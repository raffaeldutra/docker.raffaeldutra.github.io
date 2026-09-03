# Registries and Docker Hub

A **registry** is the service that stores and distributes container images. When
you run `docker pull nginx`, Docker downloads from Docker Hub; when you run
`docker push`, it sends to the registry named in the image. This chapter covers
how image names work, authentication, and how to run your own registry.

## Anatomy of an image name

```
registry.example.com:5000/team-a/my-api:1.4.0
└──────────┬─────────────┘ └──┬─┘ └─┬──┘ └─┬─┘
        registry          namespace repo   tag
```

* **registry** — host (and port). If omitted, Docker assumes
  `docker.io` (Docker Hub).
* **namespace/repo** — organization/user and repository name. On Docker Hub,
  images with no namespace (e.g. `nginx`) are the _Docker Official Images_, which
  actually live in `docker.io/library/nginx`.
* **tag** — a mutable label for a version. If omitted, Docker uses `latest`
  (which is nothing special — it is just the default tag).

Equivalent examples:

```
docker pull nginx
docker pull nginx:latest
docker pull docker.io/library/nginx:latest
```

## Most common registries

| Registry | Host | Notes |
|---|---|---|
| Docker Hub | `docker.io` | default; has a _rate limit_ for anonymous and free accounts |
| GitHub Container Registry | `ghcr.io` | integrated with GitHub repositories/Actions |
| GitLab Container Registry | `registry.gitlab.com` | one registry per GitLab project |
| Amazon ECR | `<account>.dkr.ecr.<region>.amazonaws.com` | login via `aws ecr get-login-password` |
| Google Artifact Registry | `<region>-docker.pkg.dev` | login via `gcloud auth configure-docker` |
| Azure ACR | `<name>.azurecr.io` | `az acr login` |
| Quay | `quay.io` | built-in vulnerability scanner |

!!! note "Docker Hub rate limit"

    For anonymous users, Docker Hub limits the number of _pulls_ per time window
    (per IP). In CI this is easy to hit. Solutions: authenticate
    (`docker login`), use a _mirror_ / _pull-through_ cache, or move the base
    images to another registry.

## Authentication

```
docker login                          # Docker Hub
docker login ghcr.io                   # another registry
docker login registry.example.com:5000
```

Credentials are stored in `~/.docker/config.json`. By default, in plain text
(base64, **not** encrypted). For production/CI, use a _credential helper_
(`docker-credential-pass`, `docker-credential-ecr-login`, etc.) that keeps the
secret in the OS keychain or obtains short-lived tokens.

In CI, prefer an **access token** (revocable, scoped) over the account password:

```
echo "$REGISTRY_TOKEN" | docker login ghcr.io -u "$USERNAME" --password-stdin
```

Log out:

```
docker logout ghcr.io
```

## `docker pull`, `docker push`

```
docker pull redis:7.4
docker image tag my-api:1.4.0 registry.example.com:5000/team-a/my-api:1.4.0
docker push registry.example.com:5000/team-a/my-api:1.4.0
```

You can only `push` to a repository where you have write permission — that is why
the name must point to **your** namespace/registry, not to `library/...`.

## Running your own registry

The official `registry:2` image implements the _Registry HTTP API V2_. For a lab
or an internal cache:

```
docker container run -d --name registry \
  -p 5000:5000 \
  -v registry-data:/var/lib/registry \
  registry:2
```

```
docker tag alpine:3.20 localhost:5000/alpine:3.20
docker push localhost:5000/alpine:3.20
curl -s http://localhost:5000/v2/_catalog
# {"repositories":["alpine"]}
```

### TLS and authentication

Docker refuses `push`/`pull` over HTTP on any host other than `localhost`. For a
real registry you need **TLS**:

```
docker container run -d --name registry -p 443:5000 \
  -v "$(pwd)"/certs:/certs \
  -v registry-data:/var/lib/registry \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:2
```

And basic authentication with `htpasswd` (bcrypt):

```
docker run --rm --entrypoint htpasswd httpd:2 -Bbn admin secret > auth/htpasswd

docker container run -d --name registry -p 443:5000 \
  -v "$(pwd)"/auth:/auth -v "$(pwd)"/certs:/certs -v registry-data:/var/lib/registry \
  -e REGISTRY_AUTH=htpasswd \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:2
```

### Registry for development only (HTTP)

If you really need HTTP without TLS on an internal host, declare it as
**insecure** in each client's `/etc/docker/daemon.json`:

```json
{ "insecure-registries": ["internal-registry.lab:5000"] }
```

```
sudo systemctl restart docker
```

Avoid this outside a lab.

### Docker Hub _pull-through_ cache

`registry:2` can act as a read mirror/cache of Docker Hub, easing the _rate
limit_:

```
docker container run -d --name mirror -p 5000:5000 \
  -v mirror-data:/var/lib/registry \
  -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
  registry:2
```

On the clients, `/etc/docker/daemon.json`:

```json
{ "registry-mirrors": ["http://internal-mirror.lab:5000"] }
```

## Self-hosted registry alternatives

* **Harbor** — a full registry: RBAC, built-in scanning (Trivy), signing,
  replication, quotas, retention. It is the de facto standard for an internal
  company registry.
* **Zot** — a lightweight OCI registry, native _spec_ only, with optional
  scanning and UI.
* **GitLab / Gitea / Forgejo** — they ship an embedded registry alongside Git.

## Cleaning up space in the registry

Deleting a tag through the API marks the manifest as removable, but the _blobs_
only go away during **garbage collection**:

```
docker exec registry bin/registry garbage-collect /etc/docker/registry/config.yml
```

Enable `REGISTRY_STORAGE_DELETE_ENABLED=true` to allow deletion.
