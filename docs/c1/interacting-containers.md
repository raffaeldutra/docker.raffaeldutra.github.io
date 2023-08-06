# Interagindo com containers

Até agora fizemos alguns poucos exemplos, vamos entrar de fato em um container e trabalhar um pouco com ele.

Execute o seguinte comando:

```
docker run --interactive --tty --publish 45000:80 nginx /bin/bash
```

* Edite o arquivo **/usr/share/nginx/html/index.html** com o vim

O que aconteceu?

```
apt-get update && apt-get install vim --yes
```

Vamos acessar novamente o nosso web server na porta 45000 e percebemos que? Pois então, ao entrarmos dentro de um container, nós "perdemos" a execução de comando/entrypoint que a imagem foi destinada e para entedemos melhor, vamos ver como esta imagem do **nginx** foi criada. Para isso nós iremos acessar um repositório desta imagem no [Github](https://github.com/nginxinc/docker-nginx).

Docker Hub é um repositório aberto de imagens de onde todas imagens públicas, inclusive esta que estamos usando neste momento, estão sendo utilizadas. Você pode criar sua propria imagem e envia-lá sem problema algum para o Docker Hub, apenas atente para não deixar nenhum tipo de credential "boiando" por lá.

Vamos então [abrir o repositório do Nginx](https://hub.docker.com/_/nginx/) e ver de mais perto o que estamos conversando.

Ao abrirmos o arquivo de como é feita a imagem, percebemos na última que existe um comando chamado **CMD ["nginx", "-g", "daemon off;"]**. Este comando nos diz o seguinte em uma tradução livre "quando você rodar um novo container eu automaticamente vou invocar o comando nginx -g daemon para você". No nosso caso, acessamos o container de modo que estamos "brincando" com ele e este comando não foi executado pois ele somente é dispararado quando não passamos um novo parâmetro para ele, que foi o **/bin/bash**.

Dockerfile é este arquivo que estamos acessando neste momento e entendendo sua "planta baixa" de como funciona sua imagem e que também entraremos para falar somente dele.

Voltamos ao nosso problema inicial. Percebemos que ao entrar no container que está rodando Nginx ele não subiu o serviço e com isso nos vem a pergunta simples, como levantamos o serviço do nginx? simples, digite o comando **nginx** e acesse novamente o endereço http://localhost:45000


> Trabalhar com containers no início pode ser tão trabalhoso como de fato é :-)

Agora acesse novamente http://localhost:45000 e veja sua nova página.

Porém nós podemos fazer algo melhor sem "encostar" no container, algo interessante como *volumes* que veremos mais em breve.

Quando iniciamos um container novo, podemos instalar pacotes, editar/apagar/criar arquivos e outras coisas mais, porém temos um problema ao sair do container de forma tradicional pelo terminal pois o container automaticamente será parado assim que você digitar **exit** ou der **control d**. Para resolvermos este problema, podemos utiliazar a combinação de teclas como **control p q**, isso fará com que nosso container continue rodando normalmente e ele não irá parar.

Utilizando este conjunto de teclas, nos vem a seguinte pergunta: "E se eu quero retornar ao container, como faço?".

```
docker attach <id do container> ou <nome>
```

Excelente, tudo funcionando como esperado, mas e se eu quero apenas listar algum arquivo ou quem sabe visualizar e assim por diante? ou seja, quero apenas fazer algo breve no meu container?

```
docker exec <id do container> ou <nome> ls -la /usr/share/nginx/html
```

* Como faço para visualizar o log de um container?

```
docker logs <id do container> ou <nome>
```

* Como faço para visualizar status do meu container?

```
docker stats <id do container> ou <nome>
```

* Como faço para visualizar informações detalhadas de um container?

```
docker inspect <id do container> ou <nome>
```
