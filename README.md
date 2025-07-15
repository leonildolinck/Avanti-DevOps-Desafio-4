# Projeto - Gerador de Saudações Aleatórias (Dockerizado)

![Banner](./screenshots/banner.png)

Este repositório apresenta um projeto completo de microsserviços desenvolvido com Docker e publicado no Docker Hub. Ele é composto por três partes principais:

- **Frontend (HTML estático com Nginx)**  
- **Microsserviço de Pessoas Aleatórias (FastAPI + SQLite)**  
- **Microsserviço de Saudações Aleatórias (Go + SQLite)**  

---

## Sumário

- [Projeto - Gerador de Saudações Aleatórias (Dockerizado)](#projeto---gerador-de-saudações-aleatórias-dockerizado)
  - [Sumário](#sumário)
  - [Pré-requisitos](#pré-requisitos)
  - [Arquitetura do Projeto](#arquitetura-do-projeto)
  - [1. Frontend: Site Gerador de Saudações](#1-frontend-site-gerador-de-saudações)
    - [Dockerfile](#dockerfile)
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
- Conta no [Docker Hub](https://hub.docker.com/)
- Terminal (Linux/Mac) ou PowerShell (Windows)

---

## Arquitetura do Projeto

```
[ Navegador ]
     ↓
[ Nginx (Frontend) ]
     ↓
 ┌────────────────────────────┐        ┌──────────────────────────┐
 │ API - Pessoas (Em Python)  │ <----> │ API - Saudações (em Go)  │
 └────────────────────────────┘        └──────────────────────────┘
```

---

## 1. Frontend: Site Gerador de Saudações

### Dockerfile

O `Dockerfile` é um arquivo de texto que contém as instruções para o Docker montar nossa imagem. Criei um arquivo chamado `Dockerfile` (sem extensão) na raiz do projeto, ao lado do `index.html`, com o seguinte conteúdo:

```dockerfile
# --- Estágio 1: Definir a imagem base ---
# Usamos a imagem oficial do Nginx com a tag 'alpine'.
# 'alpine' resulta em uma imagem muito menor, o que é ótimo para produção.
FROM nginx:alpine

# --- Estágio 2: Copiar os arquivos do projeto ---
# Copia o arquivo 'index.html' da sua máquina local (o contexto do build)
# para o diretório padrão onde o Nginx serve os arquivos HTML.
COPY index.html /usr/share/nginx/html/index.html

# --- Estágio 3: Expor a porta ---
# Informa ao Docker que o contêiner escutará na porta 80 em tempo de execução.
# Esta é a porta padrão do Nginx.
EXPOSE 80
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