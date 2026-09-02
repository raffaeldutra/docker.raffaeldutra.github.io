# Criando imagem sem Dockerfile

Também é possível criar uma imagem sem Dockerfile, "congelando" o estado de um
container com `docker container commit`. É útil para experimentos rápidos, mas
**não é reproduzível** — para qualquer coisa séria, prefira um Dockerfile.

Entre em um container interativo:

```
docker container run --interactive --tty --name meu-ubuntu ubuntu /bin/bash
```

Dentro do container, faça as alterações que quiser — instalar pacotes, criar
arquivos, etc.:

```
apt-get update && apt-get install -y curl
```

Saia do container (`exit`). Ele fica parado, mas preservado. Agora gere uma
imagem a partir dele:

```
docker container commit \
  --message "adiciona curl" \
  --author "Rafael Dutra <raffaeldutra@gmail.com>" \
  meu-ubuntu workshop/ubuntu-curl:0.1
```

Confira que a imagem existe e rode um container a partir dela:

```
docker image ls workshop/ubuntu-curl
docker container run --rm workshop/ubuntu-curl:0.1 curl --version
```

> Repare no problema: quem olhar essa imagem não tem como saber o que foi feito
> nem refazer o processo. Com um Dockerfile, o histórico fica versionado e
> qualquer pessoa reconstrói a mesma imagem com `docker build`.
