# Managing containers

To be able to use the stop and start commands, for example, we need a container
that is actually stopped or running, right? So now let's run a slightly more
"complex" container.

> Warning: localhost is for machines running Docker directly on bare metal; if
> you are using a VM, reach the IP of that VM, something like
> 192.168.25.100 - 10.100.111.222

Open a browser and go to http://localhost:45000 — the page is not found, right?

Run the following command:

```
docker container run --detach --publish 45000:80 nginx
```

Now open http://localhost:45000 again — Magic!

Right, now we have a web server running with a single command on port 45000, and
with that running we can use the stop and start commands.

Let's stop the container:

```
docker container stop <container id>
```

Go back to your browser and try to reach port 45000.

Let's bring the container back up with:

```
docker container start <container id>
```
