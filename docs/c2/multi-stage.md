# Multi-stage builds

Um _multi-stage build_ usa **vários `FROM` no mesmo Dockerfile**. Cada `FROM`
inicia um novo estágio; você compila em um estágio "gordo" (com compiladores,
SDKs, dependências de build) e copia só o artefato final para um estágio
"magro" que vira a imagem publicada.

O ganho: a imagem final não carrega toolchain, cache de pacotes, código-fonte
nem segredos usados no build.

## O problema que ele resolve

Sem multi-stage, tudo o que você instala para compilar fica na imagem:

```dockerfile
FROM node:20
WORKDIR /app
COPY package*.json ./
RUN npm ci                 # includes devDependencies
COPY . .
RUN npm run build          # generates dist/
CMD ["node", "dist/server.js"]
```

Resultado: imagem com `node_modules` inteiro (dev incluso), código-fonte, cache
do npm, git — facilmente 1 GB+.

## A forma multi-stage

```dockerfile
# syntax=docker/dockerfile:1

# ---------- stage 1: build ----------
FROM node:20 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build && npm prune --omit=dev

# ---------- stage 2: runtime ----------
FROM node:20-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
USER node
EXPOSE 3000
CMD ["node", "dist/server.js"]
```

O `COPY --from=build` puxa arquivos do estágio anterior. A imagem final é só o
`node:20-slim` + `node_modules` de produção + `dist/`. Nada do compilador
TypeScript, nada de `.git`, nada de cache.

## `COPY --from`

Você pode copiar de:

* **outro estágio**, por nome: `COPY --from=build /app/bin /usr/local/bin`
* **outro estágio**, por índice: `COPY --from=0 ...` (o primeiro `FROM`)
* **uma imagem externa**, sem declará-la como estágio:

```dockerfile
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY --from=nginx:1.27 /etc/nginx/nginx.conf /etc/nginx/nginx.conf
```

## Parar em um estágio específico

`docker build --target` compila só até o estágio pedido. Ótimo para ter uma
imagem de desenvolvimento/teste e outra de produção **no mesmo Dockerfile**:

```dockerfile
# syntax=docker/dockerfile:1
FROM golang:1.23 AS base
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .

FROM base AS test
RUN go vet ./... && go test ./...

FROM base AS build
RUN CGO_ENABLED=0 go build -o /out/app ./cmd/app

FROM gcr.io/distroless/static-debian12 AS prod
COPY --from=build /out/app /app
USER nonroot:nonroot
ENTRYPOINT ["/app"]
```

```
docker build --target test  -t app:test .     # runs the tests during the build
docker build --target prod   -t app:1.4.0 .    # minimal final image
```

Se você não passar `--target`, o build vai até o **último** estágio do arquivo.

## Estágios são construídos sob demanda

O BuildKit (build engine padrão desde o Docker 23) monta um grafo de
dependências e **só constrói os estágios que o alvo precisa**. No exemplo acima,
`--target prod` não executa o estágio `test`. Estágios independentes são
construídos em **paralelo**.

## Um estágio "base" compartilhado

Reaproveite instalação de dependências entre estágios para não repetir:

```dockerfile
FROM python:3.12-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM base AS lint
RUN pip install --no-cache-dir ruff && ruff check .

FROM base AS app
COPY . .
USER 1000
CMD ["python", "-m", "myapp"]
```

## Padrão "build → distroless / scratch"

Para binários estáticos (Go, Rust, C), o estágio final pode ser
`scratch` (vazio) ou `distroless` (só libc + certificados, sem shell):

```dockerfile
# syntax=docker/dockerfile:1
FROM rust:1.81 AS build
WORKDIR /src
COPY . .
RUN cargo build --release

FROM gcr.io/distroless/cc-debian12
COPY --from=build /src/target/release/myapp /usr/local/bin/myapp
USER nonroot
ENTRYPOINT ["myapp"]
```

`scratch` chega a imagens de poucos MB. O custo: **não há shell** para
`docker exec ... sh` nem `ping`/`curl` para debug — depure com
`nicolaka/netshoot` compartilhando o namespace (`--network container:...`,
`--pid container:...`).

## Copiando o mesmo artefato para várias arquiteturas

Combinado com `--platform` e `buildx`, cada plataforma roda seu próprio estágio
de build. Veja [BuildKit e buildx](buildkit.md).

## Boas práticas específicas de multi-stage

* Dê **nomes** aos estágios (`AS build`); índices numéricos quebram quando você
  reordena.
* Ponha `COPY package.json` / `go.mod` **antes** de copiar o código para
  aproveitar cache de camada na instalação de dependências.
* Não use `--from` de um estágio que você não precisa — o BuildKit não vai
  construí-lo, mas o leitor se confunde.
* Se um segredo é necessário só no build (token de repositório privado), use
  `RUN --mount=type=secret` no estágio de build — ele **não** vai para a imagem
  final de qualquer forma, mas assim também não fica no cache.
