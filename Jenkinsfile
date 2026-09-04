pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
    }

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

        // =========================
        // CI - TESTES
        // =========================

        stage('Test') {
            steps {
                sh '''
                    docker run --rm \
                      --volumes-from jenkins-korp \
                      -w "$WORKSPACE" \
                      golang:1.27-alpine \
                      sh -c "go test -v ./..."
                '''
            }
        }

        // =========================
        // CI - BUILD
        // =========================

        stage('Build') {
            steps {
                sh '''
                    docker build \
                      -t $IMAGE_NAME \
                      .
                '''
            }
        }

        // =========================
        // CI - EXECUÇÃO TEMPORÁRIA
        // =========================

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

        // =========================
        // CI - VALIDAÇÃO LOCAL
        // =========================

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

                    echo ""
                '''
            }
        }

        // =========================
        // CD - DEPLOY OCI
        // =========================

        stage('Deploy OCI') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'oci-ssh-key',
                        keyFileVariable: 'OCI_SSH_KEY',
                        usernameVariable: 'OCI_SSH_USER'
                    ),
                    string(
                        credentialsId: 'oci-host',
                        variable: 'OCI_HOST'
                    )
                ]) {
                    sh '''
                        mkdir -p ~/.ssh
                        chmod 700 ~/.ssh

                        ssh-keygen -R "$OCI_HOST" 2>/dev/null || true
                        ssh-keyscan -H "$OCI_HOST" >> ~/.ssh/known_hosts
                        chmod 600 ~/.ssh/known_hosts

                        INVENTORY_FILE=$(mktemp)

                        trap 'rm -f "$INVENTORY_FILE"' EXIT

                        cat > "$INVENTORY_FILE" <<EOF
[projeto_korp]
servidor-korp ansible_host=${OCI_HOST} ansible_user=${OCI_SSH_USER} ansible_ssh_private_key_file=${OCI_SSH_KEY} ansible_python_interpreter=/usr/bin/python3.9
EOF

                        echo "Executando deploy com Ansible..."

                        ansible-playbook \
                          -i "$INVENTORY_FILE" \
                          ansible/playbook.yml
                    '''
                }
            }
        }

        // =========================
        // CD - VALIDAÇÃO OCI
        // =========================

        stage('Validate OCI') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'oci-host',
                        variable: 'OCI_HOST'
                    )
                ]) {
                    sh '''
                        echo "Validando aplicação publicada na OCI..."

                        docker run --rm \
                          curlimages/curl:8.10.1 \
                          -fsS http://$OCI_HOST/projeto-korp

                        echo ""

                        docker run --rm \
                          curlimages/curl:8.10.1 \
                          -fsS http://$OCI_HOST/health

                        echo ""
                    '''
                }
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
            echo 'CI/CD Projeto Korp concluído com sucesso.'
        }

        failure {
            echo 'Pipeline CI/CD Projeto Korp falhou.'
        }
    }
}
