# Rede bridge

A `bridge` é o driver de rede padrão do Docker e o que você mais vai usar em um
único host. Mas existe uma diferença enorme entre a **bridge padrão** e uma
**bridge definida pelo usuário** — e escolher a segunda resolve a maior parte
das dores de rede em desenvolvimento.

## Como a bridge funciona

Ao instalar o Docker, ele cria uma ponte Linux chamada `docker0`. Cada container
na rede bridge ganha:

* uma interface `eth0` dentro do seu _namespace_ de rede;
* um IP privado da subnet da ponte (por padrão algo em `172.17.0.0/16`);
* um par `veth`: uma ponta dentro do container (`eth0`), outra plugada na ponte
  no host.

A saída para a internet passa por **NAT**: o Docker adiciona uma regra
`MASQUERADE` no `iptables` que troca o IP de origem do pacote pelo IP do host.

Ver a ponte e as interfaces no host:

```
ip addr show docker0
ip link | grep veth
```

## bridge padrão x bridge definida pelo usuário

| Característica | bridge padrão (`bridge`) | bridge definida pelo usuário |
|---|---|---|
| Resolução de nomes por DNS | ❌ só por IP (ou `--link`, legado) | ✅ container resolve o nome do outro |
| Isolamento | todos os containers sem rede explícita caem juntos aqui | só quem você conectar |
| Conectar/desconectar container em execução | ❌ | ✅ `docker network connect` |
| Configurar subnet, gateway, faixa de IP | limitado (via `daemon.json`) | ✅ por rede, no `create` |
| Variáveis de ambiente compartilhadas via `--link` | ✅ (recurso legado) | ❌ (use DNS) |

A recomendação da documentação oficial é clara: **para qualquer coisa além de um
teste rápido, crie sua própria rede bridge.**

## DNS interno automático

Este é o grande motivo para usar uma rede definida pelo usuário. O Docker sobe um
resolvedor DNS embutido em `127.0.0.11` dentro de cada container e registra ali o
**nome** e os **aliases** de cada container da rede.

```
docker network create app-net

docker container run -d --name db  --network app-net postgres:16
docker container run -d --name api --network app-net my-api:1.0
```

Agora, de dentro de `api`, o host `db` resolve para o IP do container do
Postgres:

```
docker exec api getent hosts db
# 172.19.0.2      db
```

A string de conexão da aplicação vira simplesmente
`postgres://db:5432/mydb` — sem IP fixo, sem descobrir endereço nenhum.

Aliases adicionais na hora de conectar:

```
docker container run -d --name api \
  --network app-net \
  --network-alias api \
  --network-alias api-internal \
  my-api:1.0
```

Se vários containers compartilham o mesmo alias, o DNS interno devolve todos os
IPs (um _round-robin_ rústico de balanceamento).

!!! note "`--link` está obsoleto"

    O parâmetro `--link` da bridge padrão ainda existe por compatibilidade, mas
    é considerado legado. Redes definidas pelo usuário fazem tudo o que ele fazia
    e melhor.

## Comunicação entre containers

Na mesma rede definida pelo usuário, os containers se falam **por qualquer
porta**, sem precisar de `-p`. A publicação de portas só é necessária para expor
o serviço para **fora** (host / rede externa).

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

De dentro de `api`:

```
docker exec api curl -s http://localhost:3000/health   # the API itself
docker exec api nc -z db 5432 && echo "database reachable"
```

Do host:

```
curl -s http://localhost:3000/health     # works: published port
nc -z localhost 5432                      # fails: 5432 was not published
```

## Segmentando com várias redes

Padrão comum de duas redes para reduzir a superfície de ataque:

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

Resultado: o `proxy` não enxerga o `db`, e o `db` não tem rota para a internet.

## Falar com o host a partir do container

Use o nome mágico `host.docker.internal` (resolve para o IP do host):

```
docker container run --rm --add-host=host.docker.internal:host-gateway alpine \
  ping -c1 host.docker.internal
```

No Docker Desktop (macOS/Windows) esse nome já existe sem o `--add-host`. No
Linux, adicione `--add-host=host.docker.internal:host-gateway` (ou o
equivalente `extra_hosts` no Compose).

## Ajustando a bridge padrão

Se precisar mudar a subnet da `docker0` (conflito com a rede da empresa, por
exemplo), edite `/etc/docker/daemon.json`:

```json
{
  "bip": "10.200.0.1/24",
  "default-address-pools": [
    { "base": "10.201.0.0/16", "size": 24 }
  ]
}
```

* `bip` — IP/máscara da própria `docker0`.
* `default-address-pools` — de quais faixas o Docker tira as subnets das redes
  que ele cria automaticamente.

Depois:

```
sudo systemctl restart docker
```

## MTU

Em VPNs, algumas nuvens e redes encapsuladas, o MTU padrão de 1500 causa
travadas silenciosas (conexão abre, mas download grande "pendura"). Ajuste por
rede:

```
docker network create --opt com.docker.network.driver.mtu=1400 vpn-net
```

Ou globalmente no `daemon.json` com `"mtu": 1400`.
