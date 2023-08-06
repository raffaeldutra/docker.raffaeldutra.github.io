# Docker Compose

Docker Compose é a maneira de declararmos vários containers para nossa aplicação e ele é "invocado" pelo comando **docker-compose**. Então com isso imaginamos que temos uma aplicação escrita em PHP que utiliza banco de dados MySQL para guardarmos nossos dados.

Exemplos:

1. temos uma aplicação escrita em PHP
2. temos um banco de dados em MySQL

ou ainda, o tão famoso Wordpress:

1. temos o Wordpress
2. temos o banco de dados do Wordpress

Não importa aqui o exemplo, o que importa é a ideia de termos "coisas separadas, vamos simplificar a ideia nisso apenas.

Docker Compose é parecido com o Dockerfile que vimos antes, mas ele é escrito em um formato YAML (YAML Ain't Markup Language) para que possamos declarar nossa aplicação e tudo mais que é utiliza por ela, como volumes, portas, dependência de um outro container, imagem, variáveis de ambiente e etc, ou sejam nada quase diferente do que o Dockerfile neste ponto, porém apenas parece, ele faz muito mais coisa.

Vejamos um exemplo de Docker Compose para termos uma ideia.

```
1. version: '3.3'
2.
3. services:
4.   db:
5.     image: mysql:5.7
6.     volumes:
7.       - db_data:/var/lib/mysql
8.     restart: always
9.     environment:
10.       MYSQL_ROOT_PASSWORD: somewordpress
11.       MYSQL_DATABASE: wordpress
12.       MYSQL_USER: wordpress
13.       MYSQL_PASSWORD: wordpress
14.
15.   wordpress:
16.     depends_on:
17.       - db
18.     image: wordpress:latest
19.     ports:
20.       - "8000:80"
21.     restart: always
22.     environment:
23.       WORDPRESS_DB_HOST: db:3306
24.       WORDPRESS_DB_USER: wordpress
25.       WORDPRESS_DB_PASSWORD: wordpress
26. volumes:
27.    db_data:
```

Isso mesmo, linha por linha eu vou explicar:

Linha 1: versão utilizada do Docker Compose, e isso vai variar conforme a versão que você tem instalada na sua máquina.

Linha 3: estamos dizendo que estamos iniciando um serviço e tudo abaixo dessa linha faz parte deste serviço.

Linha 4: nome que estamos dando para este container, no nosso caso é um simples "db", mas poderia ser chamado de banco, database e etc.

Linha 5: imagem utilizada do mysql com sua respectiva versão.

Linha 6 e 7: volume que é utilizado para nosso banco de dados, veja que este valor está ligado diretamente com a definição das linhas 26 e 27.

Linha 8: se algo acontecer com o container, ele por default irá reiniciar sempre.

Linha 9 até linha 13: são variáveis de ambiente que serão utilizadas para acessar o container que roda nosso banco de doados

Linha 15: nome do nosso container, que mais uma vez poderia ser o nome de qualquer coisa.

Linha 16: dizemos que para levantar este container, precisamos do container chamado **db** antes em funcionamento.

Linha 18: imagem utilizada do Wordpress com sua respectiva versão, no caso **latest** significa *última*.

Linha 19 e 20: definição de portas, ou seja, queremos acessar na porta 8000 da nossa máquina a porta 80 que roda lá dentro do container.

Linha 21: se algo acontecer com o container, ele por default irá reiniciar sempre.

Linha 22 até 25:ão variáveis de ambiente que serão utilizadas para acessar o container que roda nosso Wordpress.

Linha 26 e 27: definição do volume que usamos nas linhas 6 e 7.
