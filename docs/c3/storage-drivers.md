# Storage drivers

Antes de iniciarmos com volumes, é realmente importante entedermos um pouco como funcionam as imagens, pois como foi dito em algum momento, um container só existe se houver uma imagem (em uma forma resumida).

Storage driver permitem que você crie dados em uma camada de escrita/gravação do seu container. O importante aqui neste momento é: *quando contianer parar, nenhum dado será persistifo -- leia-se gravado em disco*.

<a name="images-and-layers"></a>
### Imagens e camadas (layers)

Uma imagem Docker é criada em várias camadas e cada camada representa uma instrução do seu Dockerfile.

Vejamos o Dockerfile de exemplo abaixo:

```
FROM alpine:3.7

ADD /etc/motd /root/meu-motd

RUN mkdir -p /root/arquivos/leiame

CMD cat /root/meu-motd
```

Cada uma dessas linhas acima representam uma camada (layer). O importante aqui é entender que cada um desses comandos gera uma camada de diferença em relação a outra, ou seja, quando o comando **FROM** foi executado, ele gerou uma camada (layer) **X**. O comando **ADD** gerou uma outra camada com seus arquivos gerando uma camada **Y** e assim respectivamente para os outros comandos.

Essas camandas (layers) são empilhadas uma em cima ds outras e quando você inicia um novo container você simplesmente adiciona uma nova layer de gravação em cima de todas as outras que já existiam. Se por algum motivo você entrar neste container e modificar qualquer arquivo lá dentro, como provavelmente já fizemos em algum exercício anterior, todas as modificações ficam nesta nova camada que você criou ao executar seu container.

Vejamos esta imagem abaixo:

![https://docs.docker.com/storage/storagedriver/images/container-layers.jpg](images/container-layers.jpg)

> Imagem retirada da documentação oficial: [https://docs.docker.com/storage/storagedriver/images/container-layers.jpg](https://docs.docker.com/storage/storagedriver/images/container-layers.jpg)

<a name="containers-and-layers"></a>
### Containers e camadas (layers)

A principal e maior diferença entre um container e uma imagem é aquela camada de escrita que acabamos de mencionar acima (camada mais alta do diagrama), aquela onde você pode modificar qualquer coisa dentro de um container que é onde essas modificações serão gravadas.

Quando seu container for deletado essa camada de cima também é removida porém as camadas de baixo irão permanecer -- **por isso muito cuidado com os bancos de dados que irá levantar, ou ainda os dados que você não pode perder, pois usando o padrão de um container, você irá perder tudo** -- e aqui também reside uma beleza super interessante: você usar o reaproveitamento das camadas de baixo, veja a imagem abaixo:

![https://docs.docker.com/storage/storagedriver/images/sharing-layers.jpg](images/sharing-layers.jpg)
> Imagem retirada da documentação oficial: [https://docs.docker.com/storage/storagedriver/images/sharing-layers.jpg](https://docs.docker.com/storage/storagedriver/images/sharing-layers.jpg)

<a name="using-volumes"></a>
### Usando Volumes

Chegou a hora de brincar um pouco com volumes. Temos dois "modelos" de como utilizar containers aqui:

1. Mapeando diretório do nosso host
Aqui podemos escolher o que queremos do nosso host e mapearmo este diretório lá pra dentro do container. Exemplo:

```
docker container run --rm --volume /tmp:/root/tmp alpine /bin/sh -c 'echo Eu sou o container de nome $(hostname) > /root/tmp/meu-querido-container'
```

2. Mapeando dados de um container
