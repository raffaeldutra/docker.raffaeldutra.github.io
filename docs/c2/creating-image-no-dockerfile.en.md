# Building an image without a Dockerfile

It is also possible to build an image without a Dockerfile, "freezing" the state
of a container with `docker container commit`. It is useful for quick
experiments, but **it is not reproducible** — for anything serious, prefer a
Dockerfile.

Enter an interactive container:

```
docker container run --interactive --tty --name my-ubuntu ubuntu /bin/bash
```

Inside the container, make whatever changes you want — install packages, create
files, etc.:

```
apt-get update && apt-get install -y curl
```

Leave the container (`exit`). It stays stopped, but preserved. Now build an image
from it:

```
docker container commit \
  --message "add curl" \
  --author "Rafael Dutra <raffaeldutra@gmail.com>" \
  my-ubuntu workshop/ubuntu-curl:0.1
```

Check that the image exists and run a container from it:

```
docker image ls workshop/ubuntu-curl
docker container run --rm workshop/ubuntu-curl:0.1 curl --version
```

> Notice the problem: whoever looks at this image has no way of knowing what was
> done or of redoing the process. With a Dockerfile, the history is versioned and
> anyone can rebuild the same image with `docker build`.
