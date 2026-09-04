pipeline {
    agent any

    options {
        // Evita que o Jenkins faça um checkout automático adicional.
        // O checkout será feito explicitamente no primeiro stage.
        skipDefaultCheckout(true)

        // Evita duas pipelines fazendo deploy ao mesmo tempo.
        disableConcurrentBuilds()
    }

    environment {
        IMAGE_NAME     = 'http-server-projeto-korp:jenkins'
        CONTAINER_NAME = 'projeto-korp-ci'
        NETWORK_NAME   = 'jenkins-korp-ci'
    }

    stages {

        // =====================================================
        // CI - CHECKOUT
        // =====================================================

        stage('Checkout') {
            steps {
                echo 'Obtendo código do GitHub...'
                checkout scm
            }
        }

        // =====================================================
        // CI - TESTES GO
        // =====================================================

        stage('Test') {
            steps {
                echo 'Executando testes automatizados...'

                sh '''
                    docker run --rm \
                      --volumes-from jenkins-korp \
                      -w "$WORKSPACE" \
                      golang:1.27-alpine \
                      sh -c "go test -v ./..."
                '''
            }
        }

        // =====================================================
        // CI - BUILD DA IMAGEM
        // =====================================================

        stage('Build') {
            steps {
                echo 'Construindo imagem Docker da aplicação...'

                sh '''
                    docker build \
                      -t $IMAGE_NAME \
                      .
                '''
            }
        }

        // =====================================================
        // CI - EXECUÇÃO TEMPORÁRIA
        // =====================================================

        stage('Run') {
            steps {
                echo 'Iniciando aplicação para validação local...'

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

        // =====================================================
        // CI - VALIDAÇÃO LOCAL
        // =====================================================

        stage('Validate') {
            steps {
                echo 'Validando aplicação localmente...'

                sh '''
                    sleep 3

                    echo "Validando /projeto-korp"

                    docker run --rm \
                      --network $NETWORK_NAME \
                      curlimages/curl:8.10.1 \
                      -fsS \
                      http://$CONTAINER_NAME:8080/projeto-korp

                    echo ""
                    echo "Validando /health"

                    docker run --rm \
                      --network $NETWORK_NAME \
                      curlimages/curl:8.10.1 \
                      -fsS \
                      http://$CONTAINER_NAME:8080/health

                    echo ""
                '''
            }
        }

        // =====================================================
        // CD - DEPLOY NA OCI
        // =====================================================

        stage('Deploy OCI') {
            steps {
                echo 'Iniciando deploy na Oracle Cloud Infrastructure...'

                withCredentials([
                    file(
                        credentialsId: 'oci-ssh-key-file',
                        variable: 'OCI_SSH_KEY'
                    ),
                    string(
                        credentialsId: 'oci-host',
                        variable: 'OCI_HOST'
                    )
                ]) {
                    sh '''
                        # Garante permissão segura para a chave SSH
                        chmod 600 "$OCI_SSH_KEY"

                        # Prepara known_hosts do Jenkins
                        mkdir -p ~/.ssh
                        chmod 700 ~/.ssh

                        ssh-keygen -R "$OCI_HOST" 2>/dev/null || true
                        ssh-keyscan -H "$OCI_HOST" >> ~/.ssh/known_hosts
                        chmod 600 ~/.ssh/known_hosts

                        # Cria inventário Ansible temporário.
                        # Nenhum IP ou chave privada fica salvo no GitHub.
                        INVENTORY_FILE=$(mktemp)

                        trap 'rm -f "$INVENTORY_FILE"' EXIT

                        cat > "$INVENTORY_FILE" <<EOF
[projeto_korp]
servidor-korp ansible_host=${OCI_HOST} ansible_user=opc ansible_ssh_private_key_file=${OCI_SSH_KEY} ansible_python_interpreter=/usr/bin/python3.9
EOF

                        echo "Executando deploy com Ansible..."

                        ansible-playbook \
                          -i "$INVENTORY_FILE" \
                          ansible/playbook.yml
                    '''
                }
            }
        }

        // =====================================================
        // CD - VALIDAÇÃO DA APLICAÇÃO NA OCI
        // =====================================================

        stage('Validate OCI') {
            steps {
                echo 'Validando aplicação publicada na OCI...'

                withCredentials([
                    string(
                        credentialsId: 'oci-host',
                        variable: 'OCI_HOST'
                    )
                ]) {
                    sh '''
                        echo "Validando /projeto-korp na OCI"

                        docker run --rm \
                          curlimages/curl:8.10.1 \
                          -fsS \
                          http://$OCI_HOST/projeto-korp

                        echo ""
                        echo "Validando /health na OCI"

                        docker run --rm \
                          curlimages/curl:8.10.1 \
                          -fsS \
                          http://$OCI_HOST/health

                        echo ""
                    '''
                }
            }
        }
    }

    // =========================================================
    // AÇÕES FINAIS
    // =========================================================

    post {

        always {
            echo 'Limpando recursos temporários da pipeline...'

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
