# Jenkins CI/CD Pipeline for Flask Application

This repository contains the `Jenkinsfile` and supporting files to automate the CI/CD pipeline for a Flask application. The pipeline integrates with Docker, pytest, and Kubernetes to ensure a seamless workflow for building, testing, and deploying the application.
The project has been recorded and posted on youtube, Link: https://youtu.be/K7V0dWVbxWA

## Project Overview

1. **Infrastructure**:  
   - The Kubernetes cluster is hosted on AWS EKS, managed via Terraform in a separate repository.

2. **Pipeline Workflow**:  
   - Clone the Flask application and infrastructure code repositories.
   - Build two Docker containers:
     - Flask app (`flask-app`)
     - Pytest environment (`pytest`)
   - Use `docker-compose up -d` to spin up three containers:
     - `mysql` for the database.
     - `flask-app` for the application.
     - `pytest` for running tests.
   - Run tests using `pytest`.
   - If tests pass:
     - Tag and push the Docker images for `flask-app` and `mysql` to Docker Hub.
   - Deploy the latest images to the Kubernetes cluster using updated deployment files.

## Repository Structure
- ├── docker-compose.yml # Docker configuration for Flask app, MySQL, and Pytest
- ├── Dockerfile # Dockerfile for Flask app 
- ├── Dockerfile.pytest # Dockerfile for Pytest container 
- ├── flask-dep.yaml # Flask app deployment definition file
- ├── Jenkinsfile # Jenkins pipeline definition 
- ├── main.py # Entry point for the Flask application 
- ├── mysql-dep.yaml # Mysql deployment definition file
- ├── readme.md # Project documentation
- ├── requirements.txt # Project dependencies/ requirements file
- ├── test_main.py # pytest file
- ├── wait.sh # Script to wait for MySQL to be ready 


## Pipeline Steps

1. **Clone Repositories**  
   The pipeline clones:
   - The Flask application repository.
   - The infrastructure repository containing Terraform files.

2. **Build Docker Images**  
   The Flask application and Pytest environment are containerized using Docker.

3. **Run Integration Tests**  
   Using `docker-compose`, spin up the `mysql`, `flask-app`, and `pytest` containers to ensure all components work together. Run tests using `pytest`.

4. **Push Docker Images**  
   On successful testing, the pipeline tags and pushes the `flask-app` and `mysql` images to Docker Hub.

5. **Deploy to Kubernetes**  
   Update Kubernetes deployment files to use the latest Docker images and apply changes to the EKS cluster.

## Prerequisites

- **Docker**: Install Docker and Docker Compose.
- **Jenkins**: Set up a Jenkins server with the following plugins:
  - Pipeline
  - Docker Pipeline
- **Kubernetes**: An existing EKS cluster with proper access.
- **Terraform**: Infrastructure code hosted in a separate repository.
- **Docker Hub**: An account for storing container images.

## Usage

### Step 1: Configure Jenkins

1. Add your Jenkinsfile to a Jenkins Pipeline job.
2. Set environment variables for Docker Hub credentials and Kubernetes configuration.

### Step 2: Run the Pipeline

1. Trigger the Jenkins pipeline.
2. Monitor logs to ensure each step completes successfully.

### Step 3: Verify Deployment

1. Once deployed, access the application using the Kubernetes service's external IP.
2. Confirm the latest features and fixes are live.

## Environment Variables

The following environment variables should be configured in Jenkins:

| Variable                | Description                                      |
|-------------------------|--------------------------------------------------|
| `DOCKER_USERNAME`       | Docker Hub username.                             |
| `DOCKER_PASSWORD`       | Docker Hub password.                             |
| `KUBECONFIG`            | Contents inside Kubernetes configuration file.   |
| `AWS_ACCESS_KEY_ID`     | AWS IAM user's access key ID.                    |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM user's secret access key.                |
| `GITHUB_USERNAME`       | GitHub username for cloning repositories.        |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | Personal access token for GitHub authentication. |

## Built With

- **Flask**: Web framework for Python.
- **Docker**: Containerization platform.
- **Docker Compose**: Multi-container application management.
- **Pytest**: Testing framework.
- **Jenkins**: CI/CD automation server.
- **Kubernetes**: Container orchestration platform.
- **Terraform**: Infrastructure as code tool.

## Contributing

Feel free to open issues or create pull requests to improve this pipeline.

---

### Notes

- Ensure the EKS cluster and Terraform configuration are functional and accessible before running the pipeline.
- Keep Docker Hub credentials secure by using Jenkins secrets.

