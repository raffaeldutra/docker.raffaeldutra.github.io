# Dockerfile

We have reached Docker's main file, the **Dockerfile**: a text file with all the
instructions to build an image.

If you already know a bit of GNU/Linux `CLI`, you will not struggle, because most
of the instructions are commands you already use.

## Main instructions

* `FROM` — defines the base image. It can appear more than once (multi-stage build).
* `ARG` — a variable available only during the build (`docker build --build-arg`).
* `LABEL` — image metadata (description, `org.opencontainers.image.*`, etc.).
* `ENV` — environment variables that stay available in the container. Use the
  `ENV key=value` form.
* `RUN` — runs a command during the build step, creating a new layer.
* `WORKDIR` — the working directory for the following instructions.
* `COPY` — copies files and directories from the build context into the image.
  **Prefer `COPY` over `ADD`.**
* `ADD` — like `COPY`, but it also extracts local tarballs and accepts URLs. Use
  it only when you need that behavior.
* `USER` — the user that runs the following instructions and the container
  process. Run as a non-root user whenever possible.
* `EXPOSE` — documents the port the container listens on (it does not publish
  anything by itself).
* `VOLUME` — marks a path as a volume mount point.
* `HEALTHCHECK` — a command Docker uses to know whether the container is healthy.
* `ENTRYPOINT` — the container's main executable.
* `CMD` — default arguments for the `ENTRYPOINT`, or the default command when
  there is no `ENTRYPOINT`.
* `STOPSIGNAL` — the signal sent when stopping the container.

> Use the **exec** form (JSON list) for `COPY`/`ADD` and `RUN`, and for
> `ENTRYPOINT` and `CMD`: `CMD ["nginx", "-g", "daemon off;"]`. That way the
> process receives signals correctly (PID 1).

## `.dockerignore`

Put a `.dockerignore` file next to the Dockerfile to keep the build context small
and avoid copying `.git`, `node_modules`, secrets and the like:

```
.git
node_modules
*.log
.env
```

## Example

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

To produce small final images, build in one stage and copy only the artifact
into a lean image:

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
