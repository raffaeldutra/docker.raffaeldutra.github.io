# BuildKit e buildx

**BuildKit** é o motor de build do Docker moderno (padrão desde o Docker 23). Ele
substitui o builder legado e traz cache mais inteligente, execução paralela de
estágios, montagens especiais no `RUN` (cache, secret, ssh, bind) e build
multi-plataforma. **buildx** é a CLI que expõe esses recursos
(`docker buildx ...`), hoje já embutida no Docker.

## Ligando o BuildKit

Desde o Docker 23 já é o padrão. Para forçar em versões antigas:

```
export DOCKER_BUILDKIT=1
docker build -t app .
```

Todo Dockerfile que usa recursos do BuildKit deve começar com a diretiva de
sintaxe, que também garante a versão mais recente do frontend:

```dockerfile
# syntax=docker/dockerfile:1
```

## `RUN --mount`: montagens durante o build

### `type=cache` — cache persistente entre builds

Monta um diretório que **sobrevive de um build para o outro** sem entrar na
imagem. Ideal para caches de gerenciadores de pacote:

```dockerfile
# syntax=docker/dockerfile:1
FROM node:20-slim
WORKDIR /app
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci
COPY . .
```

Outros exemplos de alvo:

```dockerfile
# apt
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends curl

# pip
RUN --mount=type=cache,target=/root/.cache/pip pip install -r requirements.txt

# go
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/go/pkg/mod \
    go build ./...
```

> Para o cache de `apt` funcionar, remova a linha
> `rm -rf /var/lib/apt/lists/*` e apague o
> `/etc/apt/apt.conf.d/docker-clean` (`RUN rm -f /etc/apt/apt.conf.d/docker-clean`).

### `type=bind` — montar o contexto sem `COPY`

Usa um arquivo do contexto de build só durante aquele `RUN`, sem criar camada:

```dockerfile
RUN --mount=type=bind,source=go.sum,target=go.sum \
    --mount=type=bind,source=go.mod,target=go.mod \
    go mod download
```

### `type=secret` — segredos que não vão para a imagem

```dockerfile
# syntax=docker/dockerfile:1
FROM alpine
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm ci
```

```
docker build --secret id=npmrc,src=$HOME/.npmrc -t app .
```

O arquivo existe só durante aquele `RUN`. Não aparece em `docker history`, não
fica em camada, não fica no cache. É assim que se passa token de repositório
privado, chave de licença, credencial de artefato.

### `type=ssh` — usar o agente SSH do host

Para `git clone` de repositório privado por SSH:

```dockerfile
RUN --mount=type=ssh git clone git@github.com:empresa/lib-privada.git
```

```
docker build --ssh default -t app .
```

## Cache externo: `--cache-to` / `--cache-from`

Em CI, cada job começa do zero. O BuildKit exporta e importa cache de um
registry ou diretório:

```
docker buildx build \
  --cache-to   type=registry,ref=registry.example.com/app:buildcache,mode=max \
  --cache-from type=registry,ref=registry.example.com/app:buildcache \
  -t registry.example.com/app:1.2.3 --push .
```

* `mode=max` exporta o cache de **todas** as camadas, inclusive as de estágios
  intermediários (multi-stage). `mode=min` (padrão) exporta só as da imagem
  final.
* Alternativas de backend: `type=local,dest=/path` / `type=gha` (GitHub Actions)
  / `type=inline` (embute o cache na própria imagem, só `mode=min`).

## Build multi-plataforma

Uma imagem que roda em `amd64` e `arm64` a partir de uma máquina só. Precisa de
um builder com o driver `docker-container`:

```
docker buildx create --name multi --driver docker-container --use
docker buildx inspect --bootstrap
```

Build e push do manifesto multi-arch:

```
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t registry.example.com/app:1.2.3 \
  --push .
```

O `--push` é necessário aqui porque o armazenamento local de imagens do Docker
tradicionalmente não guarda uma lista de manifestos multi-plataforma. Para
carregar só a da sua máquina, use `--load` com um único `--platform`.

Emulação de outra arquitetura (quando não há runner nativo):

```
docker run --privileged --rm tonistiigi/binfmt --install all
```

No Dockerfile, use os argumentos automáticos para não emular a compilação:

```dockerfile
# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM golang:1.23 AS build
ARG TARGETOS TARGETARCH
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /out/app .

FROM alpine
COPY --from=build /out/app /usr/local/bin/app
```

`$BUILDPLATFORM` é a máquina que compila; `$TARGETOS`/`$TARGETARCH` são o destino
— assim o Go faz _cross-compile_ nativo, sem QEMU.

## `docker buildx bake`

Descreve vários _targets_ de build em um arquivo (`docker-bake.hcl`) e roda tudo
com um comando — útil para monorepos:

```hcl
group "default" {
  targets = ["api", "worker"]
}

target "api" {
  context    = "./api"
  tags       = ["registry.example.com/api:dev"]
  platforms  = ["linux/amd64", "linux/arm64"]
}

target "worker" {
  context = "./worker"
  tags    = ["registry.example.com/worker:dev"]
}
```

```
docker buildx bake --push
```

## Inspecionar o que foi construído

```
docker buildx build --progress=plain .    # log completo, sem a UI compacta
docker buildx history                      # builds recentes (Docker Desktop / versões novas)
docker buildx du                           # espaço ocupado pelo cache do builder
docker buildx prune                        # limpa o cache do builder
```

## Gerar SBOM e proveniência

O BuildKit pode anexar um _SBOM_ (lista de pacotes) e atestado de proveniência
SLSA à imagem no push:

```
docker buildx build --sbom=true --provenance=true \
  -t registry.example.com/app:1.2.3 --push .
```

Isso alimenta ferramentas de auditoria e scanners de vulnerabilidade. Ver também
[Distribuindo imagens](../c5/distribuindo-imagens.md).
