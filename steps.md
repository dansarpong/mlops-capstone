## ✅ **PHASE 1: Data Gathering & Preparation**

### Step 1: **Gather Dataset**

* **Action**: Find or create a dataset relevant to the ML task (Customer Churn Prediction).
* **Tools**:

  * 📄 CSV data sources
  * 🧪 Python with `pandas`, `numpy`
  * ✅ (Optional) Store raw data in `S3`

---

## ✅ **PHASE 2: Training & Validation Pipeline**

### Step 2: **Preprocess and Validate Data**

* **Action**: Clean missing values, scale, encode, and validate schema.
* **Tools**:

  * `pandas`, `scikit-learn` for data validation

### Step 3: **Train and Evaluate ML Model**

* **Action**: Train ML model, evaluate using metrics (accuracy, F1, etc.)
* **Tools**:

  * `scikit-learn`
  * Write `train.py` and `evaluate.py`

### Step 4: **Automate Training with a Scheduler**

* **Action**: Schedule recurring training
* **Tools**:

  * Apache Airflow (DAG: `train_model_dag.py`)
  * Store model and metadata (training time, metrics)

---

## ✅ **PHASE 3: Experiment Tracking and Model Versioning**

### Step 5: **Track Experiments & Models**

* **Action**: Log parameters, metrics, and artifacts
* **Tools**:

  * `MLflow`
  * Create `track_experiments.py`
  * Use `mlflow ui` to visualize experiments

### Step 6: **Save and Version Trained Models**

* **Action**: Save models in a version-controlled format
* **Tools**:

  * Store in `S3` or local `models/`
  * Use MLflow Model Registry or S3 + metadata tags

---

## ✅ **PHASE 4: Inference and A/B Testing**

### Step 7: **Build and Serve Model API**

* **Action**: Build REST API to serve predictions
* **Tools**:

  * `FastAPI`
  * Use `Gunicorn` in production
  * Write `inference_api.py`

### Step 8: **Enable A/B Testing**

* **Action**: Route traffic between Model A and B
* **Tools**:

  * Use `Nginx` to split traffic
  * Add flag in `inference_api.py` to load Model A/B

### Step 9: **Log Requests and Responses**

* **Action**: Save inputs, predictions, and feedback (ground truth)
* **Tools**:

  * `Kafka`, log API, or flat-file logging
  * Create a log handler in FastAPI middleware

---

## ✅ **PHASE 5: Monitoring and Rollbacks**

### Step 10: **Monitor Performance Metrics**

* **Action**: Compare Model A vs B on real traffic
* **Tools**:

  * Store and visualize metrics in `Prometheus + Grafana`
  * Custom `compare_ab.py` script

### Step 11: **Automated Rollback**

* **Action**: Revert to Model A if Model B performs worse
* **Tools**:

  * Airflow task or scheduled script `rollback.py`
  * Config file `config.yaml` defines threshold
  * Send alerts via email

---

## ✅ **PHASE 6: CI/CD and Deployment**

### Step 12: **Containerize with Docker**

* **Action**: Create Dockerfiles for training & inference
* **Tools**:

  * `Docker`, `docker-compose` (local)
  * Later deploy to EKS

### Step 13: **CI/CD Automation**

* **Action**: Automate tests, builds, and deployments
* **Tools**:

  * `GitHub Actions`
  * Store workflows in `.github/workflows/`

---

## ✅ **PHASE 7: Testing and Observability**

### Step 14: **Testing**

* **Action**: Write test cases for scripts and APIs
* **Tools**:

  * `pytest`
  * Tests like `test_train.py`, `test_inference.py`

### Step 15: **Monitoring and Logs**

* **Action**: Observe model behavior and system health
* **Tools**:

  * `Prometheus + Grafana` for system metrics
  * `Sentry` for exception logging
