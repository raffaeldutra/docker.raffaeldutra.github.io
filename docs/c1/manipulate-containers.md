# Manipulando containers

O comando que executamos incialmente *docker run alpine hostname* é o mais básico possível para termos um container em "funcionamento". O "funcionamento" entre aspas é o que iremos discutir neste momento.

Antes tentamos remover a imagem *alpine* e obtivemos um erro, mas o que causou o erro? Foi devido que o container está rodando. Então como sabemos se um container está rodando? ou melhor, como sabemos o "status" de um container?

Utilize o comando:

```
docker container <comando>
```

* Queremos listar containers?

```
docker container ls
```

* Queremos parar?

```
docker container stop <nome do container> ou <id do container>
```

* Queremos iniciar?

```
docker container start <nome do container> ou <id do container>
```

Para a lista de comandos que podemos utilizar, simplesmente execute:

```
docker container
```
