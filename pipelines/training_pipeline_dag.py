"""
Airflow DAG for automated model training and deployment pipeline.
"""

from airflow import DAG
from datetime import datetime, timedelta
from airflow.providers.standard.operators.python import PythonOperator
from airflow.providers.smtp.notifications.smtp import SmtpNotifier
import sys
import os
import yaml
import logging
import boto3
import numpy as np


# Add project root to Python path for container environment
sys.path.append('/opt/airflow')
sys.path.append('/opt/airflow/scripts')

# Default arguments for the DAG
default_args = {
    'owner': 'dansarpong',
    'depends_on_past': False,
    'start_date': datetime(2025, 1, 1),
    'retries': 1,
    'retry_delay': timedelta(minutes=1),
}

notifier = SmtpNotifier(
    to=["dansarpong.me@gmail.com"],
    subject="Churn Prediction Model Pipeline Notification"
)

# Define the DAG
dag = DAG(
    'churn_prediction_training_pipeline',
    default_args=default_args,
    description='Automated training pipeline for customer churn prediction',
    schedule='@daily',  # Run daily
    catchup=False,
    max_active_runs=1,
    tags=['ml', 'churn-prediction', 'training'],
    on_failure_callback=notifier,
    on_success_callback=notifier
)

# Load configuration from YAML file
config_path = '/opt/airflow/config/config.yaml'
with open(config_path, 'r') as f:
    config = yaml.safe_load(f)

# S3 Boto3 Client
s3 = boto3.client('s3')
s3_bucket = config['infrastructure']['aws']['s3_bucket']

data_path = '/opt/airflow/data/telco_train.csv'



def validate_data_quality(**context):
    """Validate data quality before training."""
    try:
        from scripts.preprocessing import DataPreprocessor, create_data_quality_report

        # Load and validate data using absolute path
        preprocessor = DataPreprocessor(config)
        df = preprocessor.load_data(data_path)

        # Create data quality report
        quality_report = create_data_quality_report(df)

        # Data quality checks
        total_rows = quality_report['total_rows']
        missing_percentage = sum(quality_report['missing_values'].values()) / (total_rows * len(df.columns))
        duplicate_percentage = quality_report['duplicate_rows'] / total_rows
        
        # Quality thresholds
        if missing_percentage > 0.3:  # More than 30% missing values
            raise ValueError(f"Data quality check failed: {missing_percentage:.2%} missing values")

        if duplicate_percentage > 0.1:  # More than 10% duplicates
            raise ValueError(f"Data quality check failed: {duplicate_percentage:.2%} duplicate rows")

        if total_rows < 1000:  # Minimum sample size
            raise ValueError(f"Data quality check failed: Only {total_rows} rows available")

        logging.info(f"Data quality validation passed. Rows: {total_rows}, Missing: {missing_percentage:.2%}")

        # Store quality report
        context['task_instance'].xcom_push(key='quality_report', value=quality_report)

        return True

    except Exception as e:
        logging.error(f"Data quality validation failed: {str(e)}")
        raise


def preprocess_data(**context):
    """Preprocess data for training."""
    try:
        from scripts.preprocessing import DataPreprocessor

        # Initialize preprocessor
        preprocessor = DataPreprocessor(config)
        
        # Load and preprocess data
        df = preprocessor.load_data(data_path)
        df = preprocessor.validate_data(df)
        
        # Split data
        X_train, X_test, y_train, y_test = preprocessor.split_data(df)
        
        # Create and fit preprocessing pipeline
        preprocessor.preprocessor = preprocessor.create_preprocessing_pipeline(X_train)
        X_train_processed, X_test_processed = preprocessor.fit_transform(X_train, X_test)
        
        # Save preprocessor
        preprocessor_path = f's3://{s3_bucket}/models/preprocessor.pkl'
        preprocessor.save_preprocessor(preprocessor_path)
        
        # Save processed data for training
        np.save('/tmp/X_train_processed.npy', X_train_processed)
        np.save('/tmp/X_test_processed.npy', X_test_processed)
        np.save('/tmp/y_train.npy', y_train.values)
        np.save('/tmp/y_test.npy', y_test.values)
        
        logging.info(f"Data preprocessing completed. Train shape: {X_train_processed.shape}")
        
        # Store data info in XCom
        context['task_instance'].xcom_push(key='train_shape', value=X_train_processed.shape)
        context['task_instance'].xcom_push(key='test_shape', value=X_test_processed.shape)
        
        return True
        
    except Exception as e:
        logging.error(f"Data preprocessing failed: {str(e)}")
        raise


def train_models(**context):
    """Train machine learning models."""
    try:
        from scripts.train import ModelTrainer

        # Load processed data
        X_train = np.load('/tmp/X_train_processed.npy')
        X_test = np.load('/tmp/X_test_processed.npy')
        y_train = np.load('/tmp/y_train.npy')
        y_test = np.load('/tmp/y_test.npy')
        
        # Initialize trainer
        trainer = ModelTrainer(config)
        trainer.create_models()
        
        # Train models
        results = trainer.train_models(X_train, y_train, X_test, y_test)
        
        # Save best model
        if trainer.best_model:
            model_version = datetime.now().strftime('%Y%m%d_%H%M%S')
            model_s3_path = trainer.save_model(trainer.best_model, trainer.best_model_name, model_version)
            
            # Register model with MLflow
            trainer.register_model_with_mlflow(f"churn_prediction_{trainer.best_model_name}", trainer.best_run_id)
            logging.info(f"Training completed. Best model: {trainer.best_model_name}, Score: {trainer.best_score:.4f}")
            
            # Store results in XCom
            context['task_instance'].xcom_push(key='best_model_name', value=trainer.best_model_name)
            context['task_instance'].xcom_push(key='best_model_score', value=trainer.best_score)
            context['task_instance'].xcom_push(key='model_s3_path', value=model_s3_path)
            context['task_instance'].xcom_push(key='model_version', value=model_version)
            return True
        else:
            raise ValueError("No model was successfully trained")
            
    except Exception as e:
        logging.error(f"Model training failed: {str(e)}")
        raise


def evaluate_model_performance(**context):
    """Evaluate model performance and decide on deployment."""
    try:
        # Get training results from XCom
        best_model_score = context['task_instance'].xcom_pull(key='best_model_score', task_ids='train_models')
        model_name = context['task_instance'].xcom_pull(key='best_model_name', task_ids='train_models')

        # Performance threshold from config
        threshold = config['monitoring']['performance_threshold']
        
        if best_model_score >= threshold:
            logging.info(f"Model {model_name} passed evaluation with score {best_model_score:.4f} >= {threshold}")
            context['task_instance'].xcom_push(key='deploy_model', value=True)
            return True
        else:
            logging.warning(f"Model {model_name} failed evaluation with score {best_model_score:.4f} < {threshold}")
            context['task_instance'].xcom_push(key='deploy_model', value=False)
            return False
            
    except Exception as e:
        logging.error(f"Model evaluation failed: {str(e)}")
        raise


def deploy_model(**context):
    """Deploy model if evaluation passed."""
    try:
        # Check if model should be deployed
        deploy_model = context['task_instance'].xcom_pull(key='deploy_model', task_ids='evaluate_model')
        
        if not deploy_model:
            logging.info("Model deployment skipped due to failed evaluation")
            return False
        
        model_s3_path = context['task_instance'].xcom_pull(key='model_s3_path', task_ids='train_models')
        model_version = context['task_instance'].xcom_pull(key='model_version', task_ids='train_models')
        # Copy model to S3 production location (no local copy)
        prod_key = 'models/production_model.pkl'
        # Copy model within S3 (requires permissions)
        copy_source = {'Bucket': s3_bucket, 'Key': model_s3_path.replace(f's3://{s3_bucket}/', '')}
        s3.copy(copy_source, s3_bucket, prod_key)
        logging.info(f"Model {model_s3_path} copied to S3 production location {prod_key}")
        logging.info(f"Model {model_version} deployed successfully to production")
        return True
        
    except Exception as e:
        logging.error(f"Model deployment failed: {str(e)}")
        raise


def cleanup_temp_files(**context):
    """Clean up temporary files."""
    try:
        import os
        temp_files = [
            '/tmp/X_train_processed.npy',
            '/tmp/X_test_processed.npy',
            '/tmp/y_train.npy',
            '/tmp/y_test.npy'
        ]
        
        for file_path in temp_files:
            if os.path.exists(file_path):
                os.remove(file_path)
        
        logging.info("Temporary files cleaned up")
        return True
        
    except Exception as e:
        logging.warning(f"Cleanup failed: {str(e)}")
        return True  # Don't fail the pipeline for cleanup issues


# Define tasks
validate_data_task = PythonOperator(
    task_id='validate_data_quality',
    python_callable=validate_data_quality,
    dag=dag
)

preprocess_data_task = PythonOperator(
    task_id='preprocess_data',
    python_callable=preprocess_data,
    dag=dag
)

train_models_task = PythonOperator(
    task_id='train_models',
    python_callable=train_models,
    dag=dag
)

evaluate_model_task = PythonOperator(
    task_id='evaluate_model',
    python_callable=evaluate_model_performance,
    dag=dag
)

deploy_model_task = PythonOperator(
    task_id='deploy_model',
    python_callable=deploy_model,
    dag=dag
)

cleanup_task = PythonOperator(
    task_id='cleanup_temp_files',
    python_callable=cleanup_temp_files,
    trigger_rule='all_done',
    dag=dag
)

# Define task dependencies
validate_data_task >> preprocess_data_task >> train_models_task >> evaluate_model_task >> deploy_model_task
validate_data_task >> cleanup_task
preprocess_data_task >> cleanup_task
train_models_task >> cleanup_task
evaluate_model_task >> cleanup_task
deploy_model_task >> cleanup_task
