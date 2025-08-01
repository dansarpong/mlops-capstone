"""
Monitoring and A/B testing infrastructure for customer churn prediction models.
"""

import numpy as np
from datetime import datetime
from typing import Dict, Any, List
from scipy import stats
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, roc_auc_score
import structlog
from prometheus_client import Gauge, Counter

# Configure logging
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
MODEL_PERFORMANCE_GAUGE = Gauge('model_performance_score', 'Model performance score', ['model_version', 'metric'])
DATA_DRIFT_GAUGE = Gauge('data_drift_score', 'Data drift detection score', ['feature'])
PREDICTION_DRIFT_GAUGE = Gauge('prediction_drift_score', 'Prediction drift score')
AB_TEST_METRICS = Gauge('ab_test_metric', 'A/B test metrics', ['model', 'metric'])
ROLLBACK_COUNTER = Counter('model_rollbacks_total', 'Total number of model rollbacks')


class DataDriftDetector:
    """Detect data drift using statistical tests."""
    
    def __init__(self, reference_data: np.ndarray, feature_names: List[str]):
        self.reference_data = reference_data
        self.feature_names = feature_names
        self.reference_stats = self._calculate_reference_stats()
    
    def _calculate_reference_stats(self) -> Dict[str, Dict[str, float]]:
        """Calculate reference statistics for each feature."""
        stats_dict = {}
        for i, feature in enumerate(self.feature_names):
            feature_data = self.reference_data[:, i]
            stats_dict[feature] = {
                'mean': np.mean(feature_data),
                'std': np.std(feature_data),
                'min': np.min(feature_data),
                'max': np.max(feature_data),
                'median': np.median(feature_data),
                'q25': np.percentile(feature_data, 25),
                'q75': np.percentile(feature_data, 75)
            }
        return stats_dict
    
    def detect_drift(self, new_data: np.ndarray, threshold: float = 0.05) -> Dict[str, Dict[str, Any]]:
        """Detect drift using Kolmogorov-Smirnov test."""
        drift_results = {}
        
        for i, feature in enumerate(self.feature_names):
            reference_feature = self.reference_data[:, i]
            new_feature = new_data[:, i]
            
            # Kolmogorov-Smirnov test
            ks_statistic, p_value = stats.ks_2samp(reference_feature, new_feature)
            
            # Calculate PSI (Population Stability Index)
            psi_score = self._calculate_psi(reference_feature, new_feature)
            
            # Determine if drift is detected
            drift_detected = p_value < threshold or psi_score > 0.1
            
            drift_results[feature] = {
                'ks_statistic': ks_statistic,
                'p_value': p_value,
                'psi_score': psi_score,
                'drift_detected': drift_detected,
                'reference_stats': self.reference_stats[feature],
                'new_stats': {
                    'mean': np.mean(new_feature),
                    'std': np.std(new_feature),
                    'min': np.min(new_feature),
                    'max': np.max(new_feature)
                }
            }
            
            # Update Prometheus metrics
            DATA_DRIFT_GAUGE.labels(feature=feature).set(psi_score)
        
        return drift_results
    
    def _calculate_psi(self, reference: np.ndarray, new: np.ndarray, bins: int = 10) -> float:
        """Calculate Population Stability Index (PSI)."""
        try:
            # Create bins based on reference data
            bin_edges = np.histogram_bin_edges(reference, bins=bins)
            
            # Calculate frequencies
            ref_freq, _ = np.histogram(reference, bins=bin_edges)
            new_freq, _ = np.histogram(new, bins=bin_edges)
            
            # Convert to percentages and avoid zero values
            ref_pct = (ref_freq / len(reference)) + 1e-10
            new_pct = (new_freq / len(new)) + 1e-10
            
            # Calculate PSI
            psi = np.sum((new_pct - ref_pct) * np.log(new_pct / ref_pct))
            return psi
            
        except Exception as e:
            logger.warning(f"PSI calculation failed: {str(e)}")
            return 0.0


class ModelPerformanceMonitor:
    """Monitor model performance over time."""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.performance_history = []
    
    def evaluate_model_performance(self, y_true: np.ndarray, y_pred: np.ndarray, 
                                 y_pred_proba: np.ndarray, model_version: str) -> Dict[str, float]:
        """Evaluate model performance."""
        metrics = {
            'accuracy': accuracy_score(y_true, y_pred),
            'precision': precision_score(y_true, y_pred),
            'recall': recall_score(y_true, y_pred),
            'f1_score': f1_score(y_true, y_pred),
            'roc_auc': roc_auc_score(y_true, y_pred_proba)
        }
        
        # Add timestamp and model version
        performance_record = {
            'timestamp': datetime.now().isoformat(),
            'model_version': model_version,
            **metrics
        }
        
        self.performance_history.append(performance_record)
        
        # Update Prometheus metrics
        for metric_name, value in metrics.items():
            MODEL_PERFORMANCE_GAUGE.labels(model_version=model_version, metric=metric_name).set(value)
        
        logger.info("Model performance evaluated", **performance_record)
        return metrics
    
    def check_performance_degradation(self, current_performance: Dict[str, float], 
                                    baseline_performance: Dict[str, float], 
                                    threshold: float = 0.05) -> bool:
        """Check if model performance has degraded significantly."""
        primary_metric = 'roc_auc'
        
        current_score = current_performance.get(primary_metric, 0)
        baseline_score = baseline_performance.get(primary_metric, 0)
        
        degradation = baseline_score - current_score
        degradation_percentage = degradation / baseline_score if baseline_score > 0 else 0
        
        is_degraded = degradation_percentage > threshold
        
        logger.info(
            "Performance degradation check",
            current_score=current_score,
            baseline_score=baseline_score,
            degradation=degradation,
            degradation_percentage=degradation_percentage,
            is_degraded=is_degraded
        )
        
        return is_degraded


class ABTestManager:
    """Manage A/B testing for model deployment."""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.test_results = []
    
    def collect_ab_test_data(self, model_a_predictions: List[Dict[str, Any]], 
                           model_b_predictions: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Collect A/B test data for analysis."""
        test_data = {
            'timestamp': datetime.now().isoformat(),
            'model_a': {
                'predictions': model_a_predictions,
                'total_requests': len(model_a_predictions)
            },
            'model_b': {
                'predictions': model_b_predictions,
                'total_requests': len(model_b_predictions)
            }
        }
        
        self.test_results.append(test_data)
        return test_data
    
    def analyze_ab_test(self, model_a_metrics: Dict[str, float], 
                       model_b_metrics: Dict[str, float], 
                       confidence_level: float = 0.95) -> Dict[str, Any]:
        """Analyze A/B test results using statistical tests."""
        results = {
            'timestamp': datetime.now().isoformat(),
            'model_a_metrics': model_a_metrics,
            'model_b_metrics': model_b_metrics,
            'comparison': {},
            'recommendation': None
        }
        
        # Compare each metric
        for metric in ['accuracy', 'precision', 'recall', 'f1_score', 'roc_auc']:
            if metric in model_a_metrics and metric in model_b_metrics:
                a_score = model_a_metrics[metric]
                b_score = model_b_metrics[metric]
                
                # Simple comparison (in practice, you'd want proper statistical tests)
                difference = b_score - a_score
                improvement_percentage = (difference / a_score) * 100 if a_score > 0 else 0
                
                results['comparison'][metric] = {
                    'model_a_score': a_score,
                    'model_b_score': b_score,
                    'difference': difference,
                    'improvement_percentage': improvement_percentage,
                    'model_b_better': b_score > a_score
                }
                
                # Update Prometheus metrics
                AB_TEST_METRICS.labels(model='A', metric=metric).set(a_score)
                AB_TEST_METRICS.labels(model='B', metric=metric).set(b_score)
        
        # Make recommendation based on primary metric
        primary_metric = 'roc_auc'
        if primary_metric in results['comparison']:
            primary_comparison = results['comparison'][primary_metric]
            
            if primary_comparison['model_b_better'] and primary_comparison['improvement_percentage'] > 2.0:
                results['recommendation'] = 'deploy_model_b'
            elif primary_comparison['improvement_percentage'] < -5.0:
                results['recommendation'] = 'rollback_to_model_a'
            else:
                results['recommendation'] = 'continue_testing'
        
        logger.info("A/B test analysis completed", **results)
        return results
    
    def should_trigger_rollback(self, ab_test_results: Dict[str, Any]) -> bool:
        """Determine if a rollback should be triggered."""
        recommendation = ab_test_results.get('recommendation')
        return recommendation == 'rollback_to_model_a'


class AutomatedRollbackManager:
    """Manage automated model rollbacks."""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.rollback_history = []
    
    def check_rollback_conditions(self, current_performance: Dict[str, float], 
                                 baseline_performance: Dict[str, float],
                                 ab_test_results: Dict[str, Any] = None) -> Dict[str, Any]:
        """Check if rollback conditions are met."""
        rollback_decision = {
            'timestamp': datetime.now().isoformat(),
            'should_rollback': False,
            'reasons': [],
            'performance_check': False,
            'ab_test_check': False
        }
        
        # Check performance degradation
        performance_monitor = ModelPerformanceMonitor(self.config)
        threshold = self.config['monitoring']['performance_threshold']
        
        if performance_monitor.check_performance_degradation(current_performance, baseline_performance):
            rollback_decision['performance_check'] = True
            rollback_decision['reasons'].append('Performance degradation detected')
        
        # Check A/B test results
        if ab_test_results:
            ab_manager = ABTestManager(self.config)
            if ab_manager.should_trigger_rollback(ab_test_results):
                rollback_decision['ab_test_check'] = True
                rollback_decision['reasons'].append('A/B test indicates model B is significantly worse')
        
        # Make final decision
        rollback_decision['should_rollback'] = (
            rollback_decision['performance_check'] or 
            rollback_decision['ab_test_check']
        )
        
        return rollback_decision
    
    def execute_rollback(self, previous_model_s3_path: str, reason: str) -> bool:
        """Execute model rollback using S3 only."""
        import boto3
        s3 = boto3.client('s3')
        s3_bucket = self.config['infrastructure']['aws']['s3_bucket']
        prod_key = 'models/production_model.pkl'
        try:
            # Copy previous model in S3 to production location
            copy_source = {'Bucket': s3_bucket, 'Key': previous_model_s3_path.replace(f's3://{s3_bucket}/', '')}
            s3.copy(copy_source, s3_bucket, prod_key)
            rollback_info = {
                'rollback_timestamp': datetime.now().isoformat(),
                'reason': reason,
                'previous_model_s3_path': previous_model_s3_path,
                'rollback_executed_by': 'automated_system'
            }
            # Optionally, store rollback info in S3 or log
            self.rollback_history.append(rollback_info)
            ROLLBACK_COUNTER.inc()
            logger.info("Model rollback executed", **rollback_info)
            self._send_rollback_alert(rollback_info)
            return True
        except Exception as e:
            logger.error(f"Rollback execution failed: {str(e)}")
            return False
    
    def _send_rollback_alert(self, rollback_info: Dict[str, Any]):
        """Send rollback alert to administrators."""
        # This would integrate with actual alerting systems
        logger.info("Rollback alert sent", **rollback_info)


class PredictionDriftDetector:
    """Detect drift in model predictions."""
    
    def __init__(self, reference_predictions: np.ndarray):
        self.reference_predictions = reference_predictions
        self.reference_mean = np.mean(reference_predictions)
        self.reference_std = np.std(reference_predictions)
    
    def detect_prediction_drift(self, new_predictions: np.ndarray, threshold: float = 0.1) -> Dict[str, Any]:
        """Detect drift in prediction distributions."""
        # Calculate statistics for new predictions
        new_mean = np.mean(new_predictions)
        new_std = np.std(new_predictions)
        
        # Statistical test for distribution change
        ks_statistic, p_value = stats.ks_2samp(self.reference_predictions, new_predictions)
        
        # Calculate percentage change in mean prediction
        mean_change = abs(new_mean - self.reference_mean) / self.reference_mean if self.reference_mean > 0 else 0
        
        drift_detected = p_value < 0.05 or mean_change > threshold
        
        result = {
            'timestamp': datetime.now().isoformat(),
            'ks_statistic': ks_statistic,
            'p_value': p_value,
            'reference_mean': self.reference_mean,
            'new_mean': new_mean,
            'mean_change_percentage': mean_change * 100,
            'drift_detected': drift_detected
        }
        
        # Update Prometheus metrics
        PREDICTION_DRIFT_GAUGE.set(mean_change)
        
        logger.info("Prediction drift detection", **result)
        return result


# def main_monitoring_loop():
#     """Main monitoring loop (would be run as a service)."""
#     try:
#         # Load configuration
#         config_path = './config/config.yaml'
#         if not os.path.exists(config_path):
#             logger.error(f"Configuration file not found: {config_path}")
#             return {
#                 'status': 'error',
#                 'message': 'Configuration file not found',
#                 'timestamp': datetime.now().isoformat()
#             }
        
#         with open(config_path, 'r') as f:
#             config = yaml.safe_load(f)
        
#         # Initialize monitoring components
#         performance_monitor = ModelPerformanceMonitor(config)
#         ab_test_manager = ABTestManager(config)
#         rollback_manager = AutomatedRollbackManager(config)
        
#         logger.info("Monitoring loop started")
        
#         # This would run continuously in production
#         # For demonstration, we'll just log the initialization
#         return {
#             'status': 'monitoring_initialized',
#             'timestamp': datetime.now().isoformat(),
#             'components': ['performance_monitor', 'ab_test_manager', 'rollback_manager']
#         }
    
#     except Exception as e:
#         logger.error(f"Monitoring initialization failed: {str(e)}")
#         return {
#             'status': 'error',
#             'message': str(e),
#             'timestamp': datetime.now().isoformat()
#         }


# if __name__ == "__main__":
#     result = main_monitoring_loop()
#     print(f"Monitoring system status: {result}")
