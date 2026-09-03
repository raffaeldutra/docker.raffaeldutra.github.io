# BuildKit and buildx

**BuildKit** is the modern Docker build engine (the default since Docker 23). It
replaces the legacy builder and brings smarter caching, parallel execution of
stages, special mounts on `RUN` (cache, secret, ssh, bind) and multi-platform
builds. **buildx** is the CLI that exposes these features
(`docker buildx ...`), today already built into Docker.

## Enabling BuildKit

Since Docker 23 it is already the default. To force it on old versions:

```
export DOCKER_BUILDKIT=1
docker build -t app .
```

Every Dockerfile that uses BuildKit features should start with the syntax
directive, which also guarantees the latest version of the frontend:

```dockerfile
# syntax=docker/dockerfile:1
```

## `RUN --mount`: mounts during the build

### `type=cache` — persistent cache between builds

Mounts a directory that **survives from one build to the next** without entering
the image. Ideal for package manager caches:

```dockerfile
# syntax=docker/dockerfile:1
FROM node:20-slim
WORKDIR /app
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci
COPY . .
```

Other target examples:

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

> For the `apt` cache to work, remove the line
> `rm -rf /var/lib/apt/lists/*` and delete
> `/etc/apt/apt.conf.d/docker-clean` (`RUN rm -f /etc/apt/apt.conf.d/docker-clean`).

### `type=bind` — mount the context without `COPY`

Uses a file from the build context only during that `RUN`, without creating a
layer:

```dockerfile
RUN --mount=type=bind,source=go.sum,target=go.sum \
    --mount=type=bind,source=go.mod,target=go.mod \
    go mod download
```

### `type=secret` — secrets that do not go into the image

```dockerfile
# syntax=docker/dockerfile:1
FROM alpine
RUN --mount=type=secret,id=npmrc,target=/root/.npmrc \
    npm ci
```

```
docker build --secret id=npmrc,src=$HOME/.npmrc -t app .
```

The file exists only during that `RUN`. It does not appear in `docker history`,
does not stay in a layer, does not stay in the cache. This is how you pass a
private repository token, a license key, an artifact credential.

### `type=ssh` — use the host's SSH agent

For `git clone` of a private repository over SSH:

```dockerfile
RUN --mount=type=ssh git clone git@github.com:company/private-lib.git
```

```
docker build --ssh default -t app .
```

## External cache: `--cache-to` / `--cache-from`

In CI, each job starts from scratch. BuildKit exports and imports the cache from
a registry or directory:

```
docker buildx build \
  --cache-to   type=registry,ref=registry.example.com/app:buildcache,mode=max \
  --cache-from type=registry,ref=registry.example.com/app:buildcache \
  -t registry.example.com/app:1.2.3 --push .
```

* `mode=max` exports the cache of **all** layers, including those of intermediate
  stages (multi-stage). `mode=min` (default) exports only those of the final
  image.
* Backend alternatives: `type=local,dest=/path` / `type=gha` (GitHub Actions)
  / `type=inline` (embeds the cache in the image itself, `mode=min` only).

## Multi-platform build

An image that runs on `amd64` and `arm64` from a single machine. It needs a
builder with the `docker-container` driver:

```
docker buildx create --name multi --driver docker-container --use
docker buildx inspect --bootstrap
```

Build and push the multi-arch manifest:

```
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t registry.example.com/app:1.2.3 \
  --push .
```

`--push` is required here because Docker's traditional local image store does not
keep a multi-platform manifest list. To load only the one for your machine, use
`--load` with a single `--platform`.

Emulating another architecture (when there is no native runner):

```
docker run --privileged --rm tonistiigi/binfmt --install all
```

In the Dockerfile, use the automatic arguments so you do not emulate the
compilation:

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

`$BUILDPLATFORM` is the machine that compiles; `$TARGETOS`/`$TARGETARCH` are the
target — this way Go does a native _cross-compile_, without QEMU.

## `docker buildx bake`

Describes several build _targets_ in a file (`docker-bake.hcl`) and runs
everything with one command — useful for monorepos:

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

## Inspecting what was built

```
docker buildx build --progress=plain .    # full log, without the compact UI
docker buildx history                      # recent builds (Docker Desktop / newer versions)
docker buildx du                           # space used by the builder cache
docker buildx prune                        # clears the builder cache
```

## Generating SBOM and provenance

BuildKit can attach an _SBOM_ (package list) and an SLSA provenance attestation
to the image on push:

```
docker buildx build --sbom=true --provenance=true \
  -t registry.example.com/app:1.2.3 --push .
```

This feeds audit tools and vulnerability scanners. See also
[Distributing images](../c5/distribuindo-imagens.md).
