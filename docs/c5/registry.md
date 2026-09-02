# Registries e Docker Hub

Um **registry** é o serviço que guarda e distribui imagens de container. Quando
você faz `docker pull nginx`, o Docker baixa do Docker Hub; quando faz
`docker push`, envia para o registry indicado no nome da imagem. Este capítulo
cobre como os nomes de imagem funcionam, autenticação, e como rodar seu próprio
registry.

## Anatomia de um nome de imagem

```
registry.example.com:5000/time-a/minha-api:1.4.0
└──────────┬─────────────┘ └──┬──┘ └───┬───┘ └─┬─┘
        registry          namespace  repo    tag
```

* **registry** — host (e porta). Se omitido, o Docker assume
  `docker.io` (Docker Hub).
* **namespace/repo** — organização/usuário e nome do repositório. No Docker Hub,
  imagens sem namespace (ex.: `nginx`) são as _Docker Official Images_, que na
  verdade moram em `docker.io/library/nginx`.
* **tag** — rótulo mutável de uma versão. Se omitida, o Docker usa `latest`
  (que não tem nada de especial — é só a tag padrão).

Exemplos equivalentes:

```
docker pull nginx
docker pull nginx:latest
docker pull docker.io/library/nginx:latest
```

## Registries mais comuns

| Registry | Host | Observações |
|---|---|---|
| Docker Hub | `docker.io` | padrão; tem _rate limit_ para anônimos e conta free |
| GitHub Container Registry | `ghcr.io` | integrado a repositórios/Actions do GitHub |
| GitLab Container Registry | `registry.gitlab.com` | um registry por projeto GitLab |
| Amazon ECR | `<conta>.dkr.ecr.<região>.amazonaws.com` | login via `aws ecr get-login-password` |
| Google Artifact Registry | `<região>-docker.pkg.dev` | login via `gcloud auth configure-docker` |
| Azure ACR | `<nome>.azurecr.io` | `az acr login` |
| Quay | `quay.io` | scanner de vulnerabilidade embutido |

!!! note "Rate limit do Docker Hub"

    Para usuários anônimos o Docker Hub limita o número de _pulls_ por janela de
    tempo (por IP). Em CI isso estoura fácil. Soluções: autenticar
    (`docker login`), usar um _mirror_ / cache _pull-through_, ou mover as
    imagens base para outro registry.

## Autenticação

```
docker login                          # Docker Hub
docker login ghcr.io                   # outro registry
docker login registry.example.com:5000
```

As credenciais ficam em `~/.docker/config.json`. Por padrão, em texto
(base64, **não** criptografado). Para produção/CI, use um _credential helper_
(`docker-credential-pass`, `docker-credential-ecr-login`, etc.) que guarda o
segredo no keychain do SO ou obtém tokens de curta duração.

Em CI, prefira **token de acesso** (revogável, com escopo) em vez da senha da
conta:

```
echo "$REGISTRY_TOKEN" | docker login ghcr.io -u "$USUARIO" --password-stdin
```

Sair:

```
docker logout ghcr.io
```

## `docker pull`, `docker push`

```
docker pull redis:7.4
docker image tag minha-api:1.4.0 registry.example.com:5000/time-a/minha-api:1.4.0
docker push registry.example.com:5000/time-a/minha-api:1.4.0
```

Você só consegue dar `push` para um repositório onde tem permissão de escrita —
por isso o nome precisa apontar para o **seu** namespace/registry, não para
`library/...`.

## Rodando seu próprio registry

A imagem oficial `registry:2` implementa a _Registry HTTP API V2_. Para um
laboratório ou um cache interno:

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

### TLS e autenticação

O Docker recusa `push`/`pull` por HTTP em qualquer host que não seja
`localhost`. Para um registry real você precisa de **TLS**:

```
docker container run -d --name registry -p 443:5000 \
  -v "$(pwd)"/certs:/certs \
  -v registry-data:/var/lib/registry \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:2
```

E autenticação básica com `htpasswd` (bcrypt):

```
docker run --rm --entrypoint htpasswd httpd:2 -Bbn admin senha > auth/htpasswd

docker container run -d --name registry -p 443:5000 \
  -v "$(pwd)"/auth:/auth -v "$(pwd)"/certs:/certs -v registry-data:/var/lib/registry \
  -e REGISTRY_AUTH=htpasswd \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
  -e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  registry:2
```

### Registry só para desenvolvimento (HTTP)

Se realmente precisar de HTTP sem TLS num host interno, declare-o como
**inseguro** em `/etc/docker/daemon.json` de cada cliente:

```json
{ "insecure-registries": ["registro-interno.lab:5000"] }
```

```
sudo systemctl restart docker
```

Evite isso fora de um laboratório.

### Cache _pull-through_ do Docker Hub

O `registry:2` pode funcionar como espelho/cache de leitura do Docker Hub,
aliviando o _rate limit_:

```
docker container run -d --name mirror -p 5000:5000 \
  -v mirror-data:/var/lib/registry \
  -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
  registry:2
```

Nos clientes, `/etc/docker/daemon.json`:

```json
{ "registry-mirrors": ["http://mirror-interno.lab:5000"] }
```

## Alternativas de registry auto-hospedado

* **Harbor** — registry completo: RBAC, scan (Trivy) embutido, assinatura,
  replicação, quotas, retenção. É o padrão de fato para registry interno de
  empresa.
* **Zot** — registry OCI leve, só _spec_ nativo, com scan e UI opcionais.
* **GitLab / Gitea / Forgejo** — trazem um registry embutido junto do Git.

## Limpando espaço no registry

Deletar uma tag pela API marca o manifesto como removível, mas os _blobs_ só
somem no **garbage collection**:

```
docker exec registry bin/registry garbage-collect /etc/docker/registry/config.yml
```

Habilite `REGISTRY_STORAGE_DELETE_ENABLED=true` para permitir deleção.
