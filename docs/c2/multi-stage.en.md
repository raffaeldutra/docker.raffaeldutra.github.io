# Multi-stage builds

A _multi-stage build_ uses **several `FROM` instructions in the same Dockerfile**.
Each `FROM` starts a new stage; you build in a "fat" stage (with compilers, SDKs,
build dependencies) and copy only the final artifact into a "lean" stage that
becomes the published image.

The gain: the final image does not carry the toolchain, package caches, source
code or secrets used during the build.

## The problem it solves

Without multi-stage, everything you install to compile stays in the image:

```dockerfile
FROM node:20
WORKDIR /app
COPY package*.json ./
RUN npm ci                 # includes devDependencies
COPY . .
RUN npm run build          # generates dist/
CMD ["node", "dist/server.js"]
```

Result: an image with the entire `node_modules` (dev included), source code, the
npm cache, git — easily 1 GB+.

## The multi-stage form

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

`COPY --from=build` pulls files from the previous stage. The final image is just
`node:20-slim` + production `node_modules` + `dist/`. Nothing from the TypeScript
compiler, no `.git`, no cache.

## `COPY --from`

You can copy from:

* **another stage**, by name: `COPY --from=build /app/bin /usr/local/bin`
* **another stage**, by index: `COPY --from=0 ...` (the first `FROM`)
* **an external image**, without declaring it as a stage:

```dockerfile
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY --from=nginx:1.27 /etc/nginx/nginx.conf /etc/nginx/nginx.conf
```

## Stopping at a specific stage

`docker build --target` builds only up to the requested stage. Great for having
one development/test image and one production image **in the same Dockerfile**:

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

If you do not pass `--target`, the build goes to the **last** stage in the file.

## Stages are built on demand

BuildKit (the default build engine since Docker 23) builds a dependency graph and
**only builds the stages the target needs**. In the example above,
`--target prod` does not run the `test` stage. Independent stages are built in
**parallel**.

## A shared "base" stage

Reuse dependency installation across stages so you do not repeat it:

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

## The "build → distroless / scratch" pattern

For static binaries (Go, Rust, C), the final stage can be `scratch` (empty) or
`distroless` (only libc + certificates, no shell):

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

`scratch` gets you images of a few MB. The cost: **there is no shell** for
`docker exec ... sh` and no `ping`/`curl` for debugging — debug with
`nicolaka/netshoot` sharing the namespace (`--network container:...`,
`--pid container:...`).

## Copying the same artifact for several architectures

Combined with `--platform` and `buildx`, each platform runs its own build stage.
See [BuildKit and buildx](buildkit.md).

## Multi-stage-specific best practices

* Give **names** to stages (`AS build`); numeric indexes break when you reorder.
* Put `COPY package.json` / `go.mod` **before** copying the code to take
  advantage of layer cache in dependency installation.
* Do not `--from` a stage you do not need — BuildKit will not build it, but the
  reader gets confused.
* If a secret is only needed at build time (private repository token), use
  `RUN --mount=type=secret` in the build stage — it **will not** end up in the
  final image anyway, but this way it also does not stay in the cache.
