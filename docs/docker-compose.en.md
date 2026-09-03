# Docker Compose

Docker Compose is the way to declare and run an application with several
containers from a single file. It is invoked through the
**`docker compose`** subcommand (with a space). The old `docker-compose` binary
(with a hyphen, Compose v1) has been deprecated since 2023 — if you still use it,
migrate to the v2 plugin, which already ships with Docker Desktop and with the
`docker-compose-plugin` package on Linux.

The idea is always the same: we have "separate things" that make up the
application and we want to describe them declaratively. For example:

1. an application written in PHP
2. a MySQL database

or the classic WordPress:

1. WordPress
2. the WordPress database

The file is written in YAML (YAML Ain't Markup Language) and in it we declare the
application's services and everything they use: image, ports, volumes, networks,
environment variables, dependencies between services, healthchecks and so on.

The default file name is `compose.yaml` (the old `docker-compose.yml` still
works). Here is an example:

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

Walking through the file:

- **`services:`** — the block that gathers every service (container) of the
  application. There is no more `version:` key at the top: it is ignored by the
  current Compose Spec and only produces a warning.
- **`db:`** — the name of the first service. It is also the hostname by which the
  other services reach it on the internal network created by Compose.
- **`image: mysql:8.4`** — image and tag used by the service. Pin the version
  instead of relying on `latest`.
- **`volumes:`** inside the service — mounts the named volume `db_data` at
  `/var/lib/mysql`, linking to the definition in the `volumes:` block at the end
  of the file.
- **`restart: always`** — the container is restarted whenever it stops.
- **`environment:`** — the container's environment variables. For real secrets,
  prefer `env_file` or the `secrets:` key instead of leaving them in the file.
- **`healthcheck:`** — a command Docker runs periodically to know whether the
  service is ready.
- **`depends_on:` with `condition: service_healthy`** — `wordpress` only starts
  after `db` is healthy (not just started).
- **`ports: "8000:80"`** — publishes container port 80 on host port 8000.
- **the `volumes:` block at the end** — declares the named volume `db_data`,
  managed by Docker.

## Main commands

```bash
docker compose up -d        # start the stack in the background
docker compose ps           # list the stack services
docker compose logs -f      # follow the logs
docker compose exec db bash # open a shell in the "db" service
docker compose down         # remove containers and networks
docker compose down -v      # same, and also remove the named volumes
```
