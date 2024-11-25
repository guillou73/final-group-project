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
                    // Clean up any existing containers and volumes
                    sh '''
                        docker-compose down --volumes --remove-orphans
                        docker system prune -f
                    '''
                }
            }
        }

        stage('Run Docker Compose Build') {
            steps {
                script {
                    sh 'docker-compose -f docker-compose.yaml build --no-cache'
                }
            }
        }

        stage('Deploy and Verify Services') {
            steps {
                script {
                    try {
                        // Start the services
                        sh 'docker-compose up -d'
                        
                        // Wait for services to be ready
                        sh '''
                            echo "Waiting for services to be ready..."
                            sleep 30
                            
                            echo "Checking container status..."
                            docker-compose ps
                            
                            echo "MySQL Container Logs:"
                            docker-compose logs mysql-service
                            
                            echo "Flask Container Logs:"
                            docker-compose logs flask-app
                            
                            echo "Checking MySQL Connection..."
                            docker-compose exec -T mysql-service mysqladmin status -h mysql-service -u guillou73 -padmin
                            
                            # Verify MySQL connection
                            docker-compose exec -T mysql-service mysql -u guillou73 -padmin -e "SELECT 1;"
                        '''
                    } catch (Exception e) {
                        echo "Error during deployment: ${e.getMessage()}"
                        error "Deployment failed"
                    }
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    try {
                        sh '''
                            # Check if services are healthy
                            if ! docker-compose ps | grep -q "Up"; then
                                echo "Services are not running properly"
                                exit 1
                            fi
                            
                            # Test MySQL connection
                            docker-compose exec -T mysql-service mysql -u guillou73 -padmin -e "SHOW DATABASES;"
                            
                            # Test Flask app
                            curl -f http://localhost:5000/health || exit 1
                        '''
                    } catch (Exception e) {
                        echo "Health check failed: ${e.getMessage()}"
                        error "Health check failed"
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo 'Deployment successful!'
        }
        failure {
            script {
                echo "Deployment failed!"
                sh '''
                    echo "Debug: Container Status"
                    docker-compose ps
                    echo "Debug: MySQL Container Logs"
                    docker-compose logs mysql-service
                    echo "Debug: Flask Container Logs"
                    docker-compose logs flask-app
                '''
            }
        }
        always {
            script {
                sh '''
                    # Cleanup
                    docker-compose down --volumes --remove-orphans
                    docker system prune -f
                '''
            }
        }
    }
}
