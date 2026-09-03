# Running containers

Check that Docker is working correctly:

```
docker version
```

The output should look like:

```
Client: Docker Engine - Community
 Version:           27.3.1
 API version:       1.47
 Go version:        go1.22.7
 Git commit:        ce12230
 Built:             Fri Sep 20 11:41:00 2024
 OS/Arch:           linux/amd64
 Context:           default

Server: Docker Engine - Community
 Engine:
  Version:          27.3.1
  API version:      1.47 (minimum version 1.24)
  Go version:       go1.22.7
  Git commit:       41ca978
  Built:            Fri Sep 20 11:41:00 2024
  OS/Arch:          linux/amd64
 containerd:
  Version:          1.7.22
 runc:
  Version:          1.1.14
```

## Commands

To see every command Docker offers, type:

```
docker
```

Important: the command line (CLI) is your best friend. If you do not know the
options of a command, use `--help`:

```
docker <command> --help
```

Since Docker 1.13 the commands are organized by object
(`docker container ...`, `docker image ...`, `docker volume ...`). The old short
forms (`docker run`, `docker ps`, `docker images`) still work as shortcuts.

## Running a container

```
docker container run alpine hostname
```

You got back an identifier with letters and numbers, something like
*7ed46aef747a*. That is the container's hostname, which by default is its ID.

Breaking the command down:

* **docker container run** creates and runs a container
* **alpine** is the name of the image used
* **hostname** is the command executed inside the container — that is why the
  output is that string of letters and numbers

Try it: if you run the command a few times, does the result change?

## Using images

Everything that runs in a container comes from an image, whether an image you
built or an official image, like the Alpine one above.

> Alpine is a tiny Linux distribution. The official container image is around
> 7 MB.

List the local images:

```
docker image ls
```

The result looks like:

```
REPOSITORY     TAG              IMAGE ID       CREATED        SIZE
golang         1.23-alpine      c7d7a3d1f0a1   2 weeks ago    248MB
maven          3.9-eclipse-temurin-21  9b2f7c4e5d6a  3 weeks ago  480MB
ubuntu         24.04            35a88802559d   4 weeks ago    78.1MB
python         3.12-alpine      f6a2b3c4d5e6   4 weeks ago    50.9MB
nginx          latest           195245f0c792   5 weeks ago    193MB
alpine         3.20             324bc02ae123   6 weeks ago    7.8MB
```

* How do you search for an image?

```
docker search <image>
```

* How do you remove an image?

```
docker image rm alpine
```

> You may get an error here if there is still a container (even a stopped one)
> based on that image. Remove the container first, or use `-f` with care.

* Where are the official and vendor-maintained images?

Today [Docker Hub](https://hub.docker.com) separates **Docker Official Images**
and **Verified Publisher**. You can filter by them in the site search.

* How do you download an image?

```
docker image pull ubuntu
```

For a specific version, give the tag after the `:`

```
docker image pull ubuntu:24.04
```

> Tip: always prefer an explicit tag (`ubuntu:24.04`) over `latest`, for
> reproducible builds. To pin it immutably, use the digest:
> `ubuntu@sha256:...`.
