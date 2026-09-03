# Docker Compose

Docker Compose é a forma de declarar e executar uma aplicação com vários
containers a partir de um único arquivo. Ele é invocado pelo subcomando
**`docker compose`** (com espaço). O antigo binário `docker-compose` (com hífen,
o Compose v1) está descontinuado desde 2023 — se você ainda o utiliza, migre
para o plugin v2, que já vem com o Docker Desktop e com o pacote
`docker-compose-plugin` no Linux.

A ideia é sempre a mesma: temos "coisas separadas" que compõem a aplicação e
queremos descrevê-las de forma declarativa. Por exemplo:

1. uma aplicação escrita em PHP
2. um banco de dados MySQL

ou o clássico WordPress:

1. o WordPress
2. o banco de dados do WordPress

O arquivo é escrito em YAML (YAML Ain't Markup Language) e nele declaramos os
serviços da aplicação e tudo que eles usam: imagem, portas, volumes, redes,
variáveis de ambiente, dependências entre serviços, healthchecks e assim por
diante.

O nome de arquivo padrão é `compose.yaml` (o antigo `docker-compose.yml`
continua funcionando). Veja um exemplo:

```yaml
services:
  db:
    image: mysql:8.4
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: somewordpress
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      retries: 5

  wordpress:
    depends_on:
      db:
        condition: service_healthy
    image: wordpress:latest
    ports:
      - "8000:80"
    restart: always
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress

volumes:
  db_data:
```

Explicando o arquivo:

- **`services:`** — bloco que reúne todos os serviços (containers) da aplicação.
  Não existe mais a chave `version:` no topo: ela é ignorada pelo Compose Spec
  atual e só gera aviso.
- **`db:`** — nome do primeiro serviço. É também o hostname pelo qual os outros
  serviços o alcançam na rede interna criada pelo Compose.
- **`image: mysql:8.4`** — imagem e tag usadas pelo serviço. Fixe a versão em vez
  de depender de `latest`.
- **`volumes:`** no serviço — monta o volume nomeado `db_data` em
  `/var/lib/mysql`, ligando-se à definição no bloco `volumes:` do fim do arquivo.
- **`restart: always`** — o container é reiniciado sempre que parar.
- **`environment:`** — variáveis de ambiente do container. Para segredos reais,
  prefira `env_file` ou a chave `secrets:` em vez de deixá-los no arquivo.
- **`healthcheck:`** — comando que o Docker roda periodicamente para saber se o
  serviço está pronto.
- **`depends_on:` com `condition: service_healthy`** — o `wordpress` só sobe
  depois que o `db` estiver saudável (e não apenas iniciado).
- **`ports: "8000:80"`** — publica a porta 80 do container na porta 8000 do host.
- **bloco `volumes:` no fim** — declara o volume nomeado `db_data`, gerenciado
  pelo Docker.

## Comandos principais

```bash
docker compose up -d        # start the stack in the background
docker compose ps           # list the stack services
docker compose logs -f      # follow the logs
docker compose exec db bash # open a shell in the "db" service
docker compose down         # remove containers and networks
docker compose down -v      # same, and also remove the named volumes
```
