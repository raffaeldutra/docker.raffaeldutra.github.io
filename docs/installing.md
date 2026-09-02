# Instalando

Para instalar o **Docker Engine** você precisa de um sistema operacional 64 bits.
Hoje há basicamente três caminhos:

1. **Docker Desktop** — para Windows, macOS e também Linux. Instala o Docker
   Engine, a CLI, o Docker Compose, o Buildx e uma interface gráfica.
   Recomendado para máquinas de desenvolvimento.
2. **Docker Engine** — apenas o daemon e a CLI, instalado direto no Linux via
   repositório de pacotes. Recomendado para servidores.
3. **Script de conveniência** (`get.docker.com`) — atalho para ambientes de teste.

!!! note "E a máquina virtual?"

    Você não precisa mais de uma VM com interface em modo bridge para
    acompanhar os exemplos. Docker rodando nativo no Linux, no WSL 2 (Windows)
    ou no Docker Desktop (macOS) atende a tudo que veremos aqui. Se usar uma VM,
    lembre-se de acessar os serviços pelo IP dela, não por `localhost`.

## Docker Desktop

- [Docker Desktop para Windows](https://docs.docker.com/desktop/install/windows-install/) (requer WSL 2)
- [Docker Desktop para macOS](https://docs.docker.com/desktop/install/mac-install/) (Apple Silicon ou Intel)
- [Docker Desktop para Linux](https://docs.docker.com/desktop/install/linux-install/)

Depois de instalar, valide com:

```bash
docker version
docker compose version
docker run hello-world
```

## Docker Engine no Linux (Ubuntu/Debian)

O procedimento abaixo segue a
[documentação oficial](https://docs.docker.com/engine/install/) e usa o formato
atual de chaves de repositório (`/etc/apt/keyrings`), já que `apt-key` foi
descontinuado.

Remova pacotes antigos ou conflitantes, se existirem:

```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  sudo apt-get remove -y $pkg
done
```

Configure o repositório do Docker:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings

# troque "ubuntu" por "debian" se for o seu caso
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
```

Instale o Engine, a CLI, o containerd e os plugins do Buildx e do Compose:

```bash
sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin
```

Teste:

```bash
sudo docker run hello-world
```

Para rodar `docker` sem `sudo`, adicione seu usuário ao grupo `docker` e reinicie
a sessão:

```bash
sudo usermod -aG docker "$USER"
```

## Script de conveniência

Rápido para VMs descartáveis e ambientes de teste. Não recomendado para produção.

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$USER"
```

Faça logoff e login novamente para o grupo `docker` valer.

## Documentação oficial

- [Visão geral da instalação](https://docs.docker.com/engine/install/)
- [Debian](https://docs.docker.com/engine/install/debian/)
- [Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- [CentOS / RHEL / Fedora](https://docs.docker.com/engine/install/rhel/)
- [Passos pós-instalação no Linux](https://docs.docker.com/engine/install/linux-postinstall/)
