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

    stages {
        stage('Deploy') {
            steps {
                sh '''
                    # Start the services
                    docker-compose up -d
                    
                    # Wait for services to be ready
                    sleep 30
                    
                    echo "Flask Container Logs:"
                    docker-compose logs flask-app
                    
                    echo "Checking MySQL Connection..."
                    # Use the correct credentials for the check
                    docker-compose exec -T mysql-service mysqladmin status -h mysql-service -u guillou73 -padmin
                    
                    # Additional verification
                    docker-compose exec -T mysql-service mysql -u guillou73 -padmin -e "SELECT 1;"
                '''
            }
        }
    }
    
    post {
        failure {
            sh '''
                echo "Debug: MySQL Container Logs"
                docker-compose logs mysql-service
            '''
        }
        always {
            sh '''
                # Cleanup
                docker-compose down
            '''
        }
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

        stage('Run Docker Compose Up') {
            steps {
                script {
                    // Start the services
                    sh 'docker-compose up -d'
                    
                    // Verify containers are running
                    sh 'docker-compose ps'
                    
                    // Wait for services to be healthy
                    sh '''
                        # Wait for MySQL to be ready
                        echo "Waiting for MySQL to be ready..."
                        for i in $(seq 1 30); do
                            if docker-compose exec -T mysql-service mysqladmin ping -h localhost --silent; then
                                echo "MySQL is ready!"
                                break
                            fi
                            echo "Waiting for MySQL... attempt $i"
                            sleep 5
                        done
                    '''
                }
            }
        }

        stage('Verify Services') {
            steps {
                script {
                    // Check container status and logs
                    sh '''
                        echo "Checking container status..."
                        docker-compose ps
                        
                        echo "MySQL Container Logs:"
                        docker-compose logs mysql-service
                        
                        echo "Flask Container Logs:"
                        docker-compose logs flask-app
                        
                        echo "Checking MySQL Connection..."
                        docker-compose exec -T mysql-service mysqladmin status -h localhost || exit 1
                    '''
                }
            }
        }

        stage('Perform Unit Test') {//
            steps {//
                script {//
                    try {//
                        // Show test environment
                        sh 'docker-compose exec -T pytest env'
                        
                        // Run tests with detailed output
                        def testResult = sh(
                            script: '''
                                docker-compose exec -T pytest \
                                /wait.sh mysql-service:3306 \
                                -- pytest test_main.py -v --tb=long --capture=no
                            ''',
                            returnStatus: true
                        )

                        if (testResult != 0) {
                            // Capture all container logs on failure
                            sh '''
                                echo "Test failed! Capturing debug information..."
                                echo "Docker Compose Status:"
                                docker-compose ps
                                echo "Container Logs:"
                                docker-compose logs
                            '''
                            error "Tests failed! Check the logs for details."
                        } else {
                            echo 'Tests passed successfully!'
                        }
                    } catch (Exception e) {
                        echo "Error during test execution: ${e.getMessage()}"
                        sh 'docker-compose logs'
                        throw e
                    }
                }
            }
        }

        stage('Build Flask Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE_FLASK}:${DOCKER_TAG}", ".")
                }
            }
        }

        stage('Push Docker Images') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: DOCKER_REGISTRY_CREDENTIALS, 
                                                    usernameVariable: 'DOCKER_USERNAME', 
                                                    passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh '''
                            echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin
                            docker tag mysql:8.0 ${DOCKER_IMAGE_MYSQL}:${DOCKER_TAG}
                            docker push ${DOCKER_IMAGE_FLASK}:${DOCKER_TAG}
                            docker push ${DOCKER_IMAGE_MYSQL}:${DOCKER_TAG}
                        '''
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'aws-credentials-id',
                                                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                                                    passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh '''
                            # Verify kubeconfig
                            ls -l $KUBE_CONFIG
                            head -n 20 $KUBE_CONFIG

                            # Set kubeconfig and verify connection
                            export KUBECONFIG=$KUBE_CONFIG
                            kubectl config view
                            kubectl get nodes

                            # Update deployment files
                            envsubst < mysql-dep.yaml > mysql-deployment-updated.yaml
                            envsubst < flask-dep.yaml > flask-deployment-updated.yaml

                            # Apply Kubernetes manifests
                            kubectl apply -f persistentvolume.yaml -n ${KUBE_NAMESPACE}
                            kubectl apply -f persistentvolumeclaim.yaml -n ${KUBE_NAMESPACE}
                            kubectl apply -f mysql-deployment-updated.yaml -n ${KUBE_NAMESPACE}
                            kubectl apply -f flask-deployment-updated.yaml -n ${KUBE_NAMESPACE}

                            # Verify deployments
                            kubectl get deployments -n ${KUBE_NAMESPACE}
                            kubectl get pods -n ${KUBE_NAMESPACE}
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                // Clean up containers
                sh 'docker-compose down --volumes --remove-orphans || true'
            }
        }
        success {
            echo "Build and Deployment Successful!"
        }
        failure {
            script {
                echo "Build or Deployment Failed!"
                // Capture logs on failure
                sh 'docker-compose logs || true'
            }
        }
    }

