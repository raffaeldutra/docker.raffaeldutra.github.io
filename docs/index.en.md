![Docker](https://www.docker.com/app/uploads/2023/08/logo-guide-logos-1.svg)


---

**Official documentation**: <a href="https://docs.docker.com" target="_blank">https://docs.docker.com</a>

**Source code of this page**: <a href="https://github.com/raffaeldutra/docker.raffaeldutra.github.io" target="_blank">https://github.com/raffaeldutra/docker.raffaeldutra.github.io</a>

---

## What is it?

_Docker_ is an open piece of software that can be installed on Linux (a large number of distributions), Windows and macOS, with the goal of speeding up and simplifying application development in fully isolated environments and creating a standardized way to deliver software.

In the past, we had a big barrier in how developers and operators dealt with software delivery. Developers built software and were not concerned with how it would be handed over to the operations team, while the operations team cared about applications running correctly, which created friction between the two teams.

## Infrastructure

When we use _Docker_, we have every step of how the infrastructure for that software was built captured in a single image, which greatly helps the operations team get the software up and running: which directories, files, scripts, commands and services must be created and executed for the software to work.

Once all of this infrastructure is defined, we package the software into an image, and that image can run on any operating system thanks to the model _Docker_ uses to standardize how software should be built.

To run these images we need to create containers, and it is these containers that actually run your application and bring it to life. When the container starts, _Docker_ automatically isolates the resources it uses, such as memory, processing and disk on the hardware, thereby guaranteeing that other software built with different technologies keeps running without interference from the other running containers.

Every time a new container is started, only the process is created, carrying with it all the libraries and configuration needed for that process to be fully isolated, creating minimal overhead — which is not the case when we use Virtual Machines (we will look at a diagram about overhead and the difference between Virtual Machines and containers later on).

!!! note "When we talk about Hardware"

    We are talking about your laptop, desktop or server. The important thing is to understand that every container made with _Docker_ is isolated, and that when you run `ps -faux` you will see these containers as nothing more than processes on your machine.
