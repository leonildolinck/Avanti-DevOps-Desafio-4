# Projeto - CI/CD com Docker e Terraform

![Banner](./screenshots/banner.png)

Este repositório contém a aplicação ms-saudacoes-aleatorias, desenvolvida em Golang, usada anteriormente no repositório [Projeto - Gerador de Saudações Aleatórias (Dockerizado)](https://github.com/leonildolinck/Avanti-DevOps-Desafio-3) junto com uma pipeline de CI/CD automatizada usando o GitHub Actions. O objetivo é garantir entregas consistentes, testadas e com provisionamento de infraestrutura automática usando Terraform na plataforma Koyeb.

## Tecnologias Utilizadas
- **Go 1.22**

- **Docker**

- **Terraform**

- **GitHub Actions**

- **Koyeb**

- **Docker Hub**


## Sumário

- [Projeto - CI/CD com Docker e Terraform](#projeto---cicd-com-docker-e-terraform)
  - [Tecnologias Utilizadas](#tecnologias-utilizadas)
  - [Sumário](#sumário)
  - [Pré-requisitos](#pré-requisitos)
  - [Arquitetura do Projeto](#arquitetura-do-projeto)
  - [Estrutura do Projeto](#estrutura-do-projeto)
  - [1. Clonando a aplicação api-saudacoes-aleatorias diretamente na raiz](#1-clonando-a-aplicação-api-saudacoes-aleatorias-diretamente-na-raiz)
    - [Build da imagem](#build-da-imagem)
    - [Rodar localmente](#rodar-localmente)
  - [2. Backend: Microsserviço de Pessoas Aleatórias](#2-backend-microsserviço-de-pessoas-aleatórias)
    - [Back-end](#back-end)
    - [Dockerfile (Multi-stage)](#dockerfile-multi-stage)
    - [Build da imagem](#build-da-imagem-1)
    - [Rodar localmente](#rodar-localmente-1)
  - [3. Backend: Microsserviço de Saudações Aleatórias](#3-backend-microsserviço-de-saudações-aleatórias)
    - [Dockerfile (Multi-stage)](#dockerfile-multi-stage-1)
    - [Build da imagem](#build-da-imagem-2)
    - [Rodar localmente](#rodar-localmente-2)
  - [Utilizando Docker Compose](#utilizando-docker-compose)
  - [Resultado final](#resultado-final)
  - [Publicando no Docker Hub](#publicando-no-docker-hub)
  - [Conclusão](#conclusão)
  - [Contato](#contato)

---

## Pré-requisitos

- [Docker](https://docs.docker.com/engine/install/)
- [Terraform](https://www.terraform.io/)
- Conta no [GitHub](https://github.com/)
- Conta no [Koyeb](https://www.koyeb.com/)
- Conta no [Docker Hub](https://hub.docker.com/)

---

## Arquitetura do Projeto

```
[ Desenv. Local / GitHub ]
           │
           ▼
╔════════════════════════════════════════════════════════╗
║                    GitHub Actions CI/CD                ║
║--------------------------------------------------------║
║   1. Lint       → go fmt, go vet, golangci-lint        ║
║   2. Test       → gotestsum, junit report              ║
║   3. Build      → Docker Buildx (multi-plataforma)     ║
║   4. Push       → Docker Hub                           ║
║   5. Deploy     → Terraform Apply na Koyeb             ║
║   6. Cleanup    → Terraform Destroy (manual)           ║
╚════════════════════════════════════════════════════════╝
           │
           ▼
╔══════════════════════╗      ╔══════════════════════════╗
║    Docker Hub        ║─────▶║     Koyeb (Infra Cloud)  ║
║  leonildolinck/...   ║      ║  Container App Running   ║
╚══════════════════════╝      ╚══════════════════════════╝
                                      │
                                      ▼
                           https://<app>.koyeb.app

```

## Estrutura do Projeto
```
.
├── Dockerfile                # Build da imagem da aplicação
├── main.go                   # Código-fonte principal
├── infra/                    # Arquivos Terraform para Koyeb
│   ├── main.tf
│   ├── variables.tf
│   └── ...
├── .github/
│   └── workflows/
│       └── main.yml          # Pipeline CI/CD
└── README.md                 # Este arquivo
```


## 1. Clonando a aplicação api-saudacoes-aleatorias diretamente na raiz
Esta aplicação foi escrita em Go (Golang) e implementa um microsserviço simples de geração de saudações aleatórias. Ela será a base da nossa pipeline CI/CD.

Queremos clonar esse repositório diretamente na raiz do nosso projeto, sem que o Git crie uma subpasta, siga atentamente os comandos abaixo:
```bash
mkdir desafio-cicd
cd desafio-cicd
```
```bash
git clone https://github.com/leonildolinck/api-saudacoes-aleatorias.git .
```
> 💡
> O "." (ponto) no final do comando indica que os arquivos devem ser clonados diretamente na pasta atual, sem criar uma subpasta com o nome do repositório, certifique-se que a aplicação está no diretório raiz.

Após clonar o repositório, você verá os seguintes arquivos:

```
├── database/
├── docs/
├── handlers/
├── infra/
├── models/
├── .envrc
├── .gitignore
├── Dockerfile
├── README.md
├── devbox.json
├── go.mod
├── go.sum
└── main.go
```


Caso queira executar a aplicação localmente (precisa do [Docker](https://docs.docker.com/engine/install/) instalado):

```bash
docker build -t leonildolinck/api-saudacoes-aleatorias:latest .
docker run -p 8080:8080 leonildolinck/api-saudacoes-aleatorias:latest
```

Teste com:

```bash
curl http://localhost:8080/api/saudacoes/aleatorio
```


















### Build da imagem
 
```bash
cd site
docker build -t leonildolinck/gerador-saudacoes:1.0 .
```
![Build](./screenshots/site-docker-build.png)

### Rodar localmente

```bash
docker run -d -p 8080:80 leonildolinck/gerador-saudacoes:1.0
```

![Run](./screenshots/site-docker-run.png)

Acesse via: [http://localhost:8080](http://localhost:8080)

![Localhost](./screenshots/site-localhost.png)

> **Nota:** Perceba que o site apresenta erro, devido a falha em acessar os containeres back-end, vamos resolver isso a seguir.

---

## 2. Backend: Microsserviço de Pessoas Aleatórias

### Back-end

Agora que temos o front-end ativo, precisamos colocar no ar os servidores back-end, que serão responsáveis por toda a parte de respostas dinâmicas do site, como acessar o banco de dados de saudações ou inserir novas saudações.

### Dockerfile (Multi-stage)

O Multi-Stage Build serve para criar imagens Docker mais leves e seguras, separando o processo de construção (instalação de dependências, compilação, etc.) do ambiente final de execução da aplicação.

```dockerfile
# Builder
FROM python:3.13-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip wheel --no-cache-dir --wheel-dir /app/wheels -r requirements.txt

# Final
FROM python:3.13-slim
WORKDIR /app
COPY --from=builder /app/wheels /app/wheels
COPY . .
RUN pip install --no-cache-dir /app/wheels/*
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Build da imagem

```bash
cd api-pessoas-aleatorias
docker build -t leonildolinck/api-pessoas-aleatorias:1.0 .
```
![Pessoas Docker Build](./screenshots/pessoas-docker-build2.png)

### Rodar localmente

```bash
docker run -d -p 8000:8000 leonildolinck/api-pessoas-aleatorias:1.0
```
![Pessoas Docker Run](./screenshots/pessoas-docker-run.png)

Acesse/teste via:

- [http://localhost:8000/docs](http://localhost:8000/docs)
- [http://localhost:8000/pessoas/aleatoria](http://localhost:8000/pessoas/aleatoria)

---

## 3. Backend: Microsserviço de Saudações Aleatórias

### Dockerfile (Multi-stage)

Novamente, o Multi-Stage Build serve para criar imagens Docker mais leves e seguras, separando o processo de construção (instalação de dependências, compilação, etc.) do ambiente final de execução da aplicação.

```dockerfile
# Builder
FROM golang:1.24-alpine AS builder
RUN apk add --no-cache build-base gcc
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=1 GOOS=linux go build -a -installsuffix cgo -o /app/main .

# Final
FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/main .
EXPOSE 8080
CMD ["./main"]
```

### Build da imagem

```bash
docker build -t leonildolinck/api-saudacoes-aleatorias:1.0 .
```
![Pessoas Docker Build](./screenshots/saudacoes-docker-build.png)

### Rodar localmente

```bash
docker run -d -p 8081:8080 leonildolinck/api-saudacoes-aleatorias:1.0
```

![Pessoas Docker Run](./screenshots/saudacoes-docker-run.png)

Testes via `curl`:

```bash
curl http://localhost:8081/api/saudacoes/aleatorio
```
![Saudações CURL](./screenshots/saudacoes-curl.png)

---

## Utilizando Docker Compose

Gerenciar vários containers manualmente com ``docker run`` pode se tornar trabalhoso e propenso a erros. Para simplificar e automatizar o processo, utilizamos o **Docker Compose**, uma ferramenta que nos permite definir e orquestrar aplicações multi-containers a partir de um único arquivo: ``docker-compose.yml``.

Com ele, conseguimos:

Subir os três serviços (frontend, API de pessoas e API de saudações) com um único comando.

Garantir que os containers se comuniquem entre si por nome (sem precisar de IPs fixos).

Facilitar o desenvolvimento local.

```yaml
services:
  site:
    image: leonildolinck/gerador-saudacoes:1.0
    ports:
      - "80:80"
    depends_on:
      - api-pessoas-aleatorias
      - api-saudacoes-aleatorias
    networks:
      - backend

  api-pessoas-aleatorias:
    image: leonildolinck/api-pessoas-aleatorias:1.0
    ports:
      - "8000:8000"
    networks:
      - backend

  api-saudacoes-aleatorias:
    image: leonildolinck/api-saudacoes-aleatorias:1.0
    ports:
      - "8081:8080"
    networks:
      - backend
networks:
  backend: {}
```

```bash
# Subir os containers em segundo plano:
docker compose up -d
```

![Compose UP](./screenshots/docker-compose.png)

```bash
# Derrubar os containers e liberar os recursos:
docker compose down
```

![Compose Down](./screenshots/compose-down.png)

## Resultado final

Com isso, temos o site rodando em um container com Nginx, a API de Pessoas em um container com Python, e a API de Saudações em um container com Go.


![Saudações CURL](./screenshots/site-funcionando.png)

## Publicando no Docker Hub

Agora chegou o momento de publicar nossas imagens no Docker Hub, um repositório de imagens de containers, assim como o GitHub é um repositório para códigos-fonte.

1. Faça login:

```bash
docker login
```

2. Envie as imagens:

```bash
docker push leonildolinck/gerador-saudacoes:1.0
```
![Site Push](./screenshots/site-push.png)
```bash
docker push leonildolinck/api-pessoas-aleatorias:1.0
```
![Pessoas Push](./screenshots/pessoas-push.png)
```bash
docker push leonildolinck/api-saudacoes-aleatorias:1.0
```
![Saudações Push](./screenshots/saudacoes-push.png)

---

![Saudações Push](./screenshots/dockerhub.png)

## Conclusão

Este projeto explora o uso de **Docker** e **microserviços** para construir uma aplicação modular, leve e pronta para produção. Cada serviço é independente e pode ser versionado e publicado separadamente no Docker Hub.

---

## Contato

- **Email:** leonildolinck@gmail.com  
- **Discord:** leonildo  
- **LinkedIn:** [linkedin.com/in/leonildolinck](https://linkedin.com/in/leonildolinck)