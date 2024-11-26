pipeline {
    agent any
    environment {
        DOCKER_IMAGE_FLASK = "guillou73/flask-app"
        DOCKER_IMAGE_MYSQL = "guillou73/mysql"
        DOCKER_REGISTRY_CREDENTIALS = "dockerhub-creds"
        KUBE_NAMESPACE = "default"
        DOCKER_TAG = "${env.GIT_COMMIT}" // Correctly referencing the GIT_COMMIT environment variable
        KUBE_CONFIG = "${env.HOME}/.kube/config"
        PROJECT_NAME = "flask-mysql"
    }

    stages {
        stage('Fetch Code') {
            steps {
                checkout scm
                sh 'ls -l $WORKSPACE' // Ensures workspace is listed for debugging
            }
        }

        stage('Docker Compose Down') {
            steps {
                script {
                    // Ensure docker-compose is available and the workspace is set
                    sh 'docker-compose down --remove-orphans'
                }
            }
        }

        stage('Run Docker Compose Build') {
            steps {
                script {
                    // Ensures docker-compose uses the correct compose file
                    sh 'docker-compose -f $WORKSPACE/docker-compose.yaml build'
                }
            }
        }

        stage('Run Docker Compose Up') {
            steps {
                script {
                    // Starts services in detached mode
                    sh 'docker-compose up -d'
                    sh 'sleep 5' // Allows services some time to initialize
                }
            }
        }

        stage('Perform Unit Test') {
            steps {
                script {
                     Run the tests silently and capture the result
                    def testResult = sh(script: 'docker-compose exec -T flask pytest test_main.py > /dev/null 2>&1', returnStatus: true)

                     Handle test result
                    if (testResult != 0) {
                        error "Tests failed! Exiting pipeline."
                    } else {
                        echo 'Tests passed successfully.'
                    }
                }
            }
        }

        stage('Build Flask Docker Image') {
            steps {
                script {
                    // Build the Docker image with the specified tag
                    docker.build("${DOCKER_IMAGE_FLASK}:${DOCKER_TAG}", ".")
                }
            }
        }

        stage('Push Docker Images') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: "${DOCKER_REGISTRY_CREDENTIALS}",
                                                      usernameVariable: 'DOCKER_USERNAME', 
                                                      passwordVariable: 'DOCKER_PASSWORD')]) {
                        // Login to Docker registry
                        sh 'echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin'
                    }
                    // Tag and push images
                    sh "docker tag mysql:5.7 ${DOCKER_IMAGE_MYSQL}:${DOCKER_TAG}"
                    sh "docker push ${DOCKER_IMAGE_FLASK}:${DOCKER_TAG}"
                    sh "docker push ${DOCKER_IMAGE_MYSQL}:${DOCKER_TAG}"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'aws-credentials-id',
                                                      usernameVariable: 'AWS_ACCESS_KEY_ID',
                                                      passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        // Validate Kubeconfig file
                        sh 'ls -l $KUBE_CONFIG || echo "Kubeconfig not found!"'
                        sh 'head -n 20 $KUBE_CONFIG || echo "Kubeconfig content not available!"'

                        // Set KUBECONFIG environment variable
                        sh 'export KUBECONFIG=$KUBE_CONFIG'
                        sh 'kubectl config view'
                        sh 'kubectl get nodes'

                        // Prepare updated Kubernetes manifests
                        sh 'envsubst < $WORKSPACE/mysql-dep.yaml > $WORKSPACE/mysql-deployment-updated.yaml'
                        sh 'envsubst < $WORKSPACE/flask-dep.yaml > $WORKSPACE/flask-deployment-updated.yaml'

                        // Apply Kubernetes manifests
                        sh 'kubectl apply -f $WORKSPACE/persistentvolume.yaml -n ${KUBE_NAMESPACE}'
                        sh 'kubectl apply -f $WORKSPACE/persistentvolumeclaim.yaml -n ${KUBE_NAMESPACE}'
                        sh 'kubectl apply -f $WORKSPACE/mysql-deployment-updated.yaml -n ${KUBE_NAMESPACE}'
                        sh 'kubectl apply -f $WORKSPACE/flask-deployment-updated.yaml -n ${KUBE_NAMESPACE}'
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Build and Deployment Successful!"
        }

        failure {
            echo "Build or Deployment Failed!"
        }
    }
}
