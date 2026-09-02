# Projeto Korp

Desafio técnico para desenvolvimento, containerização, monitoramento e automação de um serviço HTTP utilizando Golang, Docker, NGINX, Prometheus, Grafana e Ansible.

## Objetivo

O projeto tem como objetivo desenvolver um serviço HTTP em Golang e criar toda a infraestrutura necessária para sua execução em containers.

O ambiente deverá incluir:

* Serviço HTTP desenvolvido em Golang
* Docker
* Docker Compose
* Rede Docker no modo bridge
* NGINX como proxy reverso
* Prometheus para coleta de métricas
* Grafana para visualização das métricas
* Ansible para automação do provisionamento

---

## Requisitos

### Serviço HTTP

O serviço deve se chamar:

```text
http-server-projeto-korp
```

A aplicação deverá escutar na porta:

```text
8080
```

E disponibilizar o endpoint:

```http
GET /projeto-korp
```

A resposta deverá seguir o formato:

```json
{
  "nome": "Projeto Korp",
  "horario": "<horário_atual>"
}
```

O campo `horario` deve ser obtido dinamicamente a cada requisição e utilizar o horário UTC.

---

## Docker

A aplicação será empacotada utilizando Docker.

O container da aplicação:

* será construído a partir do Dockerfile do projeto;
* executará o serviço Golang na porta `8080`;
* estará conectado a uma rede Docker;
* não terá a porta `8080` publicada diretamente no host.

---

## Docker Compose

O ambiente será gerenciado através do Docker Compose.

Inicialmente, serão utilizados os seguintes containers:

### http-server-projeto-korp

Responsável pela execução do serviço HTTP desenvolvido em Golang.

### NGINX

Responsável por atuar como proxy reverso.

A porta `80` do container NGINX será publicada na porta `80` do host.

O NGINX encaminhará as requisições recebidas para o serviço:

```text
http-server-projeto-korp:8080
```

---

## Rede Docker

Os containers serão conectados a uma rede Docker no modo `bridge`.

A comunicação entre NGINX e a aplicação ocorrerá através dessa rede interna.

```text
Cliente
   |
   | HTTP :80
   v
NGINX
   |
   | Docker bridge network
   v
http-server-projeto-korp :8080
```

A porta `8080` da aplicação não será exposta diretamente ao host.

---

## Proxy Reverso

O NGINX será configurado através do arquivo:

```text
http-server-projeto-korp.conf
```

A configuração será montada no container através do diretório:

```text
/etc/nginx/conf.d/
```

O fluxo de uma requisição será:

```text
http://localhost:80/projeto-korp
              |
              v
            NGINX
              |
              v
http-server-projeto-korp:8080/projeto-korp
```

---

## Teste do Serviço

Após iniciar o ambiente, o funcionamento poderá ser validado através do comando:

```bash
curl http://localhost:80/projeto-korp
```

Resposta esperada:

```json
{
  "nome": "Projeto Korp",
  "horario": "2026-09-01T21:00:00Z"
}
```

O horário apresentado acima é apenas um exemplo. A aplicação deverá retornar o horário UTC atual em cada requisição.

---

## Monitoramento e Observabilidade

O serviço deverá disponibilizar métricas no padrão Prometheus.

As métricas obrigatórias são:

* disponibilidade do serviço;
* volume de requisições.

O ambiente Docker Compose também incluirá:

* Prometheus
* Grafana

### Prometheus

O Prometheus será responsável por coletar as métricas expostas pelo serviço Golang.

```text
http-server-projeto-korp
          |
          | /metrics
          v
      Prometheus
```

### Grafana

O Grafana será utilizado para visualização das métricas coletadas pelo Prometheus.

```text
http-server-projeto-korp
          |
          v
      Prometheus
          |
          v
        Grafana
```

Será disponibilizado um dashboard para análise do comportamento e disponibilidade do serviço.

---

## Automação com Ansible

Toda a configuração do ambiente será automatizada utilizando Ansible.

O playbook deverá realizar, no mínimo:

* instalação do Docker em ambiente Linux;
* criação da rede Docker;
* build da imagem `http-server-projeto-korp`;
* execução dos containers através do Docker Compose;
* configuração do NGINX;
* configuração do Prometheus;
* configuração do Grafana;
* inicialização dos serviços;
* validação do endpoint da aplicação;
* exibição da resposta da aplicação no console.

O objetivo é permitir o provisionamento do ambiente através de um único comando:

```bash
ansible-playbook playbook.yml
```

---

## Arquitetura

```text
                         Cliente
                            |
                            | HTTP :80
                            v
                        +-------+
                        | NGINX |
                        +---+---+
                            |
                            | Proxy :8080
                            v
                  +-------------------------+
                  | http-server-projeto-korp|
                  |        Golang           |
                  +-----------+-------------+
                              |
                              | /metrics
                              v
                       +-------------+
                       | Prometheus  |
                       +------+------+
                              |
                              v
                         +---------+
                         | Grafana |
                         +---------+
```

Todos os componentes serão executados em containers Docker e conectados à mesma rede configurada para o ambiente.

---

## Tecnologias

* Golang
* Docker
* Docker Compose
* NGINX
* Prometheus
* Grafana
* Ansible
* Linux

---

## Estrutura do Projeto

A estrutura será evoluída durante o desenvolvimento do desafio.

```text
http-server-projeto-korp/
│
├── app/
│   ├── main.go
│   ├── main_test.go
│   ├── go.mod
│   └── Dockerfile
│
├── nginx/
│   └── http-server-projeto-korp.conf
│
├── prometheus/
│   └── prometheus.yml
│
├── grafana/
│   ├── provisioning/
│   └── dashboards/
│
├── ansible/
│   ├── playbook.yml
│   └── inventory/
│
├── compose.yml
├── .gitignore
└── README.md
```

---

## Status

🚧 Projeto em desenvolvimento.

### Etapa 1 — Serviço HTTP

* [X] Criar serviço Golang
* [X] Implementar `GET /projeto-korp`
* [X] Retornar horário UTC dinamicamente
* [x] Adicionar endpoint `/health`
* [x] Criar testes automatizados básicos
* [X] Criar Dockerfile
* [X] Validar execução em container

### Etapa 2 — Docker e NGINX

* [ ] Criar rede Docker
* [ ] Criar Docker Compose
* [ ] Configurar NGINX
* [ ] Configurar proxy reverso
* [ ] Validar acesso através da porta `80`

### Etapa 3 — Observabilidade

* [ ] Expor métricas Prometheus
* [ ] Monitorar disponibilidade
* [ ] Monitorar volume de requisições
* [ ] Configurar Prometheus
* [ ] Configurar Grafana
* [ ] Criar dashboard

### Etapa 4 — Ansible

* [ ] Automatizar instalação do Docker
* [ ] Automatizar configuração do ambiente
* [ ] Automatizar deploy com Docker Compose
* [ ] Automatizar configurações de monitoramento
* [ ] Validar o serviço pelo playbook
* [ ] Exibir a resposta HTTP no console

---

## Execução

As instruções completas de execução serão adicionadas conforme as etapas forem concluídas.

O teste final esperado será:

```bash
curl http://localhost:80/projeto-korp
```

---

## Autor

Projeto desenvolvido como parte de um desafio técnico.
