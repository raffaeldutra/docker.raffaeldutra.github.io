# Distribuindo imagens: tags, digests, scan e assinatura

Publicar uma imagem é mais do que `docker push`. Este capítulo trata de como
**versionar** tags de forma sã, referenciar imagens de forma **imutável** por
digest, entender o **manifesto** multi-arquitetura, e as etapas de
**segurança da cadeia de suprimentos**: scan de vulnerabilidades, assinatura e
proveniência.

## Estratégia de tags

Tag é um ponteiro **mutável**: `minha-api:1.4.0` hoje pode apontar para um
manifesto diferente amanhã se alguém der outro `push`. Escolha uma convenção e
seja consistente.

Recomendado para aplicações:

```
minha-api:1.4.0          # versão exata (imutável na prática — nunca sobrescreva)
minha-api:1.4            # "última 1.4.x" — recebe patches
minha-api:1              # "última 1.x" — recebe minors compatíveis
minha-api:latest         # última release estável
minha-api:sha-9f3c1a2    # commit exato — ótimo para rastrear em produção
minha-api:2024-06-01     # data do build, se você versiona por data
```

Anti-padrões:

* **Só `latest`** — impossível saber o que está rodando, rollback vira
  adivinhação.
* **Reescrever uma tag de versão** (`1.4.0`) — quebra reprodutibilidade e cache
  de quem já baixou.
* Tags com significado ambíguo (`prod`, `stable`) sem um processo claro de
  promoção.

Aplicar várias tags no mesmo build:

```
docker build -t minha-api:1.4.0 -t minha-api:1.4 -t minha-api:latest .
docker push minha-api:1.4.0
docker push minha-api:1.4
docker push minha-api:latest
```

Cada `push` envia só as camadas que faltam no registry; as três tags apontam
para o mesmo manifesto, então o custo é baixo.

## Digest: referência imutável

O **digest** é o SHA-256 do manifesto da imagem. Diferente da tag, ele é
**imutável**: o mesmo digest sempre entrega exatamente os mesmos bytes.

```
docker pull nginx:1.27
docker inspect --format '{{index .RepoDigests 0}}' nginx:1.27
# nginx@sha256:e2b8b3...c1
```

Usar em produção e no `FROM` para builds reprodutíveis:

```dockerfile
FROM nginx:1.27@sha256:e2b8b3...c1
```

```
docker pull nginx@sha256:e2b8b3...c1
```

Ferramentas como Renovate/Dependabot conseguem atualizar essas linhas
`tag@sha256:...` automaticamente via PR, mantendo o benefício da imutabilidade
sem congelar a versão para sempre.

## Manifesto e imagens multi-arquitetura

O que uma tag aponta pode ser:

* um **manifesto de imagem** — uma arquitetura só; ou
* uma **lista de manifestos** (`manifest list` / `image index`) — um índice que
  mapeia `linux/amd64`, `linux/arm64`, etc. para o manifesto correto.

Inspecionar sem baixar:

```
docker manifest inspect --verbose nginx:1.27
docker buildx imagetools inspect nginx:1.27
```

Saída resumida do `imagetools`:

```
Name:      docker.io/library/nginx:1.27
MediaType: application/vnd.oci.image.index.v1+json

Manifests:
  Platform: linux/amd64   Digest: sha256:aaa...
  Platform: linux/arm64   Digest: sha256:bbb...
  Platform: linux/arm/v7  Digest: sha256:ccc...
```

Quando você faz `pull`, o Docker escolhe o manifesto que casa com a plataforma
do host. Force outra com `--platform linux/arm64`.

Montar uma lista de manifestos a partir de imagens por arquitetura já enviadas:

```
docker buildx imagetools create -t empresa/app:1.4.0 \
  empresa/app:1.4.0-amd64 \
  empresa/app:1.4.0-arm64
```

(Ou, mais simples, deixe o `docker buildx build --platform ... --push` fazer
isso — ver [BuildKit e buildx](../c2/buildkit.md).)

## Scan de vulnerabilidades

Analisa as camadas da imagem em busca de pacotes com CVE conhecido.

`docker scout` (embutido no Docker moderno):

```
docker scout quickview minha-api:1.4.0
docker scout cves minha-api:1.4.0
docker scout recommendations minha-api:1.4.0     # sugere imagem base melhor
```

**Trivy** (open source, muito usado em CI):

```
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image --severity HIGH,CRITICAL minha-api:1.4.0
```

**Grype**:

```
grype minha-api:1.4.0
```

Boas práticas:

* Rode o scan no **pipeline**, falhando o build em `CRITICAL` (com uma lista de
  exceções versionada para falsos positivos).
* Rescaneie imagens **já publicadas** periodicamente — CVEs novos aparecem para
  imagens que não mudaram.
* A melhor mitigação continua sendo **imagem base pequena e atualizada**
  (`-slim`, `distroless`, Alpine, Chainguard) e multi-stage para não carregar
  toolchain.

## SBOM — inventário de software

Um _SBOM_ (Software Bill of Materials) lista todos os pacotes e versões dentro
da imagem, em formato padrão (SPDX ou CycloneDX).

```
docker scout sbom --format spdx minha-api:1.4.0
syft minha-api:1.4.0 -o cyclonedx-json > sbom.json
```

Gerar já no build e anexar ao push:

```
docker buildx build --sbom=true --provenance=true -t empresa/app:1.4.0 --push .
```

## Assinatura de imagens

Prova **quem** publicou a imagem e que ela **não foi alterada** depois.

**cosign** (projeto Sigstore) é o padrão atual:

```
# assinatura sem chave (keyless), identidade via OIDC — comum em CI
cosign sign empresa/app:1.4.0

# ou com par de chaves
cosign generate-key-pair
cosign sign --key cosign.key empresa/app@sha256:...

# verificação
cosign verify --key cosign.pub empresa/app@sha256:...
```

Assine sempre o **digest**, não a tag (a tag pode mudar depois da assinatura).

Em clusters, um _admission controller_ (Kyverno, Sigstore Policy Controller,
Connaisseur) recusa imagens sem assinatura válida.

> O **Docker Content Trust** (`DOCKER_CONTENT_TRUST=1`, baseado em Notary v1) é
> a solução antiga. Novos projetos devem usar cosign / Notary v2.

## Promoção entre ambientes

Não recompile a imagem para cada ambiente — **promova o mesmo artefato** (mesmo
digest) de `dev` → `staging` → `prod`, mudando só a tag/o registry:

```
SRC=registry.example.com/app@sha256:9f3c1a...
docker buildx imagetools create --tag registry.example.com/app:prod "$SRC"
```

Assim o que passou nos testes é exatamente o que vai para produção.

## Copiar imagens entre registries sem daemon

**skopeo** e **crane** copiam imagens registry-a-registry sem `docker pull` /
`docker push`, preservando o digest e o manifesto multi-arch:

```
skopeo copy --all docker://nginx:1.27 docker://registry.interno/nginx:1.27
crane copy nginx:1.27 registry.interno/nginx:1.27
```

Úteis para _air-gap_, mirror inicial e migração entre provedores.

## Checklist de publicação

- [ ] Tag de versão semântica **e** tag `sha-<commit>`
- [ ] Build reprodutível (base fixada por digest, `.dockerignore` enxuto)
- [ ] Imagem multi-arch se o alvo tiver `arm64`
- [ ] Scan sem `CRITICAL` pendente (ou exceção justificada)
- [ ] SBOM e proveniência anexados
- [ ] Imagem (digest) assinada
- [ ] Produção referencia **digest**, não `latest`
