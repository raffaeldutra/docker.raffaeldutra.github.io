# Rodando containers

Verifique se está com docker corretamente funcionando, para isso execute o comando:

```
docker version
```

Sua saída deve ser algo parecido com:

```
rafael @ nazgul ~
└─ $ ▶ docker version
Client:
 Version:	17.12.0-ce
 API version:	1.35
 Go version:	go1.9.2
 Git commit:	c97c6d6
 Built:	Wed Dec 27 20:03:51 2017
 OS/Arch:	darwin/amd64

Server:
 Engine:
  Version:	17.12.0-ce
  API version:	1.35 (minimum version 1.12)
  Go version:	go1.9.2
  Git commit:	c97c6d6
  Built:	Wed Dec 27 20:12:29 2017
  OS/Arch:	linux/amd64
  Experimental:	true
```

## Comandos

Para verificar todos os comandos proporcionados por Docker, simplesmente digite:

```
docker
```

Importante: não esqueça que a linha de comando (CLI) é sua melhor amiga, caso não souber como um comando continua, ou seja, opções deste comando, simplesmente digite:

```
docker <comando> --help
```

## Rodando um container

```
docker container run alpine hostname
```

Você provavelmente teve uma resposta com letras e números, algo como: *7ed46aef747a*.
O que acabamos de ver aqui é o nome do container no momento que você o executou.

Vamos explicar por partes o que o comando acima faz:

* **docker container run** executa um container
* **alpine** é o nome da imagem que estamos Utilizando
* **hostname** é o comando que é executado dentro do container, por isso obtemos aquele conjunto de números e letras como resposta quando executamos o comando.

O que iremos ver agora é:

* Executando o comando acima algumas vezes, o resultado mudou?

## Utilizando imagens


Tudo que iremos executar em um container, vem de uma imagem e essa imagem pode ser uma que você mesmo criou ou uma imagem oficial, como foi o nosso caso acima como o Alpine.

> Apenas por conhecimento, Alpine é uma distribuição Linux super pequena que neste exato momento em sua versão 3.7.0 tem uma iso de 130MB e o mesmo vale para sua imagem para container, acredite, são 4.5MB de tamanho.

Execute o comando:

```
docker images
```

E o resultado deve ser algo assim:

```
rafael @ nazgul ~
└─ $ ▶ docker images
REPOSITORY                          TAG                    IMAGE ID            CREATED             SIZE
golang                              1.10.0-alpine3.7       85256d3905e2        7 weeks ago         376MB
maven                               3.5.2-jdk-8            31eec910d005        7 weeks ago         748MB
ubuntu                              16.04                  0458a4468cbc        2 months ago        112MB
ubuntu                              latest                 0458a4468cbc        2 months ago        112MB
raffaeldutra/gohugo                 latest                 7d6cac06f35c        2 months ago        1.11GB
golang                              latest                 3858fd70eed2        2 months ago        735MB
python                              2.7-alpine             0781c116c406        2 months ago        72.4MB
python                              3.6.4-alpine3.7        4b00a94b6f26        2 months ago        83.4MB
alpine                              3.4                    c7fc7faf8c28        3 months ago        4.82MB
alpine                              latest                 3fd9065eaf02        3 months ago        4.15MB
nginx                               latest                 3f8a4339aadd        3 months ago        108MB
jenkins                             latest                 5fc84ab0b7ad        3 months ago        809MB
jenkins                             2.60.3-alpine          2ad007d33253        5 months ago        223MB
maven                               3.5.2-jdk-8-alpine     293423a981a7        5 months ago        116MB
java                                openjdk-8-jdk-alpine   3fd9dd82815c        13 months ago       145MB
java                                8u102-jre              13f413e924a3        17 months ago       309MB
```

O que iremos ver agora é:

* Como procurar uma imagem?

```
docker search <imagem>
```

* Como remover uma imagem?

```
docker rmi alpine
```

> Aqui iremos obter um erro, pois temos aquele primeiro container -- docker container run alpine hostname -- em funcionamento e não é possível remover uma imagem onde há containers rodando.

* Como saber se a imagem que vou utilizar é uma imagem oficial?

```
docker search ubuntu
```

* Como baixamos uma imagem?

```
docker pull ubuntu
```

e para baixarmos uma versão específica, como Ubuntu 18.04? Para isso passe após o : a versão que quer utilizar

```
docker pull ubuntu:18.04
```
