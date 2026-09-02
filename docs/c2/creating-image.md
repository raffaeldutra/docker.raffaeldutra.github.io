# Criando uma imagem

Para criar uma imagem precisamos de um Dockerfile, como visto antes. Com ele
geramos nossas próprias imagens de forma organizada e reproduzível.

O comando é:

```
docker build --tag nome-da-imagem:0.1 .
```

Duas observações:

1. O Docker envia o diretório atual (o `.` no fim do comando) como **contexto de
   build**. Por padrão ele procura um arquivo chamado `Dockerfile` nesse
   diretório; para usar outro, passe `--file caminho/para/Dockerfile`.
2. Desde o Docker 23 o build é feito pelo **BuildKit** por padrão, que é mais
   rápido, faz cache melhor e roda estágios em paralelo. `docker build` e
   `docker image build` são equivalentes.

Exemplo:

```
docker build --tag workshop/nginx:0.1 .
```

Rode um container baseado na imagem recém-criada:

```
docker container run --detach --publish 46000:80 workshop/nginx:0.1
```

Acesse http://localhost:46000

* O que aconteceu?
* Por que alterar o `index.html` na sua máquina não muda nada na página?
  (A imagem é um snapshot: o arquivo foi copiado no momento do `build`. Para ver
  mudanças ao vivo, você precisa de um *bind mount*, que veremos em Volumes.)

## Build para múltiplas plataformas

Para gerar imagens para mais de uma arquitetura (por exemplo `amd64` e `arm64`)
e enviá-las de uma vez para um registro, use o Buildx:

```
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag seu-usuario/workshop-nginx:0.1 \
  --push .
```
