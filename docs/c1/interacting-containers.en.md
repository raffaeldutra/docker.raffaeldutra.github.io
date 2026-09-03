# Interacting with containers

So far we have done just a few examples; let's actually get inside a container
and work with it a bit.

Run the following command:

```
docker container run --interactive --tty --publish 45000:80 nginx /bin/bash
```

* Edit the file **/usr/share/nginx/html/index.html** with vim

What happened?

```
apt-get update && apt-get install vim --yes
```

Let's reach our web server again on port 45000 — and what do we notice? Well,
when we get inside a container, we "lose" the command/entrypoint execution the
image was meant for. To understand this better, let's look at how this **nginx**
image was built. To do that we will look at a repository for this image on
[Github](https://github.com/nginxinc/docker-nginx).

Docker Hub is an open image repository where all public images, including the one
we are using right now, live. You can build your own image and push it to Docker
Hub without any problem — just be careful not to leave any kind of credential
"floating around" in there.

So let's [open the Nginx repository](https://hub.docker.com/_/nginx/) and take a
closer look at what we are talking about.

When we open the file that describes how the image is built, we notice on the
last line a command called **CMD ["nginx", "-g", "daemon off;"]**. Loosely
translated, this command tells us: "when you run a new container I will
automatically invoke the command nginx -g daemon for you". In our case, we
entered the container in a way that we are "playing" with it, and this command
was not executed because it is only triggered when we do not pass a new parameter
to it — which was **/bin/bash**.

A Dockerfile is the file we are looking at right now, understanding its
"blueprint" of how the image works — and which we will also get into on its own.

Back to our initial problem. We noticed that when we entered the container
running Nginx it did not start the service, and that raises a simple question:
how do we bring up the nginx service? Simple, type the command **nginx** and
reach http://localhost:45000 again


> Working with containers can be as much work at the start as it actually is :-)

Now go to http://localhost:45000 again and see your new page.

But we can do something better without "touching" the container, something
interesting like *volumes*, which we will see soon.

When we start a new container, we can install packages, edit/delete/create files
and other things, but we have a problem when leaving the container the
traditional way through the terminal, because the container is automatically
stopped as soon as you type **exit** or press **control d**. To solve this, we
can use the key combination **control p q**, which keeps our container running
normally without stopping it.

Using this key combination raises the next question: "And if I want to get back
into the container, how do I do it?".

```
docker attach <container id> or <name>
```

Excellent, everything working as expected, but what if I just want to list a file
or maybe view something and so on? That is, I just want to do something quick in
my container?

```
docker exec <container id> or <name> ls -la /usr/share/nginx/html
```

* And if I want an interactive shell inside a container that is already running,
  without touching the main process (PID 1)? This is the most common way in
  day-to-day work:

```
docker exec --interactive --tty <container id> or <name> bash
```

> If the image does not have `bash` (lean images like Alpine), use `sh`.

* How do I view a container's log?

```
docker logs <container id> or <name>
```

* How do I view my container's status?

```
docker stats <container id> or <name>
```

* How do I view detailed information about a container?

```
docker inspect <container id> or <name>
```
