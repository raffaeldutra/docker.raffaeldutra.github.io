# Volumes

Volumes are fully managed and created by Docker, and you can create them with
commands or, alternatively, Docker can create the volume while creating the
service.

.Command to create a volume

```shell
$ docker volume create <volume name>
```

.Example of how to create a volume and name it _data_.

```shell
$ docker volume create data
```

To list the volumes.

```shell
$ docker volume ls
```

With the following output:

```shell
DRIVER              VOLUME NAME
local               data
local               e8bf838bebbe3576313a6b37a26ab93d1fbb4865174710d9cb4d80366e85c674
```

If no argument is given to name your volume, a hash is generated, as in the
example above where we have the hash starting with `e8bf83..`.

To find out where this directory with your volume was created, you need to
inspect the volume.

To inspect a volume, use the _inspect_ command

```shell
$ docker volume inspect data
```

With the following output:

```shell
[
    {
        "CreatedAt": "2019-01-30T14:00:29-02:00",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/var/lib/docker/volumes/data/_data",
        "Name": "data",
        "Options": {},
        "Scope": "local"
    }
]
```

Every time a volume is created, it is stored in a directory on the Docker host,
and it is this structure that gets sent into the container. The big difference
here compared to `bind mounts` is that all data created in this volume is managed
by _Docker_.

All created volumes can be used by several containers at the same time, or, when
there are no containers using the volume, it stays waiting until it is needed
again. The important thing here is that your volume will always be there waiting
to be used.

Volumes have several advantages over `bind mounts`:

* Easy to back up or migrate.
* You can manage volumes using the _Docker_ _CLI_ or the API.
* Volumes work on Linux and Windows.
* Volumes are safer to share between several containers.
* Volumes come with many kinds of drivers to work locally, with _Cloud
  Computing_ providers (_AWS_, _Google Cloud_, _Azure_ and others), to encrypt
  their content or add features.
* Volumes are generally a better choice than persisting data in the container's
  write layer, because the volume does not increase the size of the container
  using it, and the volume's content lives entirely outside a container.

To use volumes on the command line, you can pass `--mount` (recommended, more
explicit) or the short form `-v` / `--volume`. Let's see an example:

```shell
$ docker run --rm \
--mount type=volume,source=ubuntu-volume,target=/tmp \
ubuntu \
mkdir /tmp/new-directory
```

> The equivalent form with `-v` would be `-v ubuntu-volume:/tmp`.

With this command, a new directory was created at `/tmp/new-directory` inside the
container, but since we are using volumes, we can find this data directly on our
host where the data is persisted.

Checking the volume path

```shell
$ docker volume inspect ubuntu-volume
```

With the following output.

```shell
[
    {
        "CreatedAt": "2019-01-30T19:40:29-02:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/ubuntu-volume/_data",
        "Name": "ubuntu-volume",
        "Options": null,
        "Scope": "local"
    }
]
```

With the command below, check that the directory was created.

```shell
$ sudo ls -la /var/lib/docker/volumes/ubuntu-volume/_data
```

Let's create two more containers pointing to this same volume, but in one of
those two containers we will create some files, and in the other container we
should be able to list these new files.


```shell
$ docker run \
--interactive \
--tty \
--volume ubuntu-volume:/tmp ubuntu
```

List the content of the `/tmp` directory


```shell
root@a83a59e4555c:/# ls -la /tmp/
total 12
drwxrwxrwt 3 root root 4096 Jan 30 21:40 .
drwxr-xr-x 1 root root 4096 Jan 30 22:07 ..
drwxr-xr-x 2 root root 4096 Jan 30 21:40 new-directory
```

Open a new terminal and run a new container, creating some files inside the `tmp`
directory.

Creating a new container

```shell
$ docker run \
--interactive \
--tty \
--volume ubuntu-volume:/tmp ubuntu
```

Creating new directories in the `/tmp` directory

```shell
cd /tmp
root@71df4a42bc32:/tmp# mkdir -p directory-a directory-b directory-c/subdirectory-a
```

In the first container, list the `tmp` directory.

```shell
root@a83a59e4555c:/# ls -la /tmp/
total 24
drwxrwxrwt 6 root root 4096 Jan 30 22:13 .
drwxr-xr-x 1 root root 4096 Jan 30 22:07 ..
drwxr-xr-x 2 root root 4096 Jan 30 22:13 directory-a
drwxr-xr-x 2 root root 4096 Jan 30 22:13 directory-b
drwxr-xr-x 3 root root 4096 Jan 30 22:13 directory-c
drwxr-xr-x 2 root root 4096 Jan 30 21:40 new-directory
```

## Bind Mounts

Bind mounts are less efficient than _volumes_, because the directory or file on
your machine is pointed into the container. If you are starting a new project,
prefer volumes over _bind mounts_.

In Docker version _17.06_ a parameter called *--mount* was introduced for
containers. Using *--mount* instead of the *-v* parameter is recommended because
*--mount* is more explicit and easier to use.

Assuming you have a directory called _test_ with any file inside it, let's run
the command to mount these objects inside the container.

To use *bind mounts*, just pass this argument when calling a new container:

```shell
$ docker run -it \
--mount type=bind,source=/tmp/test,target=/tmp/test \
alpine \
ls -la /tmp/test
```

With the following output:

```shell
total 4
drwxr-xr-x    3 root     root            96 Feb 17 00:30 .
drwxrwxrwt    1 root     root          4096 Feb 17 00:30 ..
drwxr-xr-x    2 root     root            64 Feb 17 00:30 directory-a
```
