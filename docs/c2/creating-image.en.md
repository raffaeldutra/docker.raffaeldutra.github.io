# Building an image

To build an image we need a Dockerfile, as seen earlier. With it we generate our
own images in an organized and reproducible way.

The command is:

```
docker build --tag image-name:0.1 .
```

Two notes:

1. Docker sends the current directory (the `.` at the end of the command) as the
   **build context**. By default it looks for a file named `Dockerfile` in that
   directory; to use another one, pass `--file path/to/Dockerfile`.
2. Since Docker 23 the build is done by **BuildKit** by default, which is faster,
   caches better and runs stages in parallel. `docker build` and
   `docker image build` are equivalent.

Example:

```
docker build --tag workshop/nginx:0.1 .
```

Run a container based on the freshly built image:

```
docker container run --detach --publish 46000:80 workshop/nginx:0.1
```

Go to http://localhost:46000

* What happened?
* Why does changing `index.html` on your machine not change anything on the page?
  (The image is a snapshot: the file was copied at `build` time. To see live
  changes, you need a *bind mount*, which we will see in Volumes.)

## Building for multiple platforms

To produce images for more than one architecture (for example `amd64` and
`arm64`) and push them at once to a registry, use Buildx:

```
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag your-username/workshop-nginx:0.1 \
  --push .
```
