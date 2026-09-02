# host, none, macvlan e overlay

Além da bridge, o Docker traz outros drivers para casos específicos: colar o
container na pilha de rede do host, isolá-lo por completo, dar a ele um IP
roteável na LAN ou ligá-lo a containers em outras máquinas.

## Rede `host`

O container **compartilha o _network namespace_ do host**. Não há `veth`, não há
NAT, não há publicação de portas — se a aplicação escuta na `8080`, ela está na
`8080` do host imediatamente.

```
docker container run -d --network host nginx
curl http://localhost:80          # já responde, sem -p
```

Vantagens:

* Latência e throughput praticamente iguais ao processo rodando direto no host.
* Sem a sobrecarga do `docker-proxy` para milhares de portas (servidores de
  mídia, jogos, coletores de métricas).

Desvantagens:

* **Zero isolamento de rede.** O container enxerga todas as interfaces do host.
* Conflito de portas: dois containers `host` não podem escutar na mesma porta.
* `-p` é ignorado (e o Docker emite um aviso).
* No Docker Desktop (macOS/Windows) o modo `host` tem limitações — ele funciona
  de verdade no Docker Engine em Linux.

!!! warning

    Use `host` quando performance de rede for realmente o gargalo e você
    confiar na imagem. Para a maioria dos serviços web, uma bridge definida pelo
    usuário com `-p` é mais segura e suficiente.

## Rede `none`

O container fica só com `lo` (loopback). Nenhuma placa de rede, nenhuma rota.

```
docker container run --rm --network none alpine ip addr
# 1: lo: <LOOPBACK,UP,LOWER_UP> ...
```

Serve para:

* Jobs de processamento puro (converter um arquivo, rodar um cálculo) que não
  devem tocar a rede.
* Cenários de segurança em que outra ferramenta (CNI, script) configura a rede
  depois.

## Rede `macvlan`

Dá ao container um **endereço MAC próprio** na rede física. Para o switch e para
o resto da LAN, o container parece um computador de verdade, com IP na mesma
faixa dos demais hosts.

Casos de uso: appliances/serviços legados que precisam estar "na rede", sistemas
de monitoração que fazem descoberta na LAN, quando NAT simplesmente não é aceito.

```
docker network create -d macvlan \
  --subnet=192.168.0.0/24 \
  --gateway=192.168.0.1 \
  -o parent=eth0 \
  lan
```

* `parent=eth0` — a interface física do host por onde o tráfego vai sair.
* `--subnet`/`--gateway` — os da sua LAN real.

```
docker container run -d --name legado --network lan --ip 192.168.0.50 minha-img
```

Pontos de atenção:

* A NIC do host precisa entrar em **modo promíscuo**; alguns provedores de nuvem
  e muitos APs Wi-Fi bloqueiam isso — `macvlan` costuma funcionar só em rede
  cabeada.
* Por padrão, **o host não fala com os containers macvlan** (limitação do
  driver). Contorna-se criando uma subinterface macvlan no próprio host.
* Reserve uma faixa fora do escopo do DHCP com `--ip-range` para não colidir
  endereços.

### `ipvlan`

Alternativa quando o switch limita MACs por porta: os containers compartilham o
MAC do host e se distinguem por IP (modo L3) ou por VLAN (modo L2).

```
docker network create -d ipvlan \
  --subnet=192.168.10.0/24 \
  -o parent=eth0 -o ipvlan_mode=l2 \
  ipvlan-lan
```

## Rede `overlay` (multi-host)

A `overlay` cria uma rede L2 virtual que atravessa **vários hosts** por um túnel
**VXLAN** (UDP 4789). Containers em máquinas diferentes recebem IPs da mesma
subnet e se falam como se estivessem no mesmo switch.

É o driver nativo do **Docker Swarm**. Para usá-lo é preciso ter um Swarm ativo:

```
# no primeiro nó
docker swarm init --advertise-addr 203.0.113.10

# a saída te dá o comando pra rodar nos outros nós:
docker swarm join --token SWMTKN-1-xxxx 203.0.113.10:2377
```

Criar a rede overlay:

```
docker network create -d overlay --attachable app-overlay
```

* `--attachable` permite que containers avulsos (`docker run`) entrem na rede,
  não só serviços do Swarm.
* Adicione `--opt encrypted` para cifrar o tráfego entre nós (IPsec) — custa um
  pouco de CPU.

Um serviço Swarm nessa rede:

```
docker service create --name web --network app-overlay --replicas 3 nginx
```

As três réplicas, mesmo espalhadas por nós diferentes, resolvem umas às outras
pelo nome `web` e são balanceadas por um VIP interno.

### Portas que precisam estar abertas entre os nós

| Porta | Protocolo | Uso |
|---|---|---|
| 2377 | TCP | gerência do cluster (só entre managers) |
| 7946 | TCP e UDP | descoberta de nós (_gossip_) |
| 4789 | UDP | tráfego de dados VXLAN da overlay |

## Resumo: quando usar cada um

| Driver | Escopo | Isolamento | Quando |
|---|---|---|---|
| `bridge` (definida pelo usuário) | 1 host | alto | padrão para quase tudo |
| `host` | 1 host | nenhum | performance de rede crítica |
| `none` | 1 host | total | jobs offline, rede montada por terceiro |
| `macvlan` / `ipvlan` | 1 host (LAN) | médio | container precisa de IP roteável na LAN |
| `overlay` | vários hosts | alto | Swarm, comunicação multi-host |
