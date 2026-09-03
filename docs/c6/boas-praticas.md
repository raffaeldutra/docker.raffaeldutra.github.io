# Boas práticas de imagens e Dockerfile

Um bom Dockerfile gera imagens **pequenas**, **rápidas de construir** (bom uso de
cache), **reprodutíveis** e **seguras**. As recomendações abaixo são cumulativas
— quase todas valem para qualquer linguagem.

## Cache de camadas: ordene do que muda menos para o que muda mais

Cada instrução (`RUN`, `COPY`, `ADD`) vira uma camada. O BuildKit reaproveita a
camada se a instrução **e** as entradas dela não mudaram. Quando uma camada
invalida, **todas as seguintes** são refeitas.

❌ Ruim — qualquer alteração no código reinstala todas as dependências:

```dockerfile
FROM node:20-slim
WORKDIR /app
COPY . .
RUN npm ci
CMD ["node", "server.js"]
```

✅ Bom — dependências só são reinstaladas quando o `package.json` muda:

```dockerfile
FROM node:20-slim
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
CMD ["node", "server.js"]
```

O mesmo princípio para `go.mod`/`go.sum`, `requirements.txt`, `pom.xml`,
`Gemfile`/`Gemfile.lock`, `Cargo.toml`/`Cargo.lock`.

## Uma `RUN` bem feita, não muitas `RUN` soltas

Junte comandos relacionados com `&&`, limpe o cache **na mesma camada** (limpar
numa camada seguinte não reduz o tamanho — o lixo já está numa camada anterior):

```dockerfile
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
 && rm -rf /var/lib/apt/lists/*
```

* `--no-install-recommends` evita pacotes "sugeridos" que você não pediu.
* Ordene os pacotes alfabeticamente, um por linha — _diff_ limpo em PR.
* Em Alpine: `apk add --no-cache ...` (não precisa limpar depois).

Com BuildKit, cache mounts são ainda melhores que juntar `RUN` — ver
[BuildKit e buildx](../c2/buildkit.md).

## Imagem base: pequena, oficial e fixada

| Opção | Tamanho aprox. | Observação |
|---|---|---|
| `debian:12` | ~120 MB | completa, com `apt` e shell |
| `debian:12-slim` | ~75 MB | sem docs/locales — bom padrão |
| `python:3.12-slim` | ~120 MB | oficial, baseada em slim |
| `alpine:3.20` | ~7 MB | musl libc — cuidado com wheels/CGO |
| `gcr.io/distroless/*` | ~20 MB | sem shell, sem package manager |
| `scratch` | 0 | só para binário estático |

* Prefira **imagens oficiais** ou de _Verified Publisher_.
* **Fixe a versão** (`python:3.12-slim`), nunca `latest`. Para reprodutibilidade
  total, fixe por digest: `python:3.12-slim@sha256:...`.
* Alpine reduz muito o tamanho, mas usa **musl** em vez de glibc — pode causar
  bugs sutis e builds mais lentos em Python/Node com extensões nativas. Teste.

## `.dockerignore` sempre

Evita mandar `.git`, `node_modules`, artefatos e segredos no contexto de build
(deixa o build mais rápido e evita _cache busting_):

```
.git
.gitignore
node_modules
dist
build
*.log
*.md
.env
.env.*
coverage
.vscode
Dockerfile
docker-compose*.yml
```

## Multi-stage para não carregar o toolchain

A imagem final não deve conter compilador, SDK, headers, cache de build nem
código-fonte. Ver o capítulo [Multi-stage builds](../c2/multi-stage.md). Regra
prática: se `docker history` mostra `gcc`, `go`, `maven`, `.git` ou
`node_modules` de dev na imagem de produção, algo está errado.

## Processo em PID 1: forma exec e sinais

Use a **forma exec** (lista JSON) em `ENTRYPOINT`/`CMD` para o processo virar PID
1 de verdade e receber `SIGTERM`:

```dockerfile
CMD ["nginx", "-g", "daemon off;"]      # ✅ exec
# CMD nginx -g 'daemon off;'            # ❌ shell: becomes "/bin/sh -c ...", swallows signals
```

Se a app não repassa sinais aos filhos ou deixa zumbis, adicione um init:

```
docker container run --init my-img
```

ou `ENTRYPOINT ["tini", "--"]` na imagem.

## `HEALTHCHECK`

Deixa o Docker/Compose/Swarm saber se o container está **pronto**, não só "de
pé":

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
  CMD curl -fsS http://localhost:8080/health || exit 1
```

* `--start-period` — janela inicial em que falhas não contam (app subindo).
* Use um endpoint leve; healthcheck pesado a cada 30s custa caro.
* Em imagem `distroless`/`scratch` não há `curl`; use um mini-binário de
  healthcheck ou o healthcheck nativo do orquestrador.

## Metadados: labels OCI

```dockerfile
LABEL org.opencontainers.image.title="my-api" \
      org.opencontainers.image.description="Orders API" \
      org.opencontainers.image.source="https://github.com/company/my-api" \
      org.opencontainers.image.licenses="MIT"
```

Passe versão e revisão como `ARG` no build (não fixe no arquivo):

```dockerfile
ARG VCS_REF
ARG VERSION
LABEL org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.version="$VERSION"
```

## `EXPOSE`, `WORKDIR`, `ENV`

* `EXPOSE 8080` — **documenta** a porta; não publica nada. Publicação é `-p` no
  run.
* `WORKDIR /app` — sempre com caminho absoluto; cria o diretório se não existir.
  Não use `RUN cd ...` (não persiste entre camadas).
* `ENV` — para configuração **não sensível** com _default_ sensato. Uma chave por
  linha facilita o _diff_. Nunca segredo aqui.

## Determinismo

* **Fixe versões** de tudo: imagem base, pacotes de SO críticos, dependências da
  aplicação (via lockfile).
* Não faça `curl | bash` de scripts remotos sem checar hash — a imagem deixa de
  ser reprodutível e vira risco de _supply chain_.
* Ao baixar binários, verifique checksum/assinatura:

```dockerfile
ADD --checksum=sha256:9f3c... https://example.com/tool.tgz /tmp/tool.tgz
```

## Linters

* **hadolint** — linter de Dockerfile (regras DL3xxx): pega `apt-get` sem
  `--no-install-recommends`, `latest`, `cd` em `RUN`, root, etc.

```
docker run --rm -i hadolint/hadolint < Dockerfile
```

* **dockerfilelint**, **checkov**, **trivy config** — checagens adicionais de
  segurança/estilo. Rode no CI.

## Exemplo consolidado (Python)

```dockerfile
# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.12

# ---------- build ----------
FROM python:${PYTHON_VERSION}-slim AS build
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
RUN python -m venv /venv
ENV PATH="/venv/bin:$PATH"
COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install -r requirements.txt

# ---------- runtime ----------
FROM python:${PYTHON_VERSION}-slim AS runtime
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PATH="/venv/bin:$PATH"
RUN groupadd --system --gid 1000 app \
 && useradd  --system --uid 1000 --gid app app
WORKDIR /app
COPY --from=build /venv /venv
COPY --chown=app:app . .
USER 1000
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:8000/health').status==200 else 1)"
ENTRYPOINT ["gunicorn", "-b", "0.0.0.0:8000", "myapp.wsgi"]
```

## Checklist de Dockerfile

- [ ] `# syntax=docker/dockerfile:1` na primeira linha
- [ ] Imagem base `-slim`/`distroless`, versão fixada
- [ ] Dependências copiadas e instaladas **antes** do código-fonte
- [ ] Multi-stage: imagem final sem toolchain nem fontes
- [ ] `.dockerignore` presente e enxuto
- [ ] `USER` não-root (UID numérico)
- [ ] `ENTRYPOINT`/`CMD` na forma exec
- [ ] `HEALTHCHECK` definido
- [ ] Sem segredo em `ENV`/`ARG`
- [ ] Labels OCI (`source`, `revision`, `version`)
- [ ] hadolint sem apontamentos no CI
