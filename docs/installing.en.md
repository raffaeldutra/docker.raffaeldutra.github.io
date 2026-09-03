# Installing

To install the **Docker Engine** you need a 64-bit operating system.
Today there are basically three paths:

1. **Docker Desktop** — for Windows, macOS and also Linux. It installs the Docker
   Engine, the CLI, Docker Compose, Buildx and a graphical interface.
   Recommended for development machines.
2. **Docker Engine** — only the daemon and the CLI, installed directly on Linux
   from a package repository. Recommended for servers.
3. **Convenience script** (`get.docker.com`) — a shortcut for test environments.

!!! note "What about the virtual machine?"

    You no longer need a VM with a bridged network interface to follow the
    examples. Docker running natively on Linux, on WSL 2 (Windows) or on Docker
    Desktop (macOS) covers everything we will see here. If you do use a VM,
    remember to reach the services through its IP, not through `localhost`.

## Docker Desktop

- [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/) (requires WSL 2)
- [Docker Desktop for macOS](https://docs.docker.com/desktop/install/mac-install/) (Apple Silicon or Intel)
- [Docker Desktop for Linux](https://docs.docker.com/desktop/install/linux-install/)

After installing, verify with:

```bash
docker version
docker compose version
docker run hello-world
```

## Docker Engine on Linux (Ubuntu/Debian)

The procedure below follows the
[official documentation](https://docs.docker.com/engine/install/) and uses the
current repository key format (`/etc/apt/keyrings`), since `apt-key` has been
deprecated.

Remove old or conflicting packages, if any:

```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove -y $pkg
done
```

Set up the Docker repository:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings

# swap "ubuntu" for "debian" if that is your case
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
```

Install the Engine, the CLI, containerd and the Buildx and Compose plugins:

```bash
sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
```

Test:

```bash
sudo docker run hello-world
```

To run `docker` without `sudo`, add your user to the `docker` group and restart
the session:

```bash
sudo usermod -aG docker "$USER"
```

## Convenience script

Quick for disposable VMs and test environments. Not recommended for production.

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$USER"
```

Log out and log back in for the `docker` group to take effect.

## Official documentation

- [Installation overview](https://docs.docker.com/engine/install/)
- [Debian](https://docs.docker.com/engine/install/debian/)
- [Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- [CentOS / RHEL / Fedora](https://docs.docker.com/engine/install/rhel/)
- [Post-installation steps on Linux](https://docs.docker.com/engine/install/linux-postinstall/)
