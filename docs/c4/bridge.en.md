# Bridge network

`bridge` is Docker's default network driver and the one you will use most on a
single host. But there is a huge difference between the **default bridge** and a
**user-defined bridge** — and choosing the second one solves most networking
pains in development.

## How the bridge works

When you install Docker, it creates a Linux bridge called `docker0`. Each
container on the bridge network gets:

* an `eth0` interface inside its network _namespace_;
* a private IP from the bridge's subnet (by default something in
  `172.17.0.0/16`);
* a `veth` pair: one end inside the container (`eth0`), the other plugged into
  the bridge on the host.

Outbound traffic to the internet goes through **NAT**: Docker adds a
`MASQUERADE` rule in `iptables` that swaps the packet's source IP for the host's
IP.

See the bridge and the interfaces on the host:

```
ip addr show docker0
ip link | grep veth
```

## Default bridge vs. user-defined bridge

| Feature | Default bridge (`bridge`) | User-defined bridge |
|---|---|---|
| DNS name resolution | ❌ IP only (or `--link`, legacy) | ✅ a container resolves another's name |
| Isolation | every container with no explicit network lands here together | only the ones you connect |
| Connect/disconnect a running container | ❌ | ✅ `docker network connect` |
| Configure subnet, gateway, IP range | limited (via `daemon.json`) | ✅ per network, at `create` time |
| Shared environment variables via `--link` | ✅ (legacy feature) | ❌ (use DNS) |

The official documentation's recommendation is clear: **for anything beyond a
quick test, create your own bridge network.**

## Automatic internal DNS

This is the big reason to use a user-defined network. Docker brings up an
embedded DNS resolver at `127.0.0.11` inside every container and registers there
the **name** and the **aliases** of each container on the network.

```
docker network create app-net

docker container run -d --name db  --network app-net postgres:16
docker container run -d --name api --network app-net my-api:1.0
```

Now, from inside `api`, the host `db` resolves to the IP of the Postgres
container:

```
docker exec api getent hosts db
# 172.19.0.2      db
```

The application's connection string becomes simply
`postgres://db:5432/mydb` — no fixed IP, no address discovery at all.

Extra aliases when connecting:

```
docker container run -d --name api \
  --network app-net \
  --network-alias api \
  --network-alias api-internal \
  my-api:1.0
```

If several containers share the same alias, the internal DNS returns all the IPs
(a rustic _round-robin_ load balancing).

!!! note "`--link` is deprecated"

    The `--link` parameter of the default bridge still exists for compatibility,
    but it is considered legacy. User-defined networks do everything it did, and
    better.

## Communication between containers

On the same user-defined network, containers talk to each other **on any port**,
without needing `-p`. Port publishing is only needed to expose the service to the
**outside** (host / external network).

```
docker network create shop

# database: publishes NO port, only the internal network can reach it
docker container run -d --name db --network shop \
  -e POSTGRES_PASSWORD=secret postgres:16

# api: talks to "db:5432" internally and publishes 3000 to the host
docker container run -d --name api --network shop \
  -e DATABASE_URL=postgres://postgres:secret@db:5432/postgres \
  -p 3000:3000 my-api:1.0
```

From inside `api`:

```
docker exec api curl -s http://localhost:3000/health   # the API itself
docker exec api nc -z db 5432 && echo "database reachable"
```

From the host:

```
curl -s http://localhost:3000/health     # works: published port
nc -z localhost 5432                      # fails: 5432 was not published
```

## Segmenting with several networks

A common two-network pattern to reduce the attack surface:

```
docker network create --internal backend     # no route to the internet
docker network create frontend

# database: internal network only
docker container run -d --name db --network backend postgres:16

# api: on both networks — talks to the database and is exposed by the proxy
docker container run -d --name api --network backend my-api:1.0
docker network connect frontend api

# proxy: front network only, publishes port 80
docker container run -d --name proxy --network frontend -p 80:80 nginx
```

Result: `proxy` cannot see `db`, and `db` has no route to the internet.

## Talking to the host from the container

Use the magic name `host.docker.internal` (resolves to the host's IP):

```
docker container run --rm --add-host=host.docker.internal:host-gateway alpine \
  ping -c1 host.docker.internal
```

On Docker Desktop (macOS/Windows) this name already exists without `--add-host`.
On Linux, add `--add-host=host.docker.internal:host-gateway` (or the equivalent
`extra_hosts` in Compose).

## Tuning the default bridge

If you need to change the `docker0` subnet (a conflict with the company network,
for example), edit `/etc/docker/daemon.json`:

```json
{
  "bip": "10.200.0.1/24",
  "default-address-pools": [
    { "base": "10.201.0.0/16", "size": 24 }
  ]
}
```

* `bip` — IP/mask of `docker0` itself.
* `default-address-pools` — which ranges Docker takes the subnets from for the
  networks it creates automatically.

Then:

```
sudo systemctl restart docker
```

## MTU

On VPNs, some clouds and encapsulated networks, the default MTU of 1500 causes
silent stalls (the connection opens, but a large download "hangs"). Adjust it per
network:

```
docker network create --opt com.docker.network.driver.mtu=1400 vpn-net
```

Or globally in `daemon.json` with `"mtu": 1400`.
