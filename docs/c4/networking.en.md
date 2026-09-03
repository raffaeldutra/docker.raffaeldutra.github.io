# Docker networking

Every container is born connected to some network. That is what lets a container
talk to another one, to the host and to the internet. This chapter shows how
Docker assembles that connectivity, which network drivers are available and how
to inspect and debug what is going on.

## The network model

Docker implements the **CNM** (_Container Network Model_) through the
`libnetwork` library. Three concepts matter:

* **Sandbox** — a container's network isolation: its own TCP/IP stack, routing
  table, interfaces (`eth0`, `lo`) and `iptables` rules. In practice it is a
  Linux _network namespace_.
* **Endpoint** — the "cable end" that connects a sandbox to a network. A
  container can have several endpoints, one for each network it is connected to.
* **Network** — a group of endpoints that can see each other. A `bridge` network
  on the host normally corresponds to a Linux bridge (`docker0` or `br-xxxx`) and
  a pair of `veth` interfaces per container.

```
  container A                         container B
 ┌───────────────┐                   ┌───────────────┐
 │  sandbox      │                   │  sandbox      │
 │  eth0 ────────┤ endpoint          │ ────── eth0   │
 └───────┬───────┘                   └───────┬───────┘
     veth│                              veth │
     ┌───┴──────────────────────────────────┴───┐
     │            bridge  br-1a2b3c              │  ← user-defined network
     └────────────────────┬─────────────────────┘
                          │  NAT (iptables MASQUERADE)
                    ┌─────┴─────┐
                    │  host eth0 │ → internet
                    └───────────┘
```

## Network drivers

The driver defines **how** the network is implemented. The main ones that ship
with Docker:

`bridge`
: The default network for containers on a single host. It creates a Linux bridge
  and uses NAT to give internet access. It is the driver used when you ask for
  nothing. Detailed in [Bridge network](bridge.md).

`host`
: Removes network isolation: the container shares the host's network stack.
  No NAT, no port publishing, minimal latency. See
  [host, none, macvlan and overlay](advanced-networks.md).

`none`
: The container is left with only the `lo` interface. No external connectivity.
  Useful for purely offline tasks or when another tool will set up the network.

`overlay`
: Connects containers on **different hosts** to the same virtual L2 network, via
  a VXLAN tunnel. It is the basis of Docker Swarm and is used for multi-host
  communication without Swarm through `--attachable`.

`macvlan`
: Gives the container its own MAC address, making it appear as a physical device
  on the local network. Good for legacy systems that expect to be "on the LAN".

`ipvlan`
: Similar to `macvlan`, but containers share the host's MAC and are told apart by
  IP (L3) or by VLAN tag (L2). Useful when the switch limits the number of MACs
  per port.

There are also third-party drivers (Weave, Calico, Cilium, etc.) that can be
installed as plugins.

!!! note "Which driver should I use?"

    * A single host, several containers talking → **user-defined bridge
      network**.
    * You need maximum network performance and do not care about isolation →
      **host**.
    * Several hosts → **overlay** (with Swarm) or an orchestrator like
      Kubernetes.
    * The container needs a routable IP on your LAN → **macvlan/ipvlan**.

## Essential commands

List the existing networks:

```
docker network ls
```

Typical output right after installing Docker:

```
NETWORK ID     NAME      DRIVER    SCOPE
0a1b2c3d4e5f   bridge    bridge    local
6f7e8d9c0b1a   host      host      local
2a3b4c5d6e7f   none      null      local
```

These three networks (`bridge`, `host`, `none`) are created by Docker and
**cannot be removed**.

Create a user-defined network:

```
docker network create my-net
```

With more explicit options:

```
docker network create \
  --driver bridge \
  --subnet 172.28.0.0/16 \
  --gateway 172.28.0.1 \
  --ip-range 172.28.5.0/24 \
  backend
```

* `--subnet` — the network's IP range.
* `--gateway` — the gateway IP (default: first usable IP of the subnet).
* `--ip-range` — restricts which sub-range Docker allocates IPs from
  automatically.
* `--internal` — a network with no way out of the host (no NAT).
* `--label` — metadata, useful for filtering later.

Connect and disconnect containers from a network **at runtime**:

```
docker network connect backend my-container
docker network disconnect backend my-container
```

Start a container already connected to a network:

```
docker container run -d --name api --network backend my-api:1.0
```

A container can be on several networks at once — a common practice is to have a
`frontend` network (exposed) and a `backend` network (internal) and place the
application on both.

## Inspecting a network

```
docker network inspect backend
```

Relevant excerpt from the output:

```json
[
    {
        "Name": "backend",
        "Driver": "bridge",
        "IPAM": {
            "Config": [
                { "Subnet": "172.28.0.0/16", "Gateway": "172.28.0.1" }
            ]
        },
        "Internal": false,
        "Containers": {
            "3f2a...": {
                "Name": "api",
                "IPv4Address": "172.28.5.2/16",
                "MacAddress": "02:42:ac:1c:05:02"
            }
        }
    }
]
```

This answers common questions: what is each container's IP, what is the subnet,
which containers are actually attached there.

## Port publishing

Containers on a bridge network are not reachable from the host (or the external
network) until you **publish** a port:

```
docker container run -d -p 8080:80 nginx
```

Read it as `-p HOST:CONTAINER`. Traffic arriving at `localhost:8080` on the host
is forwarded (via `iptables`/`docker-proxy`) to port `80` of the container.

Variations:

```
-p 80:80                # host port 80 → container port 80
-p 127.0.0.1:8080:80    # publishes only on the host loopback (not exposed on the LAN)
-p 8080:80/udp          # UDP protocol
-p 80                   # random host port (see it with "docker port")
-P                      # publishes ALL EXPOSE ports on random ports
```

See the actual mapping:

```
docker port my-container
```

!!! warning "`-p` bypasses the firewall"

    On many distributions Docker inserts rules straight into `iptables`, and the
    port mapping can bypass `ufw`/`firewalld`. If you need to expose only
    locally, use `-p 127.0.0.1:PORT:...`. For production, control access at the
    infrastructure layer (security group, reverse proxy).

## Debugging connectivity

Run a "Swiss army knife" container on the same network as the misbehaving
service:

```
docker container run --rm -it --network backend nicolaka/netshoot
```

Inside it you have `dig`, `curl`, `ping`, `nc`, `tcpdump`, `ip`, `ss`,
`nmap`... Quick checklist:

```
dig api                 # does the internal DNS resolve the other container's name?
ping -c1 api            # is there an L3 route to it?
curl -v http://api:8080/health   # does the app respond on the expected port?
ip route                # is the sandbox routing table as expected?
```

From the host side:

```
docker network inspect backend      # is the container really on this network?
docker exec api ss -tlnp            # is the app listening on 0.0.0.0?
```

!!! note "Listening on `127.0.0.1` inside the container is a trap"

    If the application _binds_ to `127.0.0.1`, it only accepts connections from
    inside the container itself. To receive traffic from other containers or from
    the host, it must listen on `0.0.0.0` (all interfaces).

## Removing networks

```
docker network rm backend            # removes a specific network (with no containers)
docker network prune                 # removes all networks with no containers
```
