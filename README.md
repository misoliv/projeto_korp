# Projeto Korp

Desafio técnico com foco em desenvolvimento de serviço HTTP em Go, containerização, proxy reverso, observabilidade e automação de infraestrutura.

Além dos requisitos propostos, o projeto também foi implantado em uma instância Linux na Oracle Cloud Infrastructure (OCI), permitindo validar o provisionamento e o deploy em um ambiente remoto real.

---

## Arquitetura

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

---

## Tecnologias utilizadas

- Go
- Docker
- Docker Compose
- NGINX
- Prometheus
- Grafana
- Ansible
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

O provisionamento do ambiente Linux foi automatizado utilizando Ansible.

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
 +-- builda a aplicação
 +-- executa Docker Compose
 +-- aguarda NGINX
 +-- valida /projeto-korp
 +-- valida /health
```

A VM utilizada possui recursos limitados, portanto o playbook também configura swap para permitir o provisionamento e execução do ambiente.

### Executar o playbook

A partir do WSL:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml
```

Ao final da execução, o próprio playbook realiza a validação HTTP e exibe a resposta da aplicação no console.

Exemplo de resultado:

```text
PLAY RECAP
servidor-korp : ok=36 changed=8 unreachable=0 failed=0
```

---

# Deploy na Oracle Cloud Infrastructure

Como evolução do desafio, o ambiente também foi implantado na Oracle Cloud Infrastructure.

Configuração utilizada:

```text
Cloud: Oracle Cloud Infrastructure
Sistema operacional: Oracle Linux 9
Compute Shape: VM.Standard.E2.1.Micro
Rede: VCN + subnet pública
Docker: instalado via Ansible
```

Arquitetura do provisionamento:

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

Prometheus e Grafana não precisam ser expostos diretamente para a internet e podem ser acessados através de túnel SSH.

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
- [ ] Provisionamento OCI com Terraform
- [ ] CI/CD
- [ ] Kubernetes

---

# Estrutura do projeto

```text
projeto_korp/
├── ansible/
│   ├── inventory.ini
│   └── playbook.yml
│
├── docs/
│   └── images/
│       ├── oci-instance.png
│       ├── oci-network.png
│       ├── oci-security-rules.png
│       ├── ansible-play-recap.png
│       ├── http-validation.png
│       ├── prometheus-target-up.png
│       └── grafana-dashboard.png
│
├── grafana/
│   ├── dashboards/
│   └── provisioning/
│       ├── dashboards/
│       └── datasources/
│
├── nginx/
│   └── http-server-projeto-korp.conf
│
├── prometheus/
│   └── prometheus.yml
│
├── .dockerignore
├── Dockerfile
├── compose.yml
├── go.mod
├── go.sum
├── main.go
├── main_test.go
└── README.md
```

---

## Resultado

O projeto demonstra a criação de um serviço HTTP simples em Go e sua evolução para um ambiente containerizado, observável e automatizado.

O mesmo ambiente validado localmente com Docker Compose também foi provisionado em uma máquina Linux remota na Oracle Cloud Infrastructure utilizando Ansible.
