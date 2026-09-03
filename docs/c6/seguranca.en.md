# Container security

A container **is not a virtual machine**. The isolation comes from Linux kernel
features (_namespaces_, _cgroups_, _capabilities_, seccomp, LSM) and the kernel
is **shared** with the host. This chapter shows how to reduce what a container
can do if it is compromised.

## The isolation model

| Mechanism | What it isolates / limits |
|---|---|
| **namespaces** | PID, network, mounts, users, IPC, hostname — the container "does not see" the rest |
| **cgroups** | how much CPU, memory, I/O and number of processes it can consume |
| **capabilities** | which privileged operations the container's root can perform |
| **seccomp** | which _syscalls_ the process can call |
| **LSM** (AppArmor / SELinux) | an access profile for files, network, ptrace |
| **user namespace** | maps the container's root to an unprivileged UID on the host |

If any of these is loosened (`--privileged`, `--cap-add=SYS_ADMIN`,
`--security-opt seccomp=unconfined`, mounting `/var/run/docker.sock`), the
container↔host barrier gets much thinner.

## Do not run as root inside the container

By default the container process runs as **root (UID 0)**. If it escapes through
a misconfigured bind mount or a runtime vulnerability, it is root on the host.

In the Dockerfile:

```dockerfile
FROM node:20-slim
# Debian/Node images already ship a "node" user (UID 1000)
WORKDIR /app
COPY --chown=node:node . .
USER node
CMD ["node", "server.js"]
```

Creating the user when the image does not have one:

```dockerfile
RUN groupadd --system --gid 1000 app \
 && useradd  --system --uid 1000 --gid app app
USER 1000
```

> Use the **numeric UID** (`USER 1000`) in addition to the name. Orchestrators
> that enforce `runAsNonRoot` check the number, not the name.

Force it at run time (even if the image insists on root):

```
docker container run --user 1000:1000 my-img
```

## Read-only filesystem

Most applications do not need to write to their own filesystem:

```
docker container run \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=64m \
  --tmpfs /run:rw,noexec,nosuid,size=16m \
  my-img
```

`--read-only` makes the rootfs immutable; the few writable directories become
`tmpfs` (RAM, gone at the end). Data that must persist goes to an explicit named
volume.

## Drop capabilities

The container's root already starts **without** several capabilities, but it
still has a dangerous set (`NET_RAW`, `SETUID`, `CHOWN`, `MKNOD`...). Best
practice: drop everything and re-add only what is needed.

```
docker container run \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \    # only if you need to listen on a port < 1024
  my-img
```

A web server that runs as non-root and listens on 8080 normally works with
`--cap-drop ALL` and **no** capability added.

## `no-new-privileges`

Prevents the process from gaining privileges through `setuid`/`setgid` binaries
(e.g. `sudo`, old `ping`):

```
docker container run --security-opt no-new-privileges:true my-img
```

It should be on practically every container.

## Resource limits (cgroups)

A container with no limit can bring down the whole host (OOM, CPU 100%, _fork
bomb_):

```
docker container run \
  --memory 512m --memory-swap 512m \   # no extra swap
  --cpus 1.5 \
  --pids-limit 200 \
  --ulimit nofile=1024:2048 \
  my-img
```

* `--memory` — RAM ceiling; when it is exceeded, the process gets an OOM kill.
* `--memory-swap` equal to `--memory` disables swap for that container.
* `--cpus` — CPU fractions (`1.5` = one and a half cores).
* `--pids-limit` — the maximum number of processes/threads; blocks _fork bombs_.
* `--ulimit nofile` — the file descriptor limit.

## seccomp and AppArmor

Docker already applies a **default seccomp profile** that blocks ~44 dangerous
syscalls (`mount`, `reboot`, `kexec_load`, `ptrace` in some modes...) and an
**AppArmor** profile (`docker-default`). Do not turn them off:

```
# do NOT do this in production:
docker run --security-opt seccomp=unconfined ...
docker run --security-opt apparmor=unconfined ...
```

A custom seccomp profile (more restrictive), when you know exactly which syscalls
the app uses:

```
docker run --security-opt seccomp=/path/my-profile.json my-img
```

## What never to do (unless you know why)

`--privileged`
: Turns off almost every protection: all capabilities, access to `/dev`,
  seccomp/AppArmor loosened. Only for cases like controlled Docker-in-Docker.
  It is practically equivalent to giving root on the host.

Mounting `-v /var/run/docker.sock:/var/run/docker.sock`
: Gives the container full control of the Docker daemon → full control of the
  host (just start another container with `-v /:/host`). If you need this (CI,
  an agent), isolate it in a VM or use a socket proxy with an allow-list
  (`tecnativa/docker-socket-proxy`).

`-v /:/host`, mounting the host's `/etc`, `/proc`, `/sys`
: Direct exposure of the host. Mount only the minimal path, and with `:ro`.

`--pid=host`, `--network=host`, `--ipc=host`
: They remove the corresponding namespace. `--network=host` has legitimate
  performance uses; the others rarely do.

## Hardened isolation: alternative runtimes

When containers run untrusted code (multi-tenant, third-party CI):

* **gVisor** (`runsc`) — a user-space kernel that intercepts syscalls; it greatly
  reduces the host kernel's surface.
* **Kata Containers** — each container (or pod) runs inside a lightweight
  microVM, with its own kernel.

```
docker run --runtime=runsc my-img          # after installing gVisor
```

## Secrets

* **Never** put a secret in `ENV` in the Dockerfile nor in `--build-arg` — it
  stays in `docker history` and in the layers.
* Build: `RUN --mount=type=secret` (see [BuildKit](../c2/buildkit.md)).
* Runtime: inject it through a mounted file (`--secret` in Compose/Swarm,
  `tmpfs`), or through a manager (Vault, AWS Secrets Manager, SOPS). An
  environment variable is acceptable, but it leaks easily in logs,
  `docker inspect` and _crash dumps_.

```
# Swarm / Compose
echo "s3cr3t" | docker secret create db_password -
docker service create --secret db_password my-img
# the app reads /run/secrets/db_password
```

## Host surface (Docker daemon)

* The `docker` group **is equivalent to root**. Only put in it people who are
  already administrators of the machine. Consider Docker's **rootless mode**.
* Enable _user namespace remapping_ on the daemon: `"userns-remap": "default"` in
  `/etc/docker/daemon.json` — the container's root becomes a high, unprivileged
  UID on the host.
* Keep Docker Engine, `containerd` and `runc` updated (container escapes are
  almost always a CVE in `runc`/kernel).
* Enable _live restore_ and logging with rotation; audit with `auditd` rules on
  `/usr/bin/dockerd` and `/var/lib/docker`.

## Runtime checklist

- [ ] Non-root `USER` (numeric UID) in the image
- [ ] `--read-only` + `--tmpfs` for the writable directories
- [ ] `--cap-drop ALL` and re-add only what is needed
- [ ] `--security-opt no-new-privileges:true`
- [ ] `--memory`, `--cpus`, `--pids-limit` defined
- [ ] seccomp and AppArmor **on the default profile** (not `unconfined`)
- [ ] no `--privileged`, no `docker.sock` mounted
- [ ] secrets through a file/manager, not in `ENV`/`ARG`
- [ ] image scanned and (ideally) signed — see [Distributing images](../c5/distribuindo-imagens.md)
