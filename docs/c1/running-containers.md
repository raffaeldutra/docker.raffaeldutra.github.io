# Rodando containers

Verifique se o Docker está funcionando corretamente:

```
docker version
```

A saída deve ser parecida com:

```
Client: Docker Engine - Community
 Version:           27.3.1
 API version:       1.47
 Go version:        go1.22.7
 Git commit:        ce12230
 Built:             Fri Sep 20 11:41:00 2024
 OS/Arch:           linux/amd64
 Context:           default

Server: Docker Engine - Community
 Engine:
  Version:          27.3.1
  API version:      1.47 (minimum version 1.24)
  Go version:       go1.22.7
  Git commit:       41ca978
  Built:            Fri Sep 20 11:41:00 2024
  OS/Arch:          linux/amd64
 containerd:
  Version:          1.7.22
 runc:
  Version:          1.1.14
```

## Comandos

Para ver todos os comandos oferecidos pelo Docker, digite:

```
docker
```

Importante: a linha de comando (CLI) é sua melhor amiga. Se não souber as opções
de um comando, use `--help`:

```
docker <comando> --help
```

Desde o Docker 1.13 os comandos são organizados por objeto
(`docker container ...`, `docker image ...`, `docker volume ...`). As formas
antigas e curtas (`docker run`, `docker ps`, `docker images`) continuam
funcionando como atalhos.

## Rodando um container

```
docker container run alpine hostname
```

Você recebeu de volta um identificador com letras e números, algo como
*7ed46aef747a*. É o hostname do container, que por padrão é o ID dele.

Explicando o comando por partes:

* **docker container run** cria e executa um container
* **alpine** é o nome da imagem utilizada
* **hostname** é o comando executado dentro do container — por isso a saída é
  aquele conjunto de letras e números

Experimente: rodando o comando algumas vezes, o resultado muda?

## Utilizando imagens

Tudo que roda em um container vem de uma imagem, seja uma imagem que você criou
ou uma imagem oficial, como a do Alpine acima.

> Alpine é uma distribuição Linux minúscula. A imagem oficial de container tem
> por volta de 7 MB.

Liste as imagens locais:

```
docker image ls
```

O resultado é parecido com:

```
REPOSITORY     TAG              IMAGE ID       CREATED        SIZE
golang         1.23-alpine      c7d7a3d1f0a1   2 weeks ago    248MB
maven          3.9-eclipse-temurin-21  9b2f7c4e5d6a  3 weeks ago  480MB
ubuntu         24.04            35a88802559d   4 weeks ago    78.1MB
python         3.12-alpine      f6a2b3c4d5e6   4 weeks ago    50.9MB
nginx          latest           195245f0c792   5 weeks ago    193MB
alpine         3.20             324bc02ae123   6 weeks ago    7.8MB
```

* Como procurar uma imagem?

```
docker search <imagem>
```

* Como remover uma imagem?

```
docker image rm alpine
```

> Aqui você pode obter um erro se ainda houver algum container (mesmo parado)
> baseado nessa imagem. Remova o container antes, ou use `-f` com cautela.

* Onde estão as imagens oficiais e mantidas por fornecedores?

Hoje o [Docker Hub](https://hub.docker.com) separa **Docker Official Images** e
**Verified Publisher**. Você pode filtrar por elas na busca do site.

* Como baixar uma imagem?

```
docker image pull ubuntu
```

Para uma versão específica, informe a tag após os `:`

```
docker image pull ubuntu:24.04
```

> Dica: prefira sempre uma tag explícita (`ubuntu:24.04`) a `latest`, para builds
> reproduzíveis. Para fixar de forma imutável, use o digest:
> `ubuntu@sha256:...`.
