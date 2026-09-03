# Segurança de containers

Container **não é máquina virtual**. O isolamento vem de recursos do kernel Linux
(_namespaces_, _cgroups_, _capabilities_, seccomp, LSM) e o kernel é
**compartilhado** com o host. Este capítulo mostra como reduzir o que um
container pode fazer se for comprometido.

## O modelo de isolamento

| Mecanismo | O que isola / limita |
|---|---|
| **namespaces** | PID, rede, montagens, usuários, IPC, hostname — o container "não vê" o resto |
| **cgroups** | quanto de CPU, memória, I/O e nº de processos ele pode consumir |
| **capabilities** | quais operações privilegiadas o root do container pode fazer |
| **seccomp** | quais _syscalls_ o processo pode chamar |
| **LSM** (AppArmor / SELinux) | perfil de acesso a arquivos, rede, ptrace |
| **user namespace** | mapeia root do container para um UID não privilegiado no host |

Se qualquer um desses for afrouxado (`--privileged`, `--cap-add=SYS_ADMIN`,
`--security-opt seccomp=unconfined`, montar `/var/run/docker.sock`), a barreira
container↔host fica muito mais fina.

## Não rode como root dentro do container

Por padrão o processo do container roda como **root (UID 0)**. Se ele escapar de
um bind mount mal configurado ou de uma vulnerabilidade do runtime, é root no
host.

No Dockerfile:

```dockerfile
FROM node:20-slim
# Debian/Node images already ship a "node" user (UID 1000)
WORKDIR /app
COPY --chown=node:node . .
USER node
CMD ["node", "server.js"]
```

Criando o usuário quando a imagem não tem um:

```dockerfile
RUN groupadd --system --gid 1000 app \
 && useradd  --system --uid 1000 --gid app app
USER 1000
```

> Use o **UID numérico** (`USER 1000`) além do nome. Orquestradores que aplicam
> `runAsNonRoot` verificam o número, não o nome.

Forçar em tempo de execução (mesmo que a imagem insista em root):

```
docker container run --user 1000:1000 my-img
```

## Sistema de arquivos somente leitura

A maioria das aplicações não precisa escrever no próprio filesystem:

```
docker container run \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=64m \
  --tmpfs /run:rw,noexec,nosuid,size=16m \
  my-img
```

`--read-only` torna o rootfs imutável; os poucos diretórios graváveis viram
`tmpfs` (RAM, somem no fim). Dados que precisam persistir vão para um volume
nomeado explícito.

## Descarte capabilities

O root do container já começa **sem** várias capabilities, mas ainda tem um
conjunto perigoso (`NET_RAW`, `SETUID`, `CHOWN`, `MKNOD`...). Boa prática: dropar
tudo e readicionar só o necessário.

```
docker container run \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \    # only if you need to listen on a port < 1024
  my-img
```

Um servidor web que roda como não-root e escuta na 8080 normalmente funciona com
`--cap-drop ALL` e **nenhuma** capability adicionada.

## `no-new-privileges`

Impede que o processo ganhe privilégios via binários `setuid`/`setgid` (ex.:
`sudo`, `ping` antigo):

```
docker container run --security-opt no-new-privileges:true my-img
```

Deveria estar em praticamente todo container.

## Limites de recursos (cgroups)

Um container sem limite pode derrubar o host inteiro (OOM, CPU 100%, _fork
bomb_):

```
docker container run \
  --memory 512m --memory-swap 512m \   # no extra swap
  --cpus 1.5 \
  --pids-limit 200 \
  --ulimit nofile=1024:2048 \
  my-img
```

* `--memory` — teto de RAM; ao estourar, o processo leva OOM kill.
* `--memory-swap` igual a `--memory` desativa swap para aquele container.
* `--cpus` — frações de CPU (`1.5` = um core e meio).
* `--pids-limit` — nº máximo de processos/threads; barra _fork bombs_.
* `--ulimit nofile` — limite de descritores de arquivo.

## seccomp e AppArmor

O Docker já aplica um **perfil seccomp padrão** que bloqueia ~44 syscalls
perigosas (`mount`, `reboot`, `kexec_load`, `ptrace` em alguns modos...) e um
perfil **AppArmor** (`docker-default`). Não desligue:

```
# do NOT do this in production:
docker run --security-opt seccomp=unconfined ...
docker run --security-opt apparmor=unconfined ...
```

Perfil seccomp customizado (mais restritivo), quando você sabe exatamente as
syscalls que a app usa:

```
docker run --security-opt seccomp=/path/my-profile.json my-img
```

## O que nunca fazer (a não ser que saiba o porquê)

`--privileged`
: Desliga quase todas as proteções: todas as capabilities, acesso a
  `/dev`, seccomp/AppArmor afrouxados. Só para casos como Docp-in-Docker
  controlado. Praticamente equivale a dar root no host.

Montar `-v /var/run/docker.sock:/var/run/docker.sock`
: Dá ao container controle total do daemon Docker → controle total do host
  (basta subir outro container com `-v /:/host`). Se precisa disso (CI, agente),
  isole numa VM ou use um proxy de socket com allow-list
  (`tecnativa/docker-socket-proxy`).

`-v /:/host`, montar `/etc`, `/proc`, `/sys` do host
: Exposição direta do host. Monte apenas o path mínimo e com `:ro`.

`--pid=host`, `--network=host`, `--ipc=host`
: Removem o namespace correspondente. `--network=host` tem usos legítimos de
  performance; os outros raramente.

## Isolamento reforçado: runtimes alternativos

Quando containers rodam código não confiável (multi-tenant, CI de terceiros):

* **gVisor** (`runsc`) — kernel de espaço de usuário que intercepta syscalls;
  reduz muito a superfície do kernel do host.
* **Kata Containers** — cada container (ou pod) roda dentro de uma microVM leve,
  com kernel próprio.

```
docker run --runtime=runsc my-img          # after installing gVisor
```

## Segredos

* **Nunca** ponha segredo em `ENV` no Dockerfile nem em `--build-arg` — fica em
  `docker history` e nas camadas.
* Build: `RUN --mount=type=secret` (ver [BuildKit](../c2/buildkit.md)).
* Runtime: injete por arquivo montado (`--secret` no Compose/Swarm, `tmpfs`), ou
  por um gerenciador (Vault, AWS Secrets Manager, SOPS). Variável de ambiente é
  aceitável, mas vaza fácil em logs, `docker inspect` e _crash dumps_.

```
# Swarm / Compose
echo "s3cr3t" | docker secret create db_password -
docker service create --secret db_password my-img
# the app reads /run/secrets/db_password
```

## Superfície do host (Docker daemon)

* O grupo `docker` **é equivalente a root**. Só coloque nele quem já é
  administrador da máquina. Considere o **modo rootless** do Docker.
* Habilite _user namespace remapping_ no daemon: `"userns-remap": "default"` em
  `/etc/docker/daemon.json` — root do container vira um UID alto e sem
  privilégio no host.
* Mantenha Docker Engine, `containerd` e `runc` atualizados (escapes de
  container quase sempre são CVE em `runc`/kernel).
* Habilite _live restore_ e logging com rotação; audite com `auditd` regras em
  `/usr/bin/dockerd` e `/var/lib/docker`.

## Checklist de execução

- [ ] `USER` não-root (UID numérico) na imagem
- [ ] `--read-only` + `--tmpfs` para os diretórios graváveis
- [ ] `--cap-drop ALL` e readicionar só o necessário
- [ ] `--security-opt no-new-privileges:true`
- [ ] `--memory`, `--cpus`, `--pids-limit` definidos
- [ ] seccomp e AppArmor **no perfil padrão** (não `unconfined`)
- [ ] sem `--privileged`, sem `docker.sock` montado
- [ ] segredos por arquivo/gerenciador, não em `ENV`/`ARG`
- [ ] imagem escaneada e (idealmente) assinada — ver [Distribuindo imagens](../c5/distribuindo-imagens.md)
