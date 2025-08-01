"""
Model training pipeline for customer churn prediction.
"""

import os
import joblib
import mlflow
import mlflow.sklearn
import mlflow.xgboost
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import cross_val_score, StratifiedKFold
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score, classification_report, confusion_matrix
import xgboost as xgb
import optuna
from typing import Dict, Any
import logging
from datetime import datetime
import boto3
import sys
import tempfile
import joblib

sys.path.append(os.path.dirname(__file__))

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

s3_client = boto3.client('s3')



class ModelTrainer:
    """Model training pipeline with MLflow tracking and hyperparameter optimization."""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.models = {}
        self.best_model = None
        self.best_model_name = None
        self.best_score = 0
        self.best_run_id = None
        self.experiment_id = None
        
        # Initialize MLflow
        self._setup_mlflow()
    
    def _setup_mlflow(self):
        """Setup MLflow experiment tracking."""
        try:
            # Set MLflow tracking URI
            if 'MLFLOW_TRACKING_URI' in os.environ:
                mlflow.set_tracking_uri(os.environ['MLFLOW_TRACKING_URI'])
            
            # Create or get experiment
            experiment_name = self.config['mlflow']['experiment_name']
            experiment = mlflow.get_experiment_by_name(experiment_name)
            
            if experiment is None:
                self.experiment_id = mlflow.create_experiment(
                    experiment_name,
                    artifact_location=self.config['mlflow'].get('artifact_location')
                )
            else:
                self.experiment_id = experiment.experiment_id
            
            mlflow.set_experiment(experiment_name)
            logger.info(f"MLflow experiment set: {experiment_name}")
            
        except Exception as e:
            logger.warning(f"MLflow setup failed: {str(e)}")
            self.experiment_id = None
    
    def create_models(self) -> Dict[str, Any]:
        """Create model instances based on configuration."""
        models = {}
        
        for model_config in self.config['model']['algorithms']:
            name = model_config['name']
            params = model_config['params']
            
            if name == 'random_forest':
                models[name] = RandomForestClassifier(**params)
            elif name == 'xgboost':
                models[name] = xgb.XGBClassifier(**params)
            elif name == 'logistic_regression':
                models[name] = LogisticRegression(**params)
            else:
                logger.warning(f"Unknown model type: {name}")
        
        self.models = models
        logger.info(f"Created {len(models)} models: {list(models.keys())}")
        return models
    
    def evaluate_model(self, model, X_test: np.ndarray, y_test: np.ndarray) -> Dict[str, float]:
        """Evaluate model performance."""
        y_pred = model.predict(X_test)
        y_pred_proba = model.predict_proba(X_test)[:, 1] if hasattr(model, 'predict_proba') else None
        
        metrics = {
            'accuracy': accuracy_score(y_test, y_pred),
            'precision': precision_score(y_test, y_pred),
            'recall': recall_score(y_test, y_pred),
            'f1_score': f1_score(y_test, y_pred)
        }
        
        if y_pred_proba is not None:
            metrics['roc_auc'] = roc_auc_score(y_test, y_pred_proba)
        
        return metrics
    
    def cross_validate_model(self, model, X_train: np.ndarray, y_train: np.ndarray) -> Dict[str, float]:
        """Perform cross-validation."""
        cv = StratifiedKFold(
            n_splits=self.config['training']['cross_validation_folds'],
            shuffle=True,
            random_state=self.config['data']['random_state']
        )
        
        # Map metric names to sklearn compatible names
        metric_mapping = {
            'f1_score': 'f1',
            'precision': 'precision',
            'recall': 'recall',
            'accuracy': 'accuracy',
            'roc_auc': 'roc_auc'
        }
        
        cv_scores = {}
        for metric in self.config['training']['metrics']:
            sklearn_metric = metric_mapping.get(metric, metric)
            scores = cross_val_score(model, X_train, y_train, cv=cv, scoring=sklearn_metric)
            
            cv_scores[f'cv_{metric}_mean'] = scores.mean()
            cv_scores[f'cv_{metric}_std'] = scores.std()
        
        return cv_scores
    
    def optimize_hyperparameters(self, model_name: str, X_train: np.ndarray, y_train: np.ndarray) -> Any:
        """Optimize hyperparameters using Optuna."""
        if not self.config['training']['hyperparameter_tuning']:
            return self.models[model_name]
        
        def objective(trial):
            if model_name == 'random_forest':
                params = {
                    'n_estimators': trial.suggest_int('n_estimators', 50, 200),
                    'max_depth': trial.suggest_int('max_depth', 3, 20),
                    'min_samples_split': trial.suggest_int('min_samples_split', 2, 20),
                    'min_samples_leaf': trial.suggest_int('min_samples_leaf', 1, 20),
                    'random_state': self.config['data']['random_state']
                }
                model = RandomForestClassifier(**params)
            
            elif model_name == 'xgboost':
                params = {
                    'n_estimators': trial.suggest_int('n_estimators', 50, 200),
                    'max_depth': trial.suggest_int('max_depth', 3, 10),
                    'learning_rate': trial.suggest_float('learning_rate', 0.01, 0.3),
                    'subsample': trial.suggest_float('subsample', 0.6, 1.0),
                    'colsample_bytree': trial.suggest_float('colsample_bytree', 0.6, 1.0),
                    'random_state': self.config['data']['random_state']
                }
                model = xgb.XGBClassifier(**params)
            
            elif model_name == 'logistic_regression':
                params = {
                    'C': trial.suggest_float('C', 0.001, 100, log=True),
                    'solver': trial.suggest_categorical('solver', ['liblinear', 'lbfgs']),
                    'random_state': self.config['data']['random_state'],
                    'max_iter': 1000
                }
                model = LogisticRegression(**params)
            
            # Cross-validation score
            cv = StratifiedKFold(n_splits=3, shuffle=True, random_state=42)
            scores = cross_val_score(model, X_train, y_train, cv=cv, scoring='roc_auc')
            return scores.mean()
        
        study = optuna.create_study(direction='maximize')
        study.optimize(objective, n_trials=50)
        
        # Create best model
        best_params = study.best_params
        if model_name == 'random_forest':
            best_model = RandomForestClassifier(**best_params)
        elif model_name == 'xgboost':
            best_model = xgb.XGBClassifier(**best_params)
        elif model_name == 'logistic_regression':
            best_model = LogisticRegression(**best_params)
        
        logger.info(f"Hyperparameter optimization completed for {model_name}. Best score: {study.best_value:.4f}")
        return best_model
    
    def train_models(self, X_train: np.ndarray, y_train: np.ndarray, X_test: np.ndarray, y_test: np.ndarray) -> Dict[str, Any]:
        """Train all models and track with MLflow."""
        results = {}
        best_run_id = None
        
        for model_name, model in self.models.items():
            logger.info(f"Training {model_name}...")
            
            with mlflow.start_run(run_name=f"{model_name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}") as run:
                try:
                    # Optimize hyperparameters
                    optimized_model = self.optimize_hyperparameters(model_name, X_train, y_train)
                    
                    # Train model
                    optimized_model.fit(X_train, y_train)

                    # Evaluate model
                    test_metrics = self.evaluate_model(optimized_model, X_test, y_test)
                    cv_metrics = self.cross_validate_model(optimized_model, X_train, y_train)
                    
                    # Combine all metrics
                    all_metrics = {**test_metrics, **cv_metrics}

                    # Log to MLflow
                    try:
                        if self.experiment_id:
                            mlflow.log_params(optimized_model.get_params())
                            mlflow.log_metrics(all_metrics)
                            mlflow.log_param("run_id", run.info.run_id)

                            # Create input example for model signature
                            input_example = X_test[:5] if len(X_test) > 5 else X_test[:1]

                            # Log model
                            if model_name == 'xgboost':
                                mlflow.xgboost.log_model(
                                    optimized_model, 
                                    name=f"{model_name}_model",
                                    input_example=input_example
                                )
                            else:
                                mlflow.sklearn.log_model(
                                    optimized_model, 
                                    name=f"{model_name}_model",
                                    input_example=input_example
                                )
                    except Exception as mlflow_error:
                        logger.error(f"MLflow logging failed for {model_name}: {str(mlflow_error)}")

                    # Store results
                    results[model_name] = {
                        'model': optimized_model,
                        'metrics': all_metrics,
                        'test_score': test_metrics['roc_auc'] if 'roc_auc' in test_metrics else test_metrics['f1_score'],
                        'run_id': run.info.run_id
                    }
                    
                    # Update best model
                    current_score = results[model_name]['test_score']
                    if current_score > self.best_score:
                        self.best_score = current_score
                        self.best_model = optimized_model
                        self.best_model_name = model_name
                        best_run_id = run.info.run_id

                    logger.info(f"{model_name} training completed. Score: {current_score:.4f}")
                    
                except Exception as e:
                    logger.error(f"Error training {model_name}: {str(e)}")
                    # continue

        # Check if any models were successfully trained
        if not results:
            raise RuntimeError("No models were successfully trained. Check the data and configuration.")
        
        if self.best_model_name is None:
            raise RuntimeError("No best model was selected. All models may have failed training.")
        
        # Store the best run ID
        self.best_run_id = best_run_id
        
        logger.info(f"Best model: {self.best_model_name} with score: {self.best_score:.4f}")
        return results
    
    def save_model(self, model, model_name: str, version: str = None):
        """Save model to S3."""
        try:
            if version is None:
                version = datetime.now().strftime('%Y%m%d_%H%M%S')
            s3_bucket = self.config.get('infrastructure', {}).get('aws', {}).get('s3_bucket')
            s3_key = f"models/{model_name}_{version}.pkl"
            with tempfile.NamedTemporaryFile(suffix='.pkl') as tmp:
                joblib.dump(model, tmp.name)
                s3_client.upload_file(tmp.name, s3_bucket, s3_key)
            logger.info(f"Model saved to S3: s3://{s3_bucket}/{s3_key}")
            return f's3://{s3_bucket}/{s3_key}'
        except Exception as e:
            logger.error(f"Failed to save model to S3: {str(e)}")
            raise
    
    def load_model(self, s3_path: str):
        try:
            bucket, key = s3_path.replace('s3://', '').split('/', 1)
            with tempfile.NamedTemporaryFile(suffix='.pkl') as tmp:
                s3_client.download_file(bucket, key, tmp.name)
                model = joblib.load(tmp.name)
            logger.info(f"Model loaded from {s3_path}")
            return model
        except Exception as e:
            logger.error(f"Failed to load model from S3: {str(e)}")
            raise

    def register_model_with_mlflow(self, model_name: str, run_id: str = None):
        """Register the best model with MLflow Model Registry."""
        if not self.experiment_id or not self.best_model:
            logger.warning("No MLflow experiment or best model available for registration")
            return None
        
        try:
            # Get the current run ID if not provided
            if run_id is None:
                run_id = mlflow.active_run().info.run_id if mlflow.active_run() else None
            
            if not run_id:
                logger.error("No active MLflow run found for model registration")
                return None

            # Register model using the run ID and artifact path
            model_uri = f"runs:/{run_id}/{self.best_model_name}_model"
            registered_model = mlflow.register_model(model_uri, model_name)
            logger.info(f"Model registered successfully with version {registered_model.version}")
            
            # Set alias for the model version
            client = mlflow.tracking.MlflowClient()
            client.set_registered_model_alias(
                name=model_name,
                alias="production",
                version=registered_model.version
            )
            
            logger.info(f"Model {model_name} version {registered_model.version} registered and set as production alias")
            return registered_model.version
            
        except Exception as e:
            logger.error(f"Error registering model with MLflow: {str(e)}")
            return None


# def main():
#     """Main training pipeline."""
#     # Load configuration
#     with open('/opt/airflow/config/config.yaml', 'r') as f:
#         config = yaml.safe_load(f)
    
#     # Load preprocessed data (assuming preprocessing has been run)
#     try:
#         # This would normally load from the preprocessing step
        
#         from preprocessing import DataPreprocessor
        
#         preprocessor = DataPreprocessor(config)
#         df = preprocessor.load_data('/opt/airflow/data/telco_train.csv')
#         df = preprocessor.validate_data(df)
        
#         X_train, X_test, y_train, y_test = preprocessor.split_data(df)
#         preprocessor.preprocessor = preprocessor.create_preprocessing_pipeline(X_train)
#         X_train_processed, X_test_processed = preprocessor.fit_transform(X_train, X_test)
        
#         # Initialize trainer
#         trainer = ModelTrainer(config)
#         trainer.create_models()
        
#         # Train models
#         results = trainer.train_models(X_train_processed, y_train, X_test_processed, y_test)
        
#         # Save best model
#         if trainer.best_model and trainer.best_model_name:
#             model_path = trainer.save_model(trainer.best_model, f"{trainer.best_model_name}_model")
#             trainer.register_model_with_mlflow(f"{trainer.best_model_name}_model", trainer.best_run_id)
            
#             print(f"Training completed. Best model: {trainer.best_model_name}")
#             print(f"Best score: {trainer.best_score:.4f}")
#             print(f"Model saved to: {model_path}")
#         else:
#             print("Training failed: No models were successfully trained.")
#             return
#     except Exception as e:
#         logger.error(f"Training pipeline failed: {str(e)}")
#         raise


# if __name__ == "__main__":
#     main()
