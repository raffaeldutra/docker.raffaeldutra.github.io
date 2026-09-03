# Manipulating containers

The command we ran initially, *docker container run alpine hostname*, is the most
basic possible way to have a container "running". The "running" in quotes is what
we will discuss now.

Earlier we tried to remove the *alpine* image and got an error, but what caused
the error? It was because the container is running. So how do we know whether a
container is running? Or better, how do we know the "status" of a container?

Use the command:

```
docker container <command>
```

* Want to list containers?

```
docker container ls
```

* Want to stop one?

```
docker container stop <container name> or <container id>
```

* Want to start one?

```
docker container start <container name> or <container id>
```

For the list of commands you can use, simply run:

```
docker container
```
