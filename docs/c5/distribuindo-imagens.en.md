# Distributing images: tags, digests, scanning and signing

Publishing an image is more than `docker push`. This chapter is about how to
**version** tags sanely, reference images **immutably** by digest, understand the
multi-architecture **manifest**, and the steps of **supply chain security**:
vulnerability scanning, signing and provenance.

## Tag strategy

A tag is a **mutable** pointer: `my-api:1.4.0` today may point to a different
manifest tomorrow if someone runs another `push`. Pick a convention and be
consistent.

Recommended for applications:

```
my-api:1.4.0          # exact version (immutable in practice — never overwrite)
my-api:1.4            # "latest 1.4.x" — receives patches
my-api:1              # "latest 1.x" — receives compatible minors
my-api:latest         # latest stable release
my-api:sha-9f3c1a2    # exact commit — great for tracing in production
my-api:2024-06-01     # build date, if you version by date
```

Anti-patterns:

* **`latest` only** — impossible to know what is running, rollback becomes
  guesswork.
* **Rewriting a version tag** (`1.4.0`) — breaks reproducibility and the cache of
  whoever already pulled it.
* Tags with ambiguous meaning (`prod`, `stable`) without a clear promotion
  process.

Apply several tags on the same build:

```
docker build -t my-api:1.4.0 -t my-api:1.4 -t my-api:latest .
docker push my-api:1.4.0
docker push my-api:1.4
docker push my-api:latest
```

Each `push` sends only the layers missing in the registry; the three tags point
to the same manifest, so the cost is low.

## Digest: an immutable reference

The **digest** is the SHA-256 of the image manifest. Unlike the tag, it is
**immutable**: the same digest always delivers exactly the same bytes.

```
docker pull nginx:1.27
docker inspect --format '{{index .RepoDigests 0}}' nginx:1.27
# nginx@sha256:e2b8b3...c1
```

Use it in production and in `FROM` for reproducible builds:

```dockerfile
FROM nginx:1.27@sha256:e2b8b3...c1
```

```
docker pull nginx@sha256:e2b8b3...c1
```

Tools like Renovate/Dependabot can update these `tag@sha256:...` lines
automatically via PR, keeping the benefit of immutability without freezing the
version forever.

## Manifest and multi-architecture images

What a tag points to can be:

* an **image manifest** — a single architecture; or
* a **manifest list** (`manifest list` / `image index`) — an index that maps
  `linux/amd64`, `linux/arm64`, etc. to the correct manifest.

Inspect without downloading:

```
docker manifest inspect --verbose nginx:1.27
docker buildx imagetools inspect nginx:1.27
```

Summarized `imagetools` output:

```
Name:      docker.io/library/nginx:1.27
MediaType: application/vnd.oci.image.index.v1+json

Manifests:
  Platform: linux/amd64   Digest: sha256:aaa...
  Platform: linux/arm64   Digest: sha256:bbb...
  Platform: linux/arm/v7  Digest: sha256:ccc...
```

When you `pull`, Docker picks the manifest that matches the host's platform.
Force another with `--platform linux/arm64`.

Assemble a manifest list from already-pushed per-architecture images:

```
docker buildx imagetools create -t company/app:1.4.0 \
  company/app:1.4.0-amd64 \
  company/app:1.4.0-arm64
```

(Or, more simply, let `docker buildx build --platform ... --push` do it — see
[BuildKit and buildx](../c2/buildkit.md).)

## Vulnerability scanning

It analyzes the image layers looking for packages with a known CVE.

`docker scout` (built into modern Docker):

```
docker scout quickview my-api:1.4.0
docker scout cves my-api:1.4.0
docker scout recommendations my-api:1.4.0     # suggests a better base image
```

**Trivy** (open source, widely used in CI):

```
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image --severity HIGH,CRITICAL my-api:1.4.0
```

**Grype**:

```
grype my-api:1.4.0
```

Best practices:

* Run the scan in the **pipeline**, failing the build on `CRITICAL` (with a
  versioned exception list for false positives).
* Rescan **already published** images periodically — new CVEs appear for images
  that have not changed.
* The best mitigation is still a **small, up-to-date base image** (`-slim`,
  `distroless`, Alpine, Chainguard) and multi-stage so you do not carry the
  toolchain.

## SBOM — software inventory

An _SBOM_ (Software Bill of Materials) lists every package and version inside the
image, in a standard format (SPDX or CycloneDX).

```
docker scout sbom --format spdx my-api:1.4.0
syft my-api:1.4.0 -o cyclonedx-json > sbom.json
```

Generate it at build time and attach it to the push:

```
docker buildx build --sbom=true --provenance=true -t company/app:1.4.0 --push .
```

## Image signing

It proves **who** published the image and that it **was not altered** afterwards.

**cosign** (the Sigstore project) is the current standard:

```
# keyless signing, identity via OIDC — common in CI
cosign sign company/app:1.4.0

# or with a key pair
cosign generate-key-pair
cosign sign --key cosign.key company/app@sha256:...

# verification
cosign verify --key cosign.pub company/app@sha256:...
```

Always sign the **digest**, not the tag (the tag can change after the signature).

In clusters, an _admission controller_ (Kyverno, Sigstore Policy Controller,
Connaisseur) rejects images without a valid signature.

> **Docker Content Trust** (`DOCKER_CONTENT_TRUST=1`, based on Notary v1) is the
> old solution. New projects should use cosign / Notary v2.

## Promotion between environments

Do not rebuild the image for each environment — **promote the same artifact**
(same digest) from `dev` → `staging` → `prod`, changing only the tag/registry:

```
SRC=registry.example.com/app@sha256:9f3c1a...
docker buildx imagetools create --tag registry.example.com/app:prod "$SRC"
```

This way what passed the tests is exactly what goes to production.

## Copying images between registries without a daemon

**skopeo** and **crane** copy images registry-to-registry without `docker pull` /
`docker push`, preserving the digest and the multi-arch manifest:

```
skopeo copy --all docker://nginx:1.27 docker://registry.internal/nginx:1.27
crane copy nginx:1.27 registry.internal/nginx:1.27
```

Useful for _air-gap_, initial mirroring and migration between providers.

## Publishing checklist

- [ ] Semantic version tag **and** `sha-<commit>` tag
- [ ] Reproducible build (base pinned by digest, lean `.dockerignore`)
- [ ] Multi-arch image if the target has `arm64`
- [ ] Scan with no pending `CRITICAL` (or a justified exception)
- [ ] SBOM and provenance attached
- [ ] Image (digest) signed
- [ ] Production references the **digest**, not `latest`
