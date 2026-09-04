# Projeto Korp

Desafio técnico com foco em desenvolvimento de serviço HTTP em Go, containerização, proxy reverso, observabilidade, automação de infraestrutura e CI/CD.

Além dos requisitos propostos, o projeto também foi implantado em uma instância Linux na Oracle Cloud Infrastructure (OCI), permitindo validar o provisionamento, a configuração e o deploy em um ambiente remoto real.

Como evoluções adicionais, a infraestrutura OCI também foi modelada e provisionada utilizando Terraform, aplicando Infrastructure as Code (IaC), e foi implementada uma pipeline CI/CD com Jenkins para testes, build, deploy automatizado e validação da aplicação na OCI.

---

## Arquitetura

### Arquitetura da aplicação

```text
                         INTERNET
                            |
                            | TCP/80
                            v
                  Oracle Cloud Infrastructure
                            |
                     Oracle Linux 9
                            |
                         Docker
                            |
           +----------------+----------------+
           |                |                |
           v                v                v
        NGINX          Prometheus         Grafana
         :80              :9090             :3000
           |
           | rede Docker bridge
           v
 http-server-projeto-korp
         :8080
```

O serviço Go não possui a porta `8080` publicada diretamente para a internet.

Todas as requisições externas passam pelo NGINX, que atua como reverse proxy.

Prometheus coleta as métricas diretamente do serviço Go e o Grafana utiliza o Prometheus como datasource.

### Fluxo de provisionamento

```text
Terraform
   |
   | Infrastructure as Code
   v
Oracle Cloud Infrastructure
   |
   +-- VCN
   +-- Subnet pública
   +-- Internet Gateway
   +-- Route Table
   +-- Security List
   +-- VM Oracle Linux 9
   |
   v
Ansible
   |
   +-- configura swap
   +-- instala dependências
   +-- instala Docker
   +-- configura o host
   +-- copia o projeto
   +-- executa Docker Compose
   |
   v
Docker Compose
   |
   +-- Aplicação Go
   +-- NGINX
   +-- Prometheus
   +-- Grafana
```

### Fluxo CI/CD

```text
GitHub
   |
   v
Jenkins
   |
   +-- Checkout
   |
   +-- Testes Go
   |
   +-- Docker Build
   |
   +-- Execução temporária
   |
   +-- Validação local
   |
   +-- Deploy OCI via Ansible
   |
   +-- Validação remota
   |
   v
Oracle Cloud Infrastructure
```

---

## Tecnologias utilizadas

- Go
- Docker
- Docker Compose
- NGINX
- Prometheus
- Grafana
- Ansible
- Terraform
- Jenkins
- Oracle Linux 9
- Oracle Cloud Infrastructure (OCI)
- WSL2
- Git
- GitHub

---

## Serviço HTTP

O serviço foi desenvolvido em Go e executa na porta `8080`.

### GET `/projeto-korp`

Retorna:

```json
{
  "nome": "Projeto Korp",
  "horario": "2026-09-03T15:48:15Z"
}
```

O horário é gerado dinamicamente em UTC a cada requisição.

### GET `/health`

Endpoint adicional utilizado para validação da aplicação:

```json
{
  "status": "ok"
}
```

### GET `/metrics`

Endpoint utilizado pelo Prometheus para coleta das métricas da aplicação.

---

## Testes automatizados

Foram implementados testes para validar:

- resposta HTTP do endpoint `/projeto-korp`
- conteúdo do JSON
- horário no formato RFC3339/UTC
- endpoint `/health`
- rejeição de métodos HTTP não permitidos

Para executar:

```bash
go test -v ./...
```

---

## Docker

A aplicação utiliza um Dockerfile multi-stage.

O estágio de build:

- baixa as dependências Go
- executa os testes
- compila o binário

A imagem final contém apenas o binário da aplicação.

Build manual:

```bash
docker build -t http-server-projeto-korp .
```

---

## Docker Compose

O ambiente possui quatro serviços:

```text
http-server-projeto-korp
nginx
prometheus
grafana
```

Todos os containers utilizam a rede bridge:

```text
projeto-korp-network
```

A aplicação Go não expõe a porta `8080` diretamente para o host.

Somente o NGINX publica a porta HTTP:

```text
80:80
```

---

## NGINX

O NGINX atua como reverse proxy.

Fluxo:

```text
Cliente
   |
   | :80
   v
NGINX
   |
   | :8080
   v
http-server-projeto-korp
```

Configuração:

```text
nginx/http-server-projeto-korp.conf
```

---

## Observabilidade

### Prometheus

O Prometheus coleta métricas do serviço através de:

```text
http-server-projeto-korp:8080/metrics
```

Entre as métricas utilizadas estão:

```text
http_requests_total
service_up
up
```

Exemplos de consultas PromQL:

```promql
up{job="http-server-projeto-korp"}
```

```promql
sum(http_requests_total)
```

```promql
sum(rate(http_requests_total[1m]))
```

```promql
sum by (path) (http_requests_total)
```

### Grafana

Foi criado o dashboard:

```text
Projeto Korp - Observabilidade
```

Com painéis para:

- disponibilidade do serviço
- total de requisições
- taxa de requisições
- requisições por endpoint

O datasource Prometheus e o dashboard podem ser provisionados automaticamente através dos arquivos versionados no projeto.

---

# Automação com Ansible

O provisionamento e a configuração do ambiente Linux foram automatizados utilizando Ansible.

O Ansible é executado a partir do WSL e se conecta via SSH à instância Oracle Linux na OCI.

Fluxo:

```text
WSL
 |
 | Ansible + SSH
 v
OCI / Oracle Linux 9
 |
 +-- configura swap
 +-- instala dependências
 +-- instala Docker
 +-- instala Docker Compose
 +-- habilita Docker
 +-- copia o projeto
 +-- cria rede bridge
 +-- realiza o build da aplicação
 +-- executa Docker Compose
 +-- aguarda NGINX
 +-- valida /projeto-korp
 +-- valida /health
```

A VM utilizada possui recursos limitados, portanto o playbook também configura swap para permitir o provisionamento e execução do ambiente.

### Inventário

O arquivo real `ansible/inventory.ini` contém informações específicas do ambiente local e não é versionado.

O repositório contém apenas:

```text
ansible/inventory.ini.example
```

Para utilizar:

```bash
cp ansible/inventory.ini.example ansible/inventory.ini
```

Depois, configure o IP público e o caminho da chave SSH correspondente ao ambiente.

### Executar o playbook

A partir do WSL:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
```

Ao final da execução, o próprio playbook realiza a validação HTTP e exibe a resposta da aplicação no console.

Exemplo de uma execução concluída:

```text
PLAY RECAP
servidor-korp : ok=39 changed=18 unreachable=0 failed=0
```

---

# Deploy na Oracle Cloud Infrastructure

Como evolução do desafio, o ambiente foi implantado na Oracle Cloud Infrastructure.

Configuração utilizada:

```text
Cloud: Oracle Cloud Infrastructure
Sistema operacional: Oracle Linux 9
Compute Shape: VM.Standard.E2.1.Micro
Rede: VCN + subnet pública
Docker: instalado via Ansible
```

Arquitetura:

```text
Computador local
      |
      | WSL + Ansible
      | SSH :22
      v
Oracle Cloud Infrastructure
      |
      v
Oracle Linux 9
      |
      v
Docker Compose
      |
      +-- Go
      +-- NGINX
      +-- Prometheus
      +-- Grafana
```

A porta `80` foi liberada para acesso HTTP externo através das regras de rede da OCI.

Prometheus e Grafana não são expostos diretamente para a internet e podem ser acessados através de túnel SSH.

Exemplo:

```bash
ssh -i ~/.ssh/projeto-korp-oci \
  -L 3000:127.0.0.1:3000 \
  -L 9090:127.0.0.1:9090 \
  opc@IP_PUBLICO
```

Após criar o túnel:

```text
Grafana
http://localhost:3000

Prometheus
http://localhost:9090
```

---

# Infrastructure as Code com Terraform

Como evolução adicional do projeto, a infraestrutura necessária para execução na OCI também foi implementada utilizando Terraform.

O Terraform é responsável pelo provisionamento da infraestrutura, enquanto o Ansible é responsável pela configuração do sistema operacional e pelo deploy da aplicação.

```text
Terraform
   ↓
Infraestrutura OCI
   ↓
Ansible
   ↓
Configuração do servidor
   ↓
Docker Compose
   ↓
Aplicação
```

O arquivo principal está localizado em:

```text
terraform/main.tf
```

O código provisiona:

- VCN
- subnet pública
- Internet Gateway
- Route Table
- Security List
- regra de entrada SSH na porta `22`
- regra de entrada HTTP na porta `80`
- instância Compute
- Oracle Linux 9
- IP público

### Autenticação

A autenticação do Terraform com a OCI utiliza uma API Signing Key.

Os dados de autenticação ficam apenas no ambiente local:

```text
~/.oci/config
~/.oci/oci_api_key.pem
```

Esses arquivos não fazem parte do repositório.

O Terraform utiliza o profile:

```hcl
provider "oci" {
  config_file_profile = "DEFAULT"
}
```

Os OCIDs necessários podem ser fornecidos através de variáveis de ambiente:

```bash
export TF_VAR_tenancy_ocid="TENANCY_OCID"
export TF_VAR_compartment_ocid="COMPARTMENT_OCID"
```

### Executar o Terraform

Entre no diretório:

```bash
cd terraform
```

Inicialize:

```bash
terraform init
```

Valide:

```bash
terraform validate
```

Visualize as alterações:

```bash
terraform plan
```

Para salvar e aplicar exatamente o plano revisado:

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

Após o provisionamento, o Terraform retorna informações como:

```text
availability_domain
instance_name
oracle_linux_image
public_ip
vcn_name
```

### Validação realizada

A infraestrutura criada pelo Terraform foi validada em ambiente OCI real.

O processo realizado foi:

```text
terraform plan
      ↓
terraform apply
      ↓
VM Oracle Linux criada
      ↓
SSH validado
      ↓
Ansible executado
      ↓
Docker e Docker Compose configurados
      ↓
Aplicação iniciada
      ↓
GET /projeto-korp validado
      ↓
GET /health validado
```

Após os testes, os recursos criados pelo Terraform foram removidos utilizando:

```bash
terraform destroy
```

Os recursos temporários foram destruídos após a validação para evitar manter infraestrutura duplicada e consumo desnecessário de recursos na OCI.

O código Terraform permanece versionado no repositório e permite reproduzir o provisionamento novamente.

> Arquivos de state, planos Terraform, chaves privadas e arquivos locais de configuração não são versionados.

---

# CI/CD com Jenkins

Foi implementada uma pipeline declarativa de CI/CD utilizando Jenkins.

O Jenkins é executado localmente em um container Docker, enquanto o deploy é realizado remotamente na instância Oracle Linux hospedada na OCI.

O pipeline é definido como código através do arquivo:

```text
Jenkinsfile
```

A imagem customizada utilizada pelo Jenkins é definida em:

```text
jenkins/Dockerfile
```

Essa imagem inclui:

- Jenkins
- Git
- Docker CLI
- SSH Client
- Ansible

Arquitetura:

```text
GitHub
   ↓
Jenkins local
   ↓
CI
├── Checkout
├── Test
├── Build
├── Run
└── Validate
   ↓
CD
├── Deploy OCI
└── Validate OCI
   ↓
Oracle Linux 9
   ↓
Docker Compose
   ↓
Aplicação
```

## CI — Integração Contínua

### Checkout

O Jenkins obtém o código diretamente do repositório GitHub.

```text
GitHub
→ Jenkins Workspace
```

### Test

Os testes automatizados em Go são executados utilizando um container baseado na imagem oficial do Go:

```bash
go test -v ./...
```

A pipeline só continua caso os testes sejam concluídos com sucesso.

### Build

Após os testes, o Jenkins realiza o build da imagem Docker:

```bash
docker build -t http-server-projeto-korp:jenkins .
```

### Run

A imagem criada é iniciada temporariamente em uma rede Docker específica da pipeline.

### Validate

Antes de realizar qualquer deploy na OCI, a própria pipeline testa:

```text
GET /projeto-korp
GET /health
```

Caso alguma validação local falhe, o deploy não é executado.

---

## CD — Deploy automatizado na OCI

Após a conclusão das etapas de CI, o Jenkins realiza automaticamente o deploy na VM OCI.

O deploy utiliza:

```text
Jenkins
   ↓
Ansible
   ↓ SSH
Oracle Linux 9
```

O Jenkins executa:

```bash
ansible-playbook
```

utilizando o playbook já versionado em:

```text
ansible/playbook.yml
```

Um inventário Ansible temporário é criado durante a pipeline utilizando os dados armazenados no Jenkins Credentials.

Esse inventário não é versionado nem enviado ao GitHub.

### Credenciais

As informações necessárias para acesso à OCI são armazenadas no Jenkins Credentials.

A pipeline utiliza:

```text
oci-host
```

para o endereço da VM e:

```text
oci-ssh-key-file
```

para a chave SSH privada.

Nenhuma chave privada, IP específico ou segredo é armazenado diretamente no `Jenkinsfile`.

Durante a execução, o Jenkins disponibiliza as credenciais apenas para o estágio de deploy.

### Deploy OCI

O estágio:

```text
Deploy OCI
```

executa o Ansible contra a instância Oracle Linux.

O playbook:

- configura o host
- valida swap
- instala dependências
- instala Docker
- configura Docker Compose
- copia os arquivos da aplicação
- cria a rede Docker
- realiza o build da aplicação
- inicia os containers
- valida o NGINX
- valida a aplicação

### Validate OCI

Depois do deploy, a própria pipeline acessa o IP público da aplicação e valida:

```text
GET /projeto-korp
GET /health
```

O build só termina com sucesso caso a aplicação esteja respondendo corretamente na OCI.

### Cleanup

Independentemente de sucesso ou falha, a pipeline remove os containers e redes temporários utilizados durante os testes locais.

### Pipeline completa

```text
Checkout
   ↓
Test
   ↓
Build
   ↓
Run
   ↓
Validate
   ↓
Deploy OCI
   ↓
Validate OCI
   ↓
SUCCESS
```

Com isso, alterações no código podem passar por um fluxo automatizado de teste, build, deploy e validação.

---

# Execução local

Crie a rede Docker:

```bash
docker network create --driver bridge projeto-korp-network
```

Suba o ambiente:

```bash
docker compose up -d --build
```

Valide o serviço:

```bash
curl http://localhost:80/projeto-korp
```

Health check:

```bash
curl http://localhost:80/health
```

Para encerrar o ambiente:

```bash
docker compose down
```

---

# Validação na OCI

Com a aplicação provisionada:

```bash
curl http://IP_PUBLICO/projeto-korp
```

Resposta esperada:

```json
{
  "nome": "Projeto Korp",
  "horario": "<horario UTC atual>"
}
```

Health check:

```bash
curl http://IP_PUBLICO/health
```

Resposta esperada:

```json
{
  "status": "ok"
}
```

---

# Evidências

## Oracle Cloud Infrastructure

### Instância em execução

[![OCI Instance](https://i.postimg.cc/qRP57grN/oci-instance.png)](https://postimg.cc/Q9qb48HD)

### Rede OCI

[![OCI Network](https://i.postimg.cc/3RscwWhm/oci-network1.png)](https://postimg.cc/bDRTCysw)

### Métricas

[![OCI Metrics](https://i.postimg.cc/sXkN21z1/oci-metricas.png)](https://postimg.cc/G8jQ7LH1)

---

## Ansible

### Provisionamento concluído

[![Ansible Play Recap](https://i.postimg.cc/nzyPLMxh/ansible.png)](https://postimg.cc/FdxZWr1M)

---

## Aplicação

### Validação HTTP através do IP público

[![HTTP Validation](https://i.postimg.cc/DZ9Mzmhq/validacao1.png)](https://postimg.cc/S2GrTSJs)

---

## Prometheus

### Serviço disponível para coleta

[![Prometheus](https://i.postimg.cc/fLGrbks0/prometheus.png)](https://postimg.cc/34ZBS8dK)

---

## Grafana

### Dashboard de observabilidade

[![Grafana Dashboard](https://i.postimg.cc/7Yf5466T/grafana1.png)](https://postimg.cc/HV1Y4Tbp)

---

## Terraform

As evidências abaixo correspondem ao provisionamento temporário realizado com Terraform.

### Terraform Apply

[![terraform-apply.png](https://i.postimg.cc/nz1MP60G/terraform-apply.png)](https://postimg.cc/XGpVZDMr)

### Instância criada pelo Terraform

[![instance-terraform1.png](https://i.postimg.cc/Pqx6Jj8T/instance-terraform1.png)](https://postimg.cc/fVG7q1Kr)

### Ansible executado na infraestrutura criada pelo Terraform

[![ansible-terraform.png](https://i.postimg.cc/7L6BhkJB/ansible-terraform.png)](https://postimg.cc/rDBGZ7JW)

### Validação HTTP

[![http-validation.png](https://i.postimg.cc/43d8yghR/http-validation.png)](https://postimg.cc/75F1tjVK)

### Terraform Destroy

[![destroy-terraform.png](https://i.postimg.cc/1ztWXQNm/destroy-terraform.png)](https://postimg.cc/VJx9Z2Rp)

---

## Jenkins CI/CD

### Pipeline concluída

[![CI-CD-jenkins1.png](https://i.postimg.cc/s2dySQXN/CI-CD-jenkins1.png)](https://postimg.cc/ts5LGgF3)

[![CI-CD-jenkins.png](https://i.postimg.cc/rpXcW0mn/CI-CD-jenkins.png)](https://postimg.cc/jDXGYjyP)

---

# Status do desafio

## Etapa 1 — Serviço Go

- [x] Criar servidor HTTP em Go
- [x] Criar endpoint `/projeto-korp`
- [x] Retornar horário UTC dinamicamente
- [x] Criar Dockerfile
- [x] Validar execução em container
- [x] Criar testes automatizados

## Etapa 2 — Docker Compose e NGINX

- [x] Criar rede Docker bridge
- [x] Criar Docker Compose
- [x] Configurar NGINX
- [x] Configurar reverse proxy
- [x] Validar acesso pela porta 80

## Etapa 3 — Observabilidade

- [x] Expor métricas no padrão Prometheus
- [x] Monitorar disponibilidade
- [x] Monitorar volume de requisições
- [x] Configurar Prometheus
- [x] Configurar Grafana
- [x] Criar dashboard

## Etapa 4 — Ansible

- [x] Automatizar preparação do host Linux
- [x] Automatizar instalação do Docker
- [x] Automatizar criação da rede Docker
- [x] Automatizar cópia dos arquivos
- [x] Automatizar build da aplicação
- [x] Automatizar Docker Compose
- [x] Automatizar configurações de monitoramento
- [x] Validar o serviço pelo playbook
- [x] Exibir a resposta HTTP no console

---

# Evoluções adicionais

- [x] Deploy em Oracle Cloud Infrastructure
- [x] Oracle Linux 9
- [x] Health check
- [x] Testes automatizados
- [x] Dashboard Grafana versionado
- [x] Acesso a Prometheus e Grafana via túnel SSH
- [x] Provisionamento OCI com Terraform
- [x] Validação do Terraform em ambiente OCI real
- [x] Integração Terraform + Ansible
- [x] CI com Jenkins
- [x] CD automatizado para OCI
- [x] Jenkinsfile versionado
- [x] Deploy via Ansible executado pelo Jenkins
- [x] Validação da aplicação após deploy

---

# Estrutura do projeto

```text
projeto_korp/
├── ansible/
│   ├── inventory.ini.example
│   └── playbook.yml
│
├── docs/
│   └── images/
│       ├── terraform-apply.png
│       ├── terraform-instance.png
│       ├── terraform-ansible.png
│       ├── terraform-http-validation.png
│       ├── terraform-destroy.png
│       ├── jenkins-cicd-pipeline.png
│       ├── jenkins-deploy-oci.png
│       └── jenkins-validate-oci.png
│
├── grafana/
│   ├── dashboards/
│   └── provisioning/
│       ├── dashboards/
│       └── datasources/
│
├── jenkins/
│   └── Dockerfile
│
├── nginx/
│   └── http-server-projeto-korp.conf
│
├── prometheus/
│   └── prometheus.yml
│
├── terraform/
│   ├── .terraform.lock.hcl
│   └── main.tf
│
├── .dockerignore
├── .gitignore
├── Dockerfile
├── Jenkinsfile
├── compose.yml
├── go.mod
├── go.sum
├── main.go
├── main_test.go
└── README.md
```

Arquivos locais e sensíveis, como:

```text
ansible/inventory.ini
chaves privadas
arquivos .tfstate
planos Terraform
configurações de autenticação OCI
credenciais Jenkins
```

não são versionados.

---

## Resultado

O projeto demonstra a criação de um serviço HTTP em Go e sua evolução para um ambiente containerizado, observável, automatizado e integrado a uma pipeline CI/CD.

A aplicação foi validada localmente com Docker Compose e também implantada em Oracle Linux na Oracle Cloud Infrastructure.

O Terraform permite criar a infraestrutura OCI através de Infrastructure as Code.

O Ansible automatiza a configuração do sistema operacional, Docker, Docker Compose e o deploy da aplicação.

A integração entre Terraform e Ansible foi validada em ambiente real: uma infraestrutura temporária foi criada pelo Terraform, configurada pelo Ansible, validada através dos endpoints HTTP e posteriormente destruída.

O Jenkins adiciona CI/CD ao projeto, automatizando:

```text
Checkout
→ Test
→ Build
→ Validate
→ Deploy OCI
→ Validate OCI
```

O deploy utiliza Ansible e credenciais protegidas pelo Jenkins Credentials, sem exposição de chaves privadas no código-fonte.

Ao final da pipeline, a própria aplicação publicada na OCI é validada automaticamente através dos endpoints `/projeto-korp` e `/health`.