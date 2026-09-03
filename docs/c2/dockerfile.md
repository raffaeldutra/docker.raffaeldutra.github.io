# Dockerfile

Chegamos ao arquivo principal do Docker, o **Dockerfile**: um arquivo texto com
todas as instruções para gerar uma imagem.

Se você já conhece um pouco de `CLI` de GNU/Linux, não terá dificuldade, pois
boa parte das instruções são comandos que você já usa.

## Principais instruções

* `FROM` — define a imagem base. Pode aparecer mais de uma vez (multi-stage build).
* `ARG` — variável disponível apenas durante o build (`docker build --build-arg`).
* `LABEL` — metadados da imagem (descrição, `org.opencontainers.image.*`, etc.).
* `ENV` — variáveis de ambiente que ficam disponíveis no container. Use a forma
  `ENV chave=valor`.
* `RUN` — executa um comando na etapa de build, gerando uma nova camada.
* `WORKDIR` — diretório de trabalho para as instruções seguintes.
* `COPY` — copia arquivos e diretórios do contexto de build para a imagem.
  **Prefira `COPY` a `ADD`.**
* `ADD` — como `COPY`, mas também extrai tarballs locais e aceita URLs. Use só
  quando precisar desse comportamento.
* `USER` — usuário que executa as instruções seguintes e o processo do container.
  Rode como usuário não-root sempre que possível.
* `EXPOSE` — documenta a porta que o container escuta (não publica nada sozinho).
* `VOLUME` — marca um caminho como ponto de montagem de volume.
* `HEALTHCHECK` — comando que o Docker usa para saber se o container está saudável.
* `ENTRYPOINT` — o executável principal do container.
* `CMD` — argumentos padrão para o `ENTRYPOINT`, ou o comando padrão quando não
  há `ENTRYPOINT`.
* `STOPSIGNAL` — sinal enviado ao parar o container.

> Use `COPY`/`ADD` e `RUN` na forma **exec** (lista JSON) para `ENTRYPOINT` e
> `CMD`: `CMD ["nginx", "-g", "daemon off;"]`. Assim o processo recebe os sinais
> corretamente (PID 1).

## `.dockerignore`

Coloque um arquivo `.dockerignore` ao lado do Dockerfile para manter o contexto
de build pequeno e não copiar `.git`, `node_modules`, segredos e afins:

```
.git
node_modules
*.log
.env
```

## Exemplo

```dockerfile
# syntax=docker/dockerfile:1
FROM nginx:1.27

LABEL org.opencontainers.image.description="Workshop example image."
LABEL org.opencontainers.image.authors="Rafael Dutra <raffaeldutra@gmail.com>"

ENV EVENT="Docker Workshop" \
    YEAR="2026"

RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -fsS http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
```

## Multi-stage build

Para gerar imagens finais pequenas, compile em um estágio e copie só o
artefato para uma imagem enxuta:

```dockerfile
# syntax=docker/dockerfile:1
FROM golang:1.23 AS build
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -o /app ./cmd/app

FROM gcr.io/distroless/static-debian12
COPY --from=build /app /app
USER nonroot:nonroot
ENTRYPOINT ["/app"]
```
