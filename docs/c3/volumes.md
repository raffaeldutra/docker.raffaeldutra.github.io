# Volumes

Volumes são totalmente gerenciados e criados por Docker e você pode criá-los com comandos, ou ainda, Docker pode criar este volume durante a criação do serviço.

.Comando para criar um volume

```shell
$ docker volume create <nome do volume>
```

.Exemplo de como criar um volume e chamá-lo de _dados_.

```shell
$ docker volume create dados
```

Para listar os volumes.

```shell
$ docker volume ls
```

Com a seguinte saída:

```shell
DRIVER              VOLUME NAME
local               dados
local               e8bf838bebbe3576313a6b37a26ab93d1fbb4865174710d9cb4d80366e85c674
```

Caso não seja específicado nenhum argumento para dar nome ao seu volume, um hash será gerado, conforme exemplo acima onde temos o hash com ínicio `e8bf83..`.

Para saber onde foi gerado este diretório com seu volume, é necessário inspecionar este volume.

Para inspecionar um volume utilize o comando _inspect_

```shell
$ docker volume inspect dados`
```

Com a seguinte saída:

```shell
[
    {
        "CreatedAt": "2019-01-30T14:00:29-02:00",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/dados/_data",
        "Name": "dados",
        "Options": {},
        "Scope": "local"
    }
]
```

Toda vez que for criado um volume, este volume é guardado em um diretório no Docker host e esta estrutura é que será enviada para dentro do container, mas a grande diferença aqui para `bind mounts` é que todo os dados criados neste volume são gerenciados pelo _Docker_.

Todos os volumes criados podem ser usados por vários containers ao mesmo tempo, ou ainda, quando não houver containers utilizando este volume, ele ficará em espera para quando for preciso utilizá-lo. O importante aqui é que seu volume sempre estará por sua espera para utilizar.

Volumes tem várias vantagens de utilizar do que `bind mounts`:

* Fáceis de fazer backups ou fazer migrações.
* É possível gerenciar volumes usando a _CLI_ do _Docker_ ou utilizando a API.
* Volumes funcionam em Linux e Windows.
* Volumes são mais seguros de compartilhar entre vários containers.
* Volumes contêm vários tipos de drivers para trabalhar localmente, provedores de _Cloud Computing_ (_AWS_, _Google Cloud_, _Azure_ e outros), para encriptar seu conteúdo ou adicionar funcionalidades.
* Volumes são geralmente uma escolha melhor do que persistir dados na camada de escrita do container, pois o volume não irá aumentar o tamanho do container que o está uando, e o conteúdo do volume é feito totalmente fora de um container.

Para utilizar volumes em linha de comando em Docker, você deve passar o parâmetro `-v`. Vejamos um exemplo:

```shell
$ docker run \
--rm \
--volume ubuntu-volume:/tmp ubuntu \
mkdir /tmp/novo-diretorio
```

Com este comando, foi criado um novo diretório em `/tmp/novo-diretorio` dentro do container, porém como estamos usando volumes, podemos achar este dado diretamente em nosso host onde persistimos o dado.

Verificando o caminho do volume

```shell
$ docker volume inspect ubuntu-volume
```

Com a seguinte saída.

```shell
[
    {
        "CreatedAt": "2019-01-30T19:40:29-02:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/ubuntu-volume/_data",
        "Name": "ubuntu-volume",
        "Options": null,
        "Scope": "local"
    }
]
```

Com o comando abaixo, verifique se o diretório foi criado.

```shell
$ sudo ls -la /var/lib/docker/volumes/ubuntu-volume/_data`
```

Vamos criar mais dois containers apontando para este mesmo volume, mas, em um destes dois containers, vamos criar alguns arquivos, e no outro container devemos poder listar estes novos arquivos.


```shell
$ docker run \
--interactive \
--tty \
--volume ubuntu-volume:/tmp ubuntu
```

Liste o conteúdo do diretório `/tmp`


```shell
root@a83a59e4555c:/# ls -la /tmp/
total 12
drwxrwxrwt 3 root root 4096 Jan 30 21:40 .
drwxr-xr-x 1 root root 4096 Jan 30 22:07 ..
drwxr-xr-x 2 root root 4096 Jan 30 21:40 novo-diretorio
```

Abra um novo terminal e rode um novo container, criando alguns arquivos dentro do diretório `tmp`.

Criando um novo container

```shell
$ docker run \
--interactive \
--tty \
--volume ubuntu-volume:/tmp ubuntu
```

Criando novos diretórios no diretório `/tmp`

```shell
cd /tmp
root@71df4a42bc32:/tmp# mkdir -p diretorio-a diretorio-b diretorio-c/subdiretorio-a
```

Liste no primeiro container o diretório `tmp`.

```shell
root@a83a59e4555c:/# ls -la /tmp/
total 24
drwxrwxrwt 6 root root 4096 Jan 30 22:13 .
drwxr-xr-x 1 root root 4096 Jan 30 22:07 ..
drwxr-xr-x 2 root root 4096 Jan 30 22:13 diretorio-a
drwxr-xr-x 2 root root 4096 Jan 30 22:13 diretorio-b
drwxr-xr-x 3 root root 4096 Jan 30 22:13 diretorio-c
drwxr-xr-x 2 root root 4096 Jan 30 21:40 novo-diretorio
```

## Bind Mounts

Bind mounts são menos eficientes que _volumes_, pois o diretório ou arquivo que está em sua máquina será apontada para dentro do container. Se estiver iniciando um novo projeto, prefira utilizar volumes no lugar de _bind mounts_.

Na versão _17.06_ do Docker foi introduzido um parâmetro chamado de *--mount* para containers. Recomenda-se o uso de *--mount* no lugar do parâmetro *-v* pois *--mount* é mais explicito e fácil de utilizar.

Assumindo que você tem um diretório chamado _teste_ e com um arquivo qualquer dentro deste diretório, vamos rodar o comando para montar estes objetos dentro do container.

Para utilizar *bind mounts* apenas passe este argumento quando chamar um novo container:

```shell
$ docker run -it \
--mount type=bind,source=/tmp/teste,target=/tmp/teste \
alpine \
ls -la /tmp/teste
```

Com a seguinte saída:

```shell
total 4
drwxr-xr-x    3 root     root            96 Feb 17 00:30 .
drwxrwxrwt    1 root     root          4096 Feb 17 00:30 ..
drwxr-xr-x    2 root     root            64 Feb 17 00:30 diretorio-a
```
