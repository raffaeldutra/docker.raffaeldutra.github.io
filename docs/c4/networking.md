# Redes no Docker

Todo container nasce conectado a alguma rede. É isso que permite um container
falar com outro, com o host e com a internet. Este capítulo mostra como o Docker
monta essa conectividade, quais são os drivers de rede disponíveis e como
inspecionar e depurar o que está acontecendo.

## O modelo de rede

O Docker implementa o **CNM** (_Container Network Model_) através da biblioteca
`libnetwork`. Três conceitos importam:

* **Sandbox** — o isolamento de rede de um container: sua própria pilha TCP/IP,
  tabela de rotas, interfaces (`eth0`, `lo`) e regras de `iptables`. Na prática é
  um _network namespace_ do Linux.
* **Endpoint** — a "ponta de cabo" que liga um sandbox a uma rede. Um container
  pode ter vários endpoints, um para cada rede em que está conectado.
* **Network** — um grupo de endpoints que conseguem se enxergar. Uma rede
  `bridge` no host normalmente corresponde a uma ponte Linux (`docker0` ou
  `br-xxxx`) e a um par de interfaces `veth` por container.

```
  container A                         container B
 ┌───────────────┐                   ┌───────────────┐
 │  sandbox      │                   │  sandbox      │
 │  eth0 ────────┤ endpoint          │ ────── eth0   │
 └───────┬───────┘                   └───────┬───────┘
     veth│                              veth │
     ┌───┴──────────────────────────────────┴───┐
     │            bridge  br-1a2b3c              │  ← rede definida pelo usuário
     └────────────────────┬─────────────────────┘
                          │  NAT (iptables MASQUERADE)
                    ┌─────┴─────┐
                    │  host eth0 │ → internet
                    └───────────┘
```

## Drivers de rede

O driver define **como** a rede é implementada. Os principais que já vêm com o
Docker:

`bridge`
: Rede padrão para containers em um único host. Cria uma ponte Linux e usa NAT
  para dar saída à internet. É o driver usado quando você não pede nada.
  Detalhado em [Rede bridge](bridge.md).

`host`
: Remove o isolamento de rede: o container compartilha a pilha de rede do host.
  Sem NAT, sem publicação de portas, latência mínima. Ver
  [host, none, macvlan e overlay](advanced-networks.md).

`none`
: O container fica só com a interface `lo`. Nenhuma conectividade externa. Útil
  para tarefas puramente offline ou quando outra ferramenta vai montar a rede.

`overlay`
: Liga containers em **hosts diferentes** numa mesma rede L2 virtual, via túnel
  VXLAN. É a base do Docker Swarm e serve para comunicação multi-host sem Swarm
  com `--attachable`.

`macvlan`
: Dá ao container um endereço MAC próprio, fazendo ele aparecer como um
  dispositivo físico na rede local. Bom para sistemas legados que esperam estar
  "na LAN".

`ipvlan`
: Parecido com `macvlan`, mas os containers compartilham o MAC do host e se
  diferenciam por IP (L3) ou por VLAN tag (L2). Útil quando o switch limita o
  número de MACs por porta.

Ainda existem drivers de terceiros (Weave, Calico, Cilium, etc.) instaláveis
como plugins.

!!! note "Qual driver usar?"

    * Um host só, vários containers conversando → **rede bridge definida pelo
      usuário**.
    * Precisa de performance máxima de rede e não se importa com isolamento →
      **host**.
    * Vários hosts → **overlay** (com Swarm) ou um orquestrador como Kubernetes.
    * O container precisa de um IP roteável na sua LAN → **macvlan/ipvlan**.

## Comandos essenciais

Listar as redes existentes:

```
docker network ls
```

Saída típica logo após instalar o Docker:

```
NETWORK ID     NAME      DRIVER    SCOPE
0a1b2c3d4e5f   bridge    bridge    local
6f7e8d9c0b1a   host      host      local
2a3b4c5d6e7f   none      null      local
```

Essas três redes (`bridge`, `host`, `none`) são criadas pelo Docker e **não
podem ser removidas**.

Criar uma rede definida pelo usuário:

```
docker network create minha-rede
```

Com opções mais explícitas:

```
docker network create \
  --driver bridge \
  --subnet 172.28.0.0/16 \
  --gateway 172.28.0.1 \
  --ip-range 172.28.5.0/24 \
  backend
```

* `--subnet` — faixa de IPs da rede.
* `--gateway` — IP do gateway (default: primeiro IP útil da subnet).
* `--ip-range` — restringe de qual sub-faixa o Docker aloca IPs automaticamente.
* `--internal` — rede sem saída para fora do host (sem NAT).
* `--label` — metadados, úteis para filtrar depois.

Conectar e desconectar containers de uma rede **em tempo de execução**:

```
docker network connect backend meu-container
docker network disconnect backend meu-container
```

Já subir o container conectado a uma rede:

```
docker container run -d --name api --network backend minha-api:1.0
```

Um container pode estar em várias redes ao mesmo tempo — uma prática comum é ter
uma rede `frontend` (exposta) e uma `backend` (interna) e colocar a aplicação
nas duas.

## Inspecionando uma rede

```
docker network inspect backend
```

Trecho relevante da saída:

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

Isso responde perguntas comuns: qual o IP de cada container, qual a subnet, quais
containers estão de fato ligados ali.

## Publicação de portas

Containers em uma rede bridge não são acessíveis a partir do host (ou da rede
externa) até que você **publique** uma porta:

```
docker container run -d -p 8080:80 nginx
```

Lê-se `-p HOST:CONTAINER`. O tráfego que chega em `localhost:8080` do host é
encaminhado (via `iptables`/`docker-proxy`) para a porta `80` do container.

Variações:

```
-p 80:80                # porta 80 do host → 80 do container
-p 127.0.0.1:8080:80    # publica só no loopback do host (não expõe na LAN)
-p 8080:80/udp          # protocolo UDP
-p 80                   # porta aleatória do host (veja com "docker port")
-P                      # publica TODAS as portas do EXPOSE em portas aleatórias
```

Ver o mapeamento efetivo:

```
docker port meu-container
```

!!! warning "`-p` fura o firewall"

    Em muitas distribuições o Docker insere regras direto no `iptables` e o
    mapeamento de porta pode passar por cima do `ufw`/`firewalld`. Se precisa
    expor só localmente, use `-p 127.0.0.1:PORTA:...`. Para produção, controle o
    acesso na camada de infraestrutura (security group, proxy reverso).

## Depurando conectividade

Rodar um container "canivete suíço" na mesma rede do serviço com problema:

```
docker container run --rm -it --network backend nicolaka/netshoot
```

Dentro dele você tem `dig`, `curl`, `ping`, `nc`, `tcpdump`, `ip`, `ss`,
`nmap`... Checklist rápido:

```
dig api                 # o DNS interno resolve o nome do outro container?
ping -c1 api            # há rota L3 até ele?
curl -v http://api:8080/health   # a aplicação responde na porta esperada?
ip route                # a tabela de rotas do sandbox está como esperado?
```

Do lado do host:

```
docker network inspect backend      # o container está mesmo nessa rede?
docker exec api ss -tlnp            # a aplicação está escutando em 0.0.0.0?
```

!!! note "Escutar em `127.0.0.1` dentro do container é uma armadilha"

    Se a aplicação faz _bind_ em `127.0.0.1`, ela só aceita conexões de dentro do
    próprio container. Para receber tráfego de outros containers ou do host, ela
    precisa escutar em `0.0.0.0` (todas as interfaces).

## Removendo redes

```
docker network rm backend            # remove uma rede específica (sem containers)
docker network prune                 # remove todas as redes sem containers
```
