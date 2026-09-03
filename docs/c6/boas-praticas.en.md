# Image and Dockerfile best practices

A good Dockerfile produces images that are **small**, **fast to build** (good
cache use), **reproducible** and **secure**. The recommendations below are
cumulative — almost all of them apply to any language.

## Layer cache: order from what changes least to what changes most

Each instruction (`RUN`, `COPY`, `ADD`) becomes a layer. BuildKit reuses the
layer if the instruction **and** its inputs did not change. When a layer is
invalidated, **all the following ones** are rebuilt.

❌ Bad — any change to the code reinstalls all dependencies:

```dockerfile
FROM node:20-slim
WORKDIR /app
COPY . .
RUN npm ci
CMD ["node", "server.js"]
```

✅ Good — dependencies are only reinstalled when `package.json` changes:

```dockerfile
FROM node:20-slim
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
CMD ["node", "server.js"]
```

The same principle for `go.mod`/`go.sum`, `requirements.txt`, `pom.xml`,
`Gemfile`/`Gemfile.lock`, `Cargo.toml`/`Cargo.lock`.

## One well-crafted `RUN`, not many loose `RUN`s

Join related commands with `&&`, clean the cache **in the same layer** (cleaning
in a later layer does not reduce the size — the junk is already in a previous
layer):

```dockerfile
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
 && rm -rf /var/lib/apt/lists/*
```

* `--no-install-recommends` avoids "suggested" packages you did not ask for.
* Order the packages alphabetically, one per line — a clean _diff_ in the PR.
* On Alpine: `apk add --no-cache ...` (no need to clean up afterwards).

With BuildKit, cache mounts are even better than joining `RUN`s — see
[BuildKit and buildx](../c2/buildkit.md).

## Base image: small, official and pinned

| Option | Approx. size | Note |
|---|---|---|
| `debian:12` | ~120 MB | complete, with `apt` and a shell |
| `debian:12-slim` | ~75 MB | no docs/locales — a good default |
| `python:3.12-slim` | ~120 MB | official, based on slim |
| `alpine:3.20` | ~7 MB | musl libc — watch out for wheels/CGO |
| `gcr.io/distroless/*` | ~20 MB | no shell, no package manager |
| `scratch` | 0 | for a static binary only |

* Prefer **official images** or _Verified Publisher_ ones.
* **Pin the version** (`python:3.12-slim`), never `latest`. For full
  reproducibility, pin by digest: `python:3.12-slim@sha256:...`.
* Alpine reduces size a lot, but uses **musl** instead of glibc — it can cause
  subtle bugs and slower builds in Python/Node with native extensions. Test.

## Always use `.dockerignore`

It avoids sending `.git`, `node_modules`, artifacts and secrets in the build
context (makes the build faster and avoids _cache busting_):

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

## Multi-stage so you do not carry the toolchain

The final image should not contain a compiler, SDK, headers, build cache or
source code. See the [Multi-stage builds](../c2/multi-stage.md) chapter. Rule of
thumb: if `docker history` shows `gcc`, `go`, `maven`, `.git` or dev
`node_modules` in the production image, something is wrong.

## Process at PID 1: exec form and signals

Use the **exec form** (JSON list) in `ENTRYPOINT`/`CMD` so the process really
becomes PID 1 and receives `SIGTERM`:

```dockerfile
CMD ["nginx", "-g", "daemon off;"]      # ✅ exec
# CMD nginx -g 'daemon off;'            # ❌ shell: becomes "/bin/sh -c ...", swallows signals
```

If the app does not forward signals to its children or leaves zombies, add an
init:

```
docker container run --init my-img
```

or `ENTRYPOINT ["tini", "--"]` in the image.

## `HEALTHCHECK`

Lets Docker/Compose/Swarm know whether the container is **ready**, not just "up":

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
  CMD curl -fsS http://localhost:8080/health || exit 1
```

* `--start-period` — the initial window in which failures do not count (the app
  is starting).
* Use a lightweight endpoint; a heavy healthcheck every 30s is expensive.
* On a `distroless`/`scratch` image there is no `curl`; use a mini healthcheck
  binary or the orchestrator's native healthcheck.

## Metadata: OCI labels

```dockerfile
LABEL org.opencontainers.image.title="my-api" \
      org.opencontainers.image.description="Orders API" \
      org.opencontainers.image.source="https://github.com/company/my-api" \
      org.opencontainers.image.licenses="MIT"
```

Pass version and revision as `ARG` at build time (do not hardcode them in the
file):

```dockerfile
ARG VCS_REF
ARG VERSION
LABEL org.opencontainers.image.revision="$VCS_REF" \
      org.opencontainers.image.version="$VERSION"
```

## `EXPOSE`, `WORKDIR`, `ENV`

* `EXPOSE 8080` — **documents** the port; it does not publish anything.
  Publishing is `-p` at run time.
* `WORKDIR /app` — always with an absolute path; it creates the directory if it
  does not exist. Do not use `RUN cd ...` (it does not persist between layers).
* `ENV` — for **non-sensitive** configuration with a sensible _default_. One key
  per line makes the _diff_ easier. Never a secret here.

## Determinism

* **Pin the versions** of everything: base image, critical OS packages,
  application dependencies (via a lockfile).
* Do not `curl | bash` remote scripts without checking a hash — the image stops
  being reproducible and becomes a _supply chain_ risk.
* When downloading binaries, verify the checksum/signature:

```dockerfile
ADD --checksum=sha256:9f3c... https://example.com/tool.tgz /tmp/tool.tgz
```

## Linters

* **hadolint** — a Dockerfile linter (DL3xxx rules): catches `apt-get` without
  `--no-install-recommends`, `latest`, `cd` in `RUN`, root, etc.

```
docker run --rm -i hadolint/hadolint < Dockerfile
```

* **dockerfilelint**, **checkov**, **trivy config** — additional
  security/style checks. Run them in CI.

## Consolidated example (Python)

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

## Dockerfile checklist

- [ ] `# syntax=docker/dockerfile:1` on the first line
- [ ] `-slim`/`distroless` base image, pinned version
- [ ] Dependencies copied and installed **before** the source code
- [ ] Multi-stage: final image with no toolchain or sources
- [ ] `.dockerignore` present and lean
- [ ] Non-root `USER` (numeric UID)
- [ ] `ENTRYPOINT`/`CMD` in exec form
- [ ] `HEALTHCHECK` defined
- [ ] No secret in `ENV`/`ARG`
- [ ] OCI labels (`source`, `revision`, `version`)
- [ ] hadolint with no findings in CI
