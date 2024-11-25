pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE_FLASK = "guillou73/flask-app"
        DOCKER_IMAGE_MYSQL = "guillou73/mysql"
        DOCKER_REGISTRY_CREDENTIALS = "dockerhub-creds"
        MYSQL_ROOT_PASSWORD = credentials('mysql-root-password')
    }

    stages {
        stage('Prepare Environment') {
            steps {
                script {
                    // Create wait-for-mysql script
                    sh '''
                        cat << 'EOF' > wait-for-mysql.sh
                        #!/bin/bash
                        set -e
                        host="mysql-service"
                        user="root"
                        password="rootpassword"
                        
                        echo "Waiting for MySQL to be ready..."
                        for i in $(seq 1 30); do
                            if mysqladmin ping -h"$host" -u"$user" -p"$password" --silent; then
                                echo "MySQL is ready!"
                                exit 0
                            fi
                            echo "Attempt $i: MySQL not ready yet..."
                            sleep 5
                        done
                        echo "MySQL failed to become ready"
                        exit 1
                        EOF
                        
                        chmod +x wait-for-mysql.sh
                    '''
                }
            }
        }

        stage('Clean Environment') {
            steps {
                script {
                    sh '''
                        # Stop and remove existing containers
                        docker-compose down --volumes --remove-orphans || true
                        
                        # Remove existing volumes
                        docker volume rm $(docker volume ls -q | grep mysql_data) || true
                        
                        # Prune system
                        docker system prune -f
                    '''
                }
            }
        }

        stage('Start MySQL') {
            steps {
                script {
                    try {
                        sh '''
                            # Start only MySQL service
                            docker-compose up -d mysql-service
                            
                            # Wait for MySQL and show logs if there's an issue
                            for i in $(seq 1 30); do
                                if docker-compose exec -T mysql-service mysqladmin ping -h localhost -u root -prootpassword; then
                                    echo "MySQL is ready!"
                                    break
                                fi
                                echo "Attempt $i: Waiting for MySQL..."
                                docker-compose logs mysql-service
                                sleep 5
                                if [ $i -eq 30 ]; then
                                    echo "MySQL failed to start"
                                    exit 1
                                fi
                            done
                        '''
                    } catch (Exception e) {
                        sh '''
                            echo "MySQL failed to start. Debug information:"
                            docker-compose logs mysql-service
                            docker inspect mysql-service
                            exit 1
                        '''
                    }
                }
            }
        }

        stage('Start Flask App') {
            steps {
                script {
                    sh '''
                        # Start Flask service
                        docker-compose up -d flask_app
                        
                        # Wait for Flask to be ready
                        for i in $(seq 1 15); do
                            if curl -s http://localhost:5000/health; then
                                echo "Flask app is ready!"
                                break
                            fi
                            echo "Waiting for Flask app..."
                            sleep 2
                        done
                    '''
                }
            }
        }

        stage('Verify Services') {
            steps {
                script {
                    sh '''
                        echo "Checking MySQL..."
                        docker-compose exec -T mysql-service mysql -uroot -prootpassword -e "SHOW DATABASES;"
                        
                        echo "Checking Flask app..."
                        curl -s http://localhost:5000/health
                    '''
                }
            }
        }
    }

    post {
        failure {
            script {
                sh '''
                    echo "=== Debug Information ==="
                    docker-compose ps
                    docker-compose logs
                    
                    echo "=== MySQL Logs ==="
                    docker-compose logs mysql-service
                    
                    echo "=== MySQL Container Inspection ==="
                    docker inspect mysql-service || true
                '''
            }
        }
        always {
            script {
                sh '''
                    echo "Cleaning up..."
                    docker-compose down --volumes --remove-orphans || true
                '''
            }
        }
    }
}
