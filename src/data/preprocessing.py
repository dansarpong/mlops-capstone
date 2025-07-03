"""
Data preprocessing pipeline for customer churn prediction.
"""

import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler, LabelEncoder, OneHotEncoder
from sklearn.model_selection import train_test_split
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
import joblib
import logging
from typing import Tuple, Dict, Any
import os
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class DataPreprocessor:
    """Data preprocessing pipeline for customer churn prediction."""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.preprocessor = None
        self.feature_columns = None
        self.target_column = config['data']['target_column']
        
    def load_data(self, file_path: str) -> pd.DataFrame:
        """Load data from CSV file."""
        try:
            df = pd.read_csv(file_path)
            logger.info(f"Data loaded successfully. Shape: {df.shape}")
            return df
        except Exception as e:
            logger.error(f"Error loading data: {str(e)}")
            raise
    
    def validate_data(self, df: pd.DataFrame) -> pd.DataFrame:
        """Validate and clean the data."""
        logger.info("Starting data validation...")
        
        # Check for missing values
        missing_values = df.isnull().sum()
        if missing_values.any():
            logger.warning(f"Missing values found: {missing_values[missing_values > 0]}")
        
        # Handle TotalCharges column (convert to numeric)
        if 'TotalCharges' in df.columns:
            df['TotalCharges'] = pd.to_numeric(df['TotalCharges'], errors='coerce')
            df['TotalCharges'].fillna(df['TotalCharges'].median(), inplace=True)
        
        # Remove customer ID column if exists
        if 'customerID' in df.columns:
            df = df.drop('customerID', axis=1)
        
        # Convert target column to binary
        if self.target_column in df.columns:
            df[self.target_column] = df[self.target_column].map({'Yes': 1, 'No': 0})
        
        logger.info("Data validation completed.")
        return df
    
    def create_preprocessing_pipeline(self, df: pd.DataFrame) -> ColumnTransformer:
        """Create preprocessing pipeline."""
        # Identify feature types
        numeric_features = df.select_dtypes(include=['int64', 'float64']).columns.tolist()
        if self.target_column in numeric_features:
            numeric_features.remove(self.target_column)
        
        categorical_features = df.select_dtypes(include=['object']).columns.tolist()
        
        # Create preprocessing steps
        numeric_transformer = StandardScaler()
        categorical_transformer = OneHotEncoder(drop='first', sparse_output=False)
        
        # Combine preprocessing steps
        preprocessor = ColumnTransformer(
            transformers=[
                ('num', numeric_transformer, numeric_features),
                ('cat', categorical_transformer, categorical_features)
            ]
        )
        
        self.feature_columns = {
            'numeric': numeric_features,
            'categorical': categorical_features
        }
        
        logger.info(f"Preprocessing pipeline created. Numeric features: {len(numeric_features)}, Categorical features: {len(categorical_features)}")
        return preprocessor
    
    def split_data(self, df: pd.DataFrame) -> Tuple[pd.DataFrame, pd.DataFrame, pd.Series, pd.Series]:
        """Split data into train and test sets."""
        X = df.drop(self.target_column, axis=1)
        y = df[self.target_column]
        
        X_train, X_test, y_train, y_test = train_test_split(
            X, y,
            test_size=self.config['data']['test_size'],
            random_state=self.config['data']['random_state'],
            stratify=y
        )
        
        logger.info(f"Data split completed. Train: {X_train.shape}, Test: {X_test.shape}")
        return X_train, X_test, y_train, y_test
    
    def fit_transform(self, X_train: pd.DataFrame, X_test: pd.DataFrame) -> Tuple[np.ndarray, np.ndarray]:
        """Fit preprocessor on training data and transform both train and test data."""
        if self.preprocessor is None:
            raise ValueError("Preprocessor not created. Call create_preprocessing_pipeline first.")
        
        X_train_processed = self.preprocessor.fit_transform(X_train)
        X_test_processed = self.preprocessor.transform(X_test)
        
        logger.info("Data preprocessing completed.")
        return X_train_processed, X_test_processed
    
    def save_preprocessor(self, file_path: str):
        """Save the fitted preprocessor."""
        if self.preprocessor is None:
            raise ValueError("No preprocessor to save. Fit the preprocessor first.")
        
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        joblib.dump({
            'preprocessor': self.preprocessor,
            'feature_columns': self.feature_columns,
            'target_column': self.target_column
        }, file_path)
        
        logger.info(f"Preprocessor saved to {file_path}")
    
    def load_preprocessor(self, file_path: str):
        """Load a saved preprocessor."""
        data = joblib.load(file_path)
        self.preprocessor = data['preprocessor']
        self.feature_columns = data['feature_columns']
        self.target_column = data['target_column']
        
        logger.info(f"Preprocessor loaded from {file_path}")
    
    def transform_new_data(self, df: pd.DataFrame) -> np.ndarray:
        """Transform new data using the fitted preprocessor."""
        if self.preprocessor is None:
            raise ValueError("Preprocessor not loaded. Load preprocessor first.")
        
        # Apply same validation steps
        df = self.validate_data(df.copy())
        
        # Remove target column if present
        if self.target_column in df.columns:
            df = df.drop(self.target_column, axis=1)
        
        # Transform data
        return self.preprocessor.transform(df)
    
    def get_feature_names(self) -> list:
        """Get feature names after preprocessing."""
        if self.preprocessor is None:
            raise ValueError("Preprocessor not fitted.")
        
        # Get numeric feature names
        numeric_features = self.feature_columns['numeric']
        
        # Get categorical feature names after one-hot encoding
        categorical_transformer = self.preprocessor.named_transformers_['cat']
        categorical_features = categorical_transformer.get_feature_names_out(
            self.feature_columns['categorical']
        )
        
        return list(numeric_features) + list(categorical_features)


def create_data_quality_report(df: pd.DataFrame) -> Dict[str, Any]:
    """Create a data quality report."""
    report = {
        'timestamp': datetime.now().isoformat(),
        'total_rows': len(df),
        'total_columns': len(df.columns),
        'missing_values': df.isnull().sum().to_dict(),
        'data_types': df.dtypes.astype(str).to_dict(),
        'duplicate_rows': df.duplicated().sum(),
        'memory_usage': df.memory_usage(deep=True).sum(),
        'summary_stats': df.describe().to_dict()
    }
    
    return report


if __name__ == "__main__":
    import yaml
    
    # Load configuration
    with open('/workspaces/mlops-capstone/config/config.yaml', 'r') as f:
        config = yaml.safe_load(f)
    
    # Initialize preprocessor
    preprocessor = DataPreprocessor(config)
    
    # Load and preprocess data
    df = preprocessor.load_data('/workspaces/mlops-capstone/data/WA_Fn-UseC_-Telco-Customer-Churn.csv')
    df = preprocessor.validate_data(df)
    
    # Create data quality report
    quality_report = create_data_quality_report(df)
    print("Data Quality Report:")
    print(f"Total rows: {quality_report['total_rows']}")
    print(f"Total columns: {quality_report['total_columns']}")
    print(f"Missing values: {quality_report['missing_values']}")
    
    # Split data
    X_train, X_test, y_train, y_test = preprocessor.split_data(df)
    
    # Create and fit preprocessing pipeline
    preprocessor.preprocessor = preprocessor.create_preprocessing_pipeline(X_train)
    X_train_processed, X_test_processed = preprocessor.fit_transform(X_train, X_test)
    
    # Save preprocessor
    preprocessor.save_preprocessor('/workspaces/mlops-capstone/models/preprocessor.pkl')
    
    print(f"Preprocessed training data shape: {X_train_processed.shape}")
    print(f"Preprocessed test data shape: {X_test_processed.shape}")
