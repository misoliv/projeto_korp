pipeline {
    agent any

    environment {
        IMAGE_NAME = 'http-server-projeto-korp:jenkins'
        CONTAINER_NAME = 'projeto-korp-ci'
        NETWORK_NAME = 'jenkins-korp-ci'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test') {
            steps {
                sh '''
                    docker run --rm \
                      -v "$WORKSPACE:/app" \
                      -w /app \
                      golang:1.27-alpine \
                      sh -c "go test -v ./..."
                '''
            }
        }

        stage('Build') {
            steps {
                sh '''
                    docker build \
                      -t $IMAGE_NAME \
                      .
                '''
            }
        }

        stage('Run') {
            steps {
                sh '''
                    docker rm -f $CONTAINER_NAME 2>/dev/null || true
                    docker network rm $NETWORK_NAME 2>/dev/null || true

                    docker network create $NETWORK_NAME

                    docker run -d \
                      --name $CONTAINER_NAME \
                      --network $NETWORK_NAME \
                      $IMAGE_NAME
                '''
            }
        }

        stage('Validate') {
            steps {
                sh '''
                    sleep 3

                    echo "Validando /projeto-korp"
                    docker run --rm \
                      --network $NETWORK_NAME \
                      curlimages/curl:8.10.1 \
                      -fsS http://$CONTAINER_NAME:8080/projeto-korp

                    echo ""

                    echo "Validando /health"
                    docker run --rm \
                      --network $NETWORK_NAME \
                      curlimages/curl:8.10.1 \
                      -fsS http://$CONTAINER_NAME:8080/health
                '''
            }
        }
    }

    post {
        always {
            sh '''
                docker rm -f $CONTAINER_NAME 2>/dev/null || true
                docker network rm $NETWORK_NAME 2>/dev/null || true
            '''
        }

        success {
            echo 'Pipeline Projeto Korp concluída com sucesso.'
        }

        failure {
            echo 'Pipeline Projeto Korp falhou.'
        }
    }
}
