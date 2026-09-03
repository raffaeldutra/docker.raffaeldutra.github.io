# host, none, macvlan and overlay

Besides the bridge, Docker brings other drivers for specific cases: gluing the
container to the host's network stack, isolating it completely, giving it a
routable IP on the LAN, or connecting it to containers on other machines.

## The `host` network

The container **shares the host's _network namespace_**. There is no `veth`, no
NAT, no port publishing — if the application listens on `8080`, it is on the
host's `8080` immediately.

```
docker container run -d --network host nginx
curl http://localhost:80          # responds already, no -p
```

Advantages:

* Latency and throughput practically equal to running the process directly on the
  host.
* No `docker-proxy` overhead for thousands of ports (media servers, games,
  metrics collectors).

Disadvantages:

* **Zero network isolation.** The container sees all of the host's interfaces.
* Port conflicts: two `host` containers cannot listen on the same port.
* `-p` is ignored (and Docker emits a warning).
* On Docker Desktop (macOS/Windows) the `host` mode has limitations — it really
  works on Docker Engine on Linux.

!!! warning

    Use `host` when network performance is really the bottleneck and you trust
    the image. For most web services, a user-defined bridge with `-p` is safer
    and sufficient.

## The `none` network

The container is left with only `lo` (loopback). No network card, no routes.

```
docker container run --rm --network none alpine ip addr
# 1: lo: <LOOPBACK,UP,LOWER_UP> ...
```

It is useful for:

* Pure processing jobs (converting a file, running a calculation) that must not
  touch the network.
* Security scenarios where another tool (CNI, script) configures the network
  afterwards.

## The `macvlan` network

Gives the container its **own MAC address** on the physical network. To the
switch and the rest of the LAN, the container looks like a real computer, with an
IP in the same range as the other hosts.

Use cases: legacy appliances/services that need to be "on the network",
monitoring systems that do LAN discovery, when NAT simply is not accepted.

```
docker network create -d macvlan \
  --subnet=192.168.0.0/24 \
  --gateway=192.168.0.1 \
  -o parent=eth0 \
  lan
```

* `parent=eth0` — the host's physical interface through which the traffic will
  leave.
* `--subnet`/`--gateway` — those of your real LAN.

```
docker container run -d --name legacy --network lan --ip 192.168.0.50 my-img
```

Points to watch:

* The host's NIC needs to go into **promiscuous mode**; some cloud providers and
  many Wi-Fi APs block this — `macvlan` usually works only on a wired network.
* By default, **the host cannot talk to the macvlan containers** (a driver
  limitation). You work around it by creating a macvlan subinterface on the host
  itself.
* Reserve a range outside the DHCP scope with `--ip-range` to avoid address
  clashes.

### `ipvlan`

An alternative when the switch limits MACs per port: containers share the host's
MAC and are told apart by IP (L3 mode) or by VLAN (L2 mode).

```
docker network create -d ipvlan \
  --subnet=192.168.10.0/24 \
  -o parent=eth0 -o ipvlan_mode=l2 \
  ipvlan-lan
```

## The `overlay` network (multi-host)

`overlay` creates a virtual L2 network that spans **several hosts** through a
**VXLAN** tunnel (UDP 4789). Containers on different machines get IPs from the
same subnet and talk as if they were on the same switch.

It is **Docker Swarm**'s native driver. To use it you need an active Swarm:

```
# on the first node
docker swarm init --advertise-addr 203.0.113.10

# the output gives you the command to run on the other nodes:
docker swarm join --token SWMTKN-1-xxxx 203.0.113.10:2377
```

Create the overlay network:

```
docker network create -d overlay --attachable app-overlay
```

* `--attachable` lets standalone containers (`docker run`) join the network, not
  just Swarm services.
* Add `--opt encrypted` to encrypt the traffic between nodes (IPsec) — it costs
  a bit of CPU.

A Swarm service on that network:

```
docker service create --name web --network app-overlay --replicas 3 nginx
```

The three replicas, even spread across different nodes, resolve each other by the
name `web` and are balanced by an internal VIP.

### Ports that must be open between the nodes

| Port | Protocol | Use |
|---|---|---|
| 2377 | TCP | cluster management (managers only) |
| 7946 | TCP and UDP | node discovery (_gossip_) |
| 4789 | UDP | overlay VXLAN data traffic |

## Summary: when to use each one

| Driver | Scope | Isolation | When |
|---|---|---|---|
| `bridge` (user-defined) | 1 host | high | default for almost everything |
| `host` | 1 host | none | critical network performance |
| `none` | 1 host | total | offline jobs, network set up by a third party |
| `macvlan` / `ipvlan` | 1 host (LAN) | medium | container needs a routable IP on the LAN |
| `overlay` | several hosts | high | Swarm, multi-host communication |
