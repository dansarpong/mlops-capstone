# MLOps Capstone Project

This repository contains an end-to-end MLOps pipeline for a Customer Churn Prediction use case. It demonstrates best practices in data engineering, model training, experiment tracking, CI/CD, infrastructure-as-code, monitoring, and automated rollbacks.

---

## 🚀 Project Structure

```plaintext
.
├── assets                                   # Static assets
├── config                                   # Configuration files for various services
│   ├── airflow.cfg
│   ├── config.yaml
│   ├── nginx.conf
│   └── prometheus.yml
├── data                                     # Sample data files
│   ├── telco_test.csv
│   └── telco_train.csv
├── docker-compose.yml
├── Dockerfile.airflow
├── Dockerfile.inference
├── mlops-dev-key.pem
├── pipelines                                # Airflow DAGs and pipeline definitions
│   └── training_pipeline_dag.py
├── README.md
├── requirements.txt
├── scripts                                  # Utility scripts for various tasks
│   ├── inference_api.py
│   ├── model_monitoring.py
│   ├── preprocessing.py
│   └── train.py
└── terraform
    ├── environments
    │   └── dev                              # Development environment configurations
    └── modules                              # Terraform modules for infrastructure
```


---

## Features

- **Data Ingestion & Preprocessing**: Automated data cleaning, validation, and quality reporting.
- **Model Training & Validation**: Modular training pipeline with experiment tracking using MLflow.
- **Model Registry & Versioning**: Store and manage models in S3 or MLflow Model Registry.
- **API Serving**: FastAPI-based REST API for real-time inference, containerized for deployment.
- **A/B Testing**: Nginx-based traffic splitting between model versions.
- **Monitoring**: Metrics and logs collected via Prometheus, Grafana, and CloudWatch.
- **Automated Rollbacks**: Airflow or script-based rollback if new model underperforms.
- **CI/CD**: Automated testing, building, and deployment using GitHub Actions.
- **Infrastructure as Code**: Modular Terraform for AWS (VPC, EC2, RDS, S3, IAM, Security Groups, CloudWatch).

---

## Getting Started

### Prerequisites

- Docker & Docker Compose
- Python 3.8+
- AWS CLI & credentials
- Terraform >= 1.3.2

### Local Setup

1. **Clone the repository**
   ```sh
   git clone https://github.com/<your-username>/mlops-capstone.git
   cd mlops-capstone
   ```

2. **Install dependencies**
   ```sh
   pip install -r requirements.txt
   ```

3. **Start local services**
   ```sh
   docker-compose up --build
   ```

---

## Key Components

- **Data Preprocessing** : `scripts/preprocessing.py`
- **Model Training**: `scripts/train.py`
- **Inference API**: `scripts/inference_api.py`
- **Airflow DAGs**: `pipelines/training_pipeline_dag.py`
- **Monitoring**: `scripts/model_monitoring.py`
- **Terraform Modules**: `terraform/modules/`

## Development Workflow

1. **Data Preparation**: Place raw data in `data/`, run preprocessing scripts.
2. **Model Training**: Run `train.py` or trigger via Airflow.
3. **Experiment Tracking**: Use MLflow UI to visualize experiments.
4. **Model Deployment**: Build and deploy Docker containers for inference.
5. **A/B Testing**: Configure Nginx to route traffic between model versions.
6. **Monitoring & Rollback**: Monitor metrics, trigger rollback if needed.
7. **CI/CD**: Push changes to trigger automated tests and deployments.
