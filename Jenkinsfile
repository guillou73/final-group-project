pipeline {
    agent any
    tools {
        git 'Default'
    }
    environment {
        DOCKER_IMAGE_FLASK = "guillou73/flask-app"
        DOCKER_IMAGE_MYSQL = "guillou73/mysql"
        DOCKER_REGISTRY_CREDENTIALS = "dockerhub-creds"
        KUBE_NAMESPACE = "default"
        DOCKER_TAG = "${GIT_COMMIT}"
        KUBE_CONFIG = "/tmp/kubeconfig"
        PROJECT_NAME = "flask-mysql"
        DOCKER_BUILDKIT = '1'
    }

    stages {
        stage('Checkout from Git') {
            steps {
                git branch: 'main', url: 'https://github.com/guillou73/final-group-project.git'
            }
        }

        stage('Clean Environment') {
            steps {
                script {
                    sh '''
                        echo "Cleaning up environment..."
                        docker-compose down --volumes --remove-orphans || true
                        docker system prune -f || true
                        docker volume prune -f || true
                    '''
                }
            }
        }

        stage('Run Docker Compose Build') {
            steps {
                script {
                    sh '''
                        echo "Building Docker images..."
                        docker-compose -f docker-compose.yaml build --no-cache
                        echo "Build completed."
                    '''
                }
            }
        }

        stage('Debug MySQL Service') {
            steps {
                script {
                    sh '''
                        echo "=== MySQL Service Debug Information ==="
                        
                        echo "Checking MySQL logs..."
                        docker-compose logs mysql-service || true
                        
                        echo "Checking MySQL container status..."
                        docker ps -a | grep mysql-service || true
                        
                        echo "Checking Docker volumes..."
                        docker volume ls
                        
                        echo "Checking file permissions..."
                        ls -la init.sql || echo "init.sql not found"
                        
                        echo "Checking Docker Compose configuration..."
                        docker-compose config
                    '''
                }
            }
        }

        stage('Deploy Services') {
            steps {
                script {
                    try {
                        sh '''
                            echo "Starting services..."
                            docker-compose up -d
                            
                            echo "Waiting for MySQL to be ready..."
                            for i in $(seq 1 30); do
                                if docker-compose exec -T mysql-service mysqladmin ping -h localhost -u guillou73 -padmin; then
                                    echo "MySQL is ready!"
                                    break
                                fi
                                echo "Attempt $i: Waiting for MySQL..."
                                sleep 5
                                if [ $i -eq 30 ]; then
                                    echo "MySQL failed to start in time"
                                    exit 1
                                fi
                            done
                        '''
                    } catch (Exception e) {
                        sh '''
                            echo "=== Debug Information ==="
                            docker-compose logs
                            docker-compose ps
                            exit 1
                        '''
                    }
                }
            }
        }

        stage('Verify Services') {
            steps {
                script {
                    try {
                        sh '''
                            echo "Verifying services..."
                            
                            echo "Checking container status..."
                            docker-compose ps
                            
                            echo "Checking MySQL connection..."
                            docker-compose exec -T mysql-service mysql -u guillou73 -padmin -e "SHOW DATABASES;"
                            
                            echo "Checking Flask application..."
                            curl -f http://localhost:5000/health || (echo "Flask app health check failed" && exit 1)
                            
                            echo "All services verified successfully!"
                        '''
                    } catch (Exception e) {
                        sh '''
                            echo "=== Service Verification Failed ==="
                            echo "MySQL Logs:"
                            docker-compose logs mysql-service
                            echo "Flask Logs:"
                            docker-compose logs flask_app
                            exit 1
                        '''
                    }
                }
            }
        }

        stage('Run Tests') {
            steps {
                script {
                    try {
                        sh '''
                            echo "Running tests..."
                            docker-compose exec -T flask_app pytest tests/ -v
                        '''
                    } catch (Exception e) {
                        error "Tests failed: ${e.message}"
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            script {
                echo 'Pipeline failed! Collecting debug information...'
                sh '''
                    echo "=== Debug Information ==="
                    docker-compose ps
                    docker-compose logs
                '''
            }
        }
        always {
            script {
                echo 'Cleaning up resources...'
                sh '''
                    docker-compose down --volumes --remove-orphans || true
                    docker system prune -f || true
                '''
            }
        }
    }
}
