"""
FastAPI-based inference API for customer churn prediction with A/B testing support.
"""

import os
import joblib
import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from pydantic import BaseModel, Field
from typing import List, Dict, Any
from datetime import datetime
import uuid
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response
import structlog
from contextlib import asynccontextmanager
import sys
import boto3
import tempfile
import yaml
import joblib
import logging


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
    handlers=[logging.StreamHandler()]
)

# Add scripts path for monitoring integration
sys.path.append('/app/scripts')
try:
    from model_monitoring import (
        DataDriftDetector, ModelPerformanceMonitor, 
        ABTestManager, AutomatedRollbackManager, PredictionDriftDetector
    )
    MONITORING_AVAILABLE = True
except ImportError as e:
    print(f"Warning: Monitoring module not available: {e}")
    MONITORING_AVAILABLE = False

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# Prometheus metrics
PREDICTION_COUNTER = Counter('predictions_total', 'Total number of predictions', ['model_version', 'endpoint'])
PREDICTION_LATENCY = Histogram('prediction_duration_seconds', 'Prediction latency', ['model_version'])
ERROR_COUNTER = Counter('prediction_errors_total', 'Total number of prediction errors', ['error_type'])

# Global variables for models
models = {}
preprocessor = None
ab_test_config = {
    'enabled': True,
    'traffic_split': 0.5,
    'model_a': None,
    'model_b': None
}

# Global variables for monitoring
monitoring_config = None
performance_monitor = None
ab_test_manager = None
rollback_manager = None
drift_detector = None
prediction_drift_detector = None
reference_data = None

config_path = '/app/config/config.yaml'
if os.path.exists(config_path):
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)

s3 = boto3.client('s3')
s3_bucket = config['infrastructure']['aws']['s3_bucket']


class CustomerData(BaseModel):
    """Input schema for customer churn prediction."""
    gender: str = Field(..., description="Customer gender")
    SeniorCitizen: int = Field(..., description="Whether customer is senior citizen (0/1)")
    Partner: str = Field(..., description="Whether customer has partner")
    Dependents: str = Field(..., description="Whether customer has dependents")
    tenure: int = Field(..., description="Customer tenure in months")
    PhoneService: str = Field(..., description="Whether customer has phone service")
    MultipleLines: str = Field(..., description="Whether customer has multiple lines")
    InternetService: str = Field(..., description="Customer internet service type")
    OnlineSecurity: str = Field(..., description="Whether customer has online security")
    OnlineBackup: str = Field(..., description="Whether customer has online backup")
    DeviceProtection: str = Field(..., description="Whether customer has device protection")
    TechSupport: str = Field(..., description="Whether customer has tech support")
    StreamingTV: str = Field(..., description="Whether customer has streaming TV")
    StreamingMovies: str = Field(..., description="Whether customer has streaming movies")
    Contract: str = Field(..., description="Customer contract type")
    PaperlessBilling: str = Field(..., description="Whether customer uses paperless billing")
    PaymentMethod: str = Field(..., description="Customer payment method")
    MonthlyCharges: float = Field(..., description="Customer monthly charges")
    TotalCharges: float = Field(..., description="Customer total charges")


class PredictionResponse(BaseModel):
    """Response schema for predictions."""
    prediction: int = Field(..., description="Churn prediction (0/1)")
    probability: float = Field(..., description="Churn probability")
    model_version: str = Field(..., description="Model version used")
    request_id: str = Field(..., description="Unique request ID")
    timestamp: str = Field(..., description="Prediction timestamp")


class BatchPredictionRequest(BaseModel):
    """Request schema for batch predictions."""
    customers: List[CustomerData] = Field(..., description="List of customers")


class BatchPredictionResponse(BaseModel):
    """Response schema for batch predictions."""
    predictions: List[PredictionResponse] = Field(..., description="List of predictions")
    total_processed: int = Field(..., description="Total number of customers processed")
    batch_id: str = Field(..., description="Unique batch ID")


class HealthResponse(BaseModel):
    """Health check response schema."""
    status: str = Field(..., description="Service status")
    version: str = Field(..., description="API version")
    models_loaded: List[str] = Field(..., description="List of loaded models")
    timestamp: str = Field(..., description="Health check timestamp")


def clean_numeric_columns(df: pd.DataFrame, numeric_columns: list):
    """Convert numeric columns to float and handle errors/missing values."""
    for col in numeric_columns:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors='coerce')
    df.fillna(0, inplace=True)
    return df

def load_models():
    """Load models and preprocessor"""
    global models, preprocessor, ab_test_config
    global monitoring_config, performance_monitor, ab_test_manager, rollback_manager, drift_detector, reference_data

    # Load preprocessor
    preprocessor_key = "models/preprocessor.pkl"
    try:
        with tempfile.NamedTemporaryFile(suffix='.pkl') as tmp:
            s3.download_file(s3_bucket, preprocessor_key, tmp.name)
            data = joblib.load(tmp.name)
            preprocessor = data['preprocessor']
            logger.info("Preprocessor loaded successfully from S3")
    except Exception as e:
        logger.warning(f"Preprocessor not found in S3: {str(e)}")

    # Load models
    models = {}
    try:
        response = s3.list_objects_v2(Bucket=s3_bucket, Prefix="models/")
        for obj in response.get('Contents', []):
            key = obj['Key']
            if key.endswith('.pkl') and 'preprocessor' not in key:
                model_name = os.path.basename(key).replace('.pkl', '')
                try:
                    with tempfile.NamedTemporaryFile(suffix='.pkl') as tmp:
                        s3.download_file(s3_bucket, key, tmp.name)
                        models[model_name] = joblib.load(tmp.name)
                        logger.info(f"Model {model_name} loaded successfully from S3")
                except Exception as e:
                    logger.warning(f"Failed to load model {model_name} from S3: {str(e)}")
    except Exception as e:
        logger.error(f"Failed to list or load models from S3: {str(e)}")

    # Set up A/B testing models
    model_names = list(models.keys())
    if len(model_names) >= 2:
        ab_test_config['model_a'] = model_names[0]
        ab_test_config['model_b'] = model_names[1]
        logger.info(f"A/B testing configured: A={model_names[0]}, B={model_names[1]}")
    elif len(model_names) == 1:
        ab_test_config['model_a'] = model_names[0]
        ab_test_config['model_b'] = model_names[0]
        ab_test_config['enabled'] = False
        logger.info(f"Single model mode: {model_names[0]}")

    # Monitoring components
    if MONITORING_AVAILABLE:
        try:
            # Check monitoring configuration
            if monitoring_config:
                # Initialize monitoring components
                performance_monitor = ModelPerformanceMonitor(monitoring_config)
                ab_test_manager = ABTestManager(monitoring_config)
                rollback_manager = AutomatedRollbackManager(monitoring_config)
                
                # Initialize drift detector with reference data if available
                data_path = '/app/data/telco_train.csv'
                if os.path.exists(data_path):
                    reference_df = pd.read_csv(data_path)
                    if preprocessor and 'Churn' in reference_df.columns:
                        # Use training data as reference (excluding target) and clean numeric columns
                        ref_features = reference_df.drop('Churn', axis=1)
                        numeric_cols = ['tenure', 'MonthlyCharges', 'TotalCharges']
                        ref_features = clean_numeric_columns(ref_features, numeric_cols)
                        reference_data = preprocessor.transform(ref_features)
                        feature_names = ref_features.columns.tolist()
                        drift_detector = DataDriftDetector(reference_data, feature_names)
                        logger.info("Monitoring components initialized successfully")
                    else:
                        logger.warning("Could not initialize drift detector - preprocessor or target column missing")
                else:
                    logger.warning("Reference data not found for drift detection")
            else:
                logger.warning("Monitoring configuration not found")
        except Exception as e:
            logger.error(f"Failed to initialize monitoring components: {str(e)}")

def select_model_for_ab_test() -> str:
    """Select model for A/B testing based on traffic split."""
    if not ab_test_config['enabled'] or not ab_test_config['model_a']:
        return ab_test_config['model_a'] or list(models.keys())[0]
    
    import random
    if random.random() < ab_test_config['traffic_split']:
        return ab_test_config['model_a']
    else:
        return ab_test_config['model_b']

def preprocess_customer_data(customer_data: CustomerData) -> np.ndarray:
    """Preprocess customer data for prediction."""
    if preprocessor is None:
        raise HTTPException(status_code=500, detail="Preprocessor not loaded")
    
    # Convert to DataFrame
    data_dict = customer_data.dict()
    df = pd.DataFrame([data_dict])
    
    # Transform using preprocessor
    processed_data = preprocessor.transform(df)
    logger.info(f"Processed data for prediction: {processed_data}")
    return processed_data

async def log_prediction_async(request_data: Dict[str, Any], response_data: Dict[str, Any]):
    """Asynchronously log prediction data."""
    try:
        log_entry = {
            'timestamp': datetime.now().isoformat(),
            'request_id': response_data.get('request_id'),
            'model_version': response_data.get('model_version'),
            'input_data': request_data,
            'prediction': response_data.get('prediction'),
            'probability': response_data.get('probability')
        }
        
        # Log to structured logger
        logger.info("prediction_logged", **log_entry)
        
    except Exception as e:
        logger.error(f"Error logging prediction: {str(e)}")


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    # Startup
    logger.info("Starting up inference API...")
    load_models()
    yield
    # Shutdown
    logger.info("Shutting down inference API...")


# Initialize FastAPI app
app = FastAPI(
    title="Customer Churn Prediction API",
    description="ML inference API for customer churn prediction with A/B testing",
    version="1.0.0",
    lifespan=lifespan
)

# Add middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["*"]
)


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint."""
    return HealthResponse(
        status="healthy",
        version="1.0.0",
        models_loaded=list(models.keys()),
        timestamp=datetime.now().isoformat()
    )


@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint."""
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.post("/predict", response_model=PredictionResponse)
async def predict_churn(
    customer: CustomerData,
    background_tasks: BackgroundTasks
):
    """Single customer churn prediction."""
    request_id = str(uuid.uuid4())
    start_time = datetime.now()
    
    try:
        # Select model for A/B testing
        selected_model_name = select_model_for_ab_test()
        
        if selected_model_name not in models:
            ERROR_COUNTER.labels(error_type="model_not_found").inc()
            raise HTTPException(status_code=500, detail=f"Model {selected_model_name} not found")
        
        selected_model = models[selected_model_name]
        
        # Preprocess data
        processed_data = preprocess_customer_data(customer)
        
        # Make prediction
        with PREDICTION_LATENCY.labels(model_version=selected_model_name).time():
            prediction = selected_model.predict(processed_data)[0]
            probability = selected_model.predict_proba(processed_data)[0][1]
        
        # Create response
        response = PredictionResponse(
            prediction=int(prediction),
            probability=float(probability),
            model_version=selected_model_name,
            request_id=request_id,
            timestamp=start_time.isoformat()
        )
        
        # Update metrics
        PREDICTION_COUNTER.labels(
            model_version=selected_model_name,
            endpoint="predict"
        ).inc()
        
        # Log prediction asynchronously
        background_tasks.add_task(
            log_prediction_async,
            customer.dict(),
            response.dict()
        )
        
        return response
        
    except Exception as e:
        ERROR_COUNTER.labels(error_type="prediction_error").inc()
        logger.error(f"Prediction error: {str(e)}", request_id=request_id)
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")


@app.post("/predict/batch", response_model=BatchPredictionResponse)
async def predict_batch_churn(
    batch_request: BatchPredictionRequest,
    background_tasks: BackgroundTasks
):
    """Batch customer churn prediction."""
    batch_id = str(uuid.uuid4())
    start_time = datetime.now()
    
    try:
        predictions = []
        
        for customer in batch_request.customers:
            try:
                # Select model for A/B testing
                selected_model_name = select_model_for_ab_test()
                selected_model = models[selected_model_name]
                
                # Preprocess data
                processed_data = preprocess_customer_data(customer)
                
                # Make prediction
                prediction = selected_model.predict(processed_data)[0]
                probability = selected_model.predict_proba(processed_data)[0][1]
                
                # Create response
                pred_response = PredictionResponse(
                    prediction=int(prediction),
                    probability=float(probability),
                    model_version=selected_model_name,
                    request_id=str(uuid.uuid4()),
                    timestamp=start_time.isoformat()
                )
                
                predictions.append(pred_response)
                
                # Update metrics
                PREDICTION_COUNTER.labels(
                    model_version=selected_model_name,
                    endpoint="predict_batch"
                ).inc()
                
            except Exception as e:
                ERROR_COUNTER.labels(error_type="batch_prediction_error").inc()
                logger.error(f"Batch prediction error for customer: {str(e)}")
                continue
        
        response = BatchPredictionResponse(
            predictions=predictions,
            total_processed=len(predictions),
            batch_id=batch_id
        )
        
        # Log batch prediction asynchronously
        background_tasks.add_task(
            log_prediction_async,
            {"batch_size": len(batch_request.customers), "batch_id": batch_id},
            {"total_processed": len(predictions), "batch_id": batch_id}
        )
        
        return response
        
    except Exception as e:
        ERROR_COUNTER.labels(error_type="batch_error").inc()
        logger.error(f"Batch prediction error: {str(e)}", batch_id=batch_id)
        raise HTTPException(status_code=500, detail=f"Batch prediction failed: {str(e)}")


@app.get("/models")
async def list_models():
    """List available models."""
    return {
        "models": list(models.keys()),
        "ab_testing": ab_test_config,
        "total_models": len(models)
    }


@app.post("/models/switch")
async def switch_ab_models(model_a: str, model_b: str):
    """Switch A/B testing models."""
    if model_a not in models or model_b not in models:
        raise HTTPException(status_code=400, detail="One or both models not found")
    
    ab_test_config['model_a'] = model_a
    ab_test_config['model_b'] = model_b
    ab_test_config['enabled'] = True
    
    logger.info(f"A/B models switched: A={model_a}, B={model_b}")
    return {"message": f"A/B models switched successfully", "config": ab_test_config}


@app.post("/models/traffic-split")
async def update_traffic_split(split_ratio: float):
    """Update A/B testing traffic split ratio."""
    if not 0 <= split_ratio <= 1:
        raise HTTPException(status_code=400, detail="Split ratio must be between 0 and 1")
    
    ab_test_config['traffic_split'] = split_ratio
    logger.info(f"Traffic split updated to {split_ratio}")
    return {"message": "Traffic split updated", "split_ratio": split_ratio}


@app.get("/monitoring/status")
async def monitoring_status():
    """Get monitoring system status."""
    if not MONITORING_AVAILABLE:
        return {"status": "monitoring_unavailable", "message": "Monitoring module not loaded"}
    
    return {
        "status": "monitoring_active" if performance_monitor else "monitoring_inactive",
        "components": {
            "performance_monitor": performance_monitor is not None,
            "ab_test_manager": ab_test_manager is not None,
            "rollback_manager": rollback_manager is not None,
            "drift_detector": drift_detector is not None
        },
        "timestamp": datetime.now().isoformat()
    }


@app.post("/monitoring/drift/check")
async def check_data_drift(data: List[CustomerData]):
    """Check for data drift in incoming data."""
    if not MONITORING_AVAILABLE or not drift_detector:
        raise HTTPException(status_code=503, detail="Drift detection not available")
    
    try:
        # Convert input data to numpy array
        df = pd.DataFrame([customer.dict() for customer in data])
        # Apply same preprocessing as training data
        if preprocessor:
            processed_data = preprocessor.transform(df)
        else:
            # Basic preprocessing if preprocessor not available
            processed_data = df.select_dtypes(include=[np.number]).values
        
        # Detect drift
        drift_results = drift_detector.detect_drift(processed_data)
        
        return {
            "drift_detected": any(result['drift_detected'] for result in drift_results.values()),
            "feature_drift": drift_results,
            "timestamp": datetime.now().isoformat()
        }
    
    except Exception as e:
        logger.error(f"Drift detection failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Drift detection failed: {str(e)}")


@app.get("/monitoring/performance")
async def get_performance_metrics():
    """Get current model performance metrics."""
    if not MONITORING_AVAILABLE or not performance_monitor:
        raise HTTPException(status_code=503, detail="Performance monitoring not available")
    
    try:
        # Return latest performance metrics
        if performance_monitor.performance_history:
            latest_performance = performance_monitor.performance_history[-1]
            return {
                "latest_performance": latest_performance,
                "performance_history_count": len(performance_monitor.performance_history),
                "timestamp": datetime.now().isoformat()
            }
        else:
            return {
                "message": "No performance metrics available yet",
                "timestamp": datetime.now().isoformat()
            }
    
    except Exception as e:
        logger.error(f"Performance metrics retrieval failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Performance metrics retrieval failed: {str(e)}")


@app.post("/monitoring/rollback/check")
async def check_rollback_conditions():
    """Check if rollback conditions are met."""
    if not MONITORING_AVAILABLE or not rollback_manager:
        raise HTTPException(status_code=503, detail="Rollback manager not available")
    
    try:
        # This would typically be called with actual performance data
        # For now, return rollback manager status
        return {
            "rollback_manager_active": True,
            "rollback_history_count": len(rollback_manager.rollback_history),
            "message": "Rollback check endpoint active - requires performance data for actual check",
            "timestamp": datetime.now().isoformat()
        }
    
    except Exception as e:
        logger.error(f"Rollback check failed: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Rollback check failed: {str(e)}")


@app.get("/")
async def root():
    """Root endpoint."""
    return {
        "message": "Customer Churn Prediction API",
        "version": "1.0.0",
        "get_endpoints": [
            "/health",
            "/metrics",
            "/models",
            "/monitoring/status",
            "/monitoring/performance",
        ],
        "post_endpoints": [
            "/predict",
            "/predict/batch",
            "/models/switch",
            "/models/traffic-split",
            "/monitoring/drift/check",
            "/monitoring/rollback/check"
        ]
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "inference_api:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
