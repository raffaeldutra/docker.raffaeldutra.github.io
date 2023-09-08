<p align="center"><img src="https://www.shareicon.net/data/128x128/2015/10/06/112721_development_512x512.png"></p>

<p align="center">
<a href="https://img.shields.io/badge/License-GPL%20v3-blue.svg"><img src="https://img.shields.io/badge/License-GPL%20v3-blue.svg" alt="License"></a>
</p>

# Sumário

- [Sumário](#sumário)
  - [TL;DR (Too Long, Didn't Read)](#tldr-too-long-didnt-read)
  - [Como obter Docker?](#como-obter-docker)
  - [Criando novo site](#criando-novo-site)
  - [Rodando servidor](#rodando-servidor)

## TL;DR (Too Long, Didn't Read)

Baixe Docker com o comando mágico.

```bash
curl -fsSL https://get.docker.com/ | sh
```

<a name="como-obter-docker"></a>
## Como obter Docker?

- [Link para documentação oficial](https://docs.docker.com/install/)
    - [Instalando em Windows](https://docs.docker.com/docker-for-windows/install/)
    - [Instalando em Debian](https://docs.docker.com/install/linux/docker-ce/debian/)
    - [Instalando em Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
    - [Instalando em MacOS](https://docs.docker.com/docker-for-mac/install/)


<a name="criando-novo-site"></a>
## Criando novo site

```bash
docker container run \
--rm \
-it \
-v $(pwd):/docs \
squidfunk/mkdocs-material:9 new .
```

<a name="rodando-servidor"></a>
## Rodando servidor

```bash
docker container run \
--rm \
-it \
-p 8000:8001 \
-v $(pwd):/docs \
squidfunk/mkdocs-material:9
```
