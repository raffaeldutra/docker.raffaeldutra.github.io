# Instalando

Para instalar Docker CE (Community Edition), você precisa de versão 64 bits.

Agora para instalarmos isso vai depender de bastante coisa, porém vamos trabalhar de maneira genérica, então segue duas formas:

Forma 1.

* Uma máquina virtual (VM): pode ser utilizando Virtualbox, VMware, tanto faz.
  * VM com acesso para internet.
  * VM com placa em modo bridge.
  * Curl instalado **sudo apt-get install curl --yes**

> Atenção: esta VM precisa ter uma interface em modo bridge para ter acesso aos containers que iremos estudar durante o workshop

Forma 2.

* Se você já for usuário Linux nativo, pode realizar diretamente sem necessitar de máquina virtual.

## Formas de instalar docker

Existem algumas formas de instalar Docker, porém vamos ver as duas mais comuns.

### Maneira 1

Remova a versão antiga (caso tiver).

```
sudo apt-get remove docker docker-engine docker.io
```

Instale os pacotes que permitem que o *apt* possa utilizar repositórios com https

```
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
```

Agora instale a chave GPG do Docker

> Preste atenção na sua distribuição abaixo

```
curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | sudo apt-key add -
```

Adicione o repositório.

```
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu (lsb_release -cs) stable"
```

Vamos atualizar o index dos pacotes apt

```
sudo apt-get update
```

Vamos instalar a última versão do Docker Community Edition

```
sudo apt-get install docker-ce
```

Vamos testar se está tudo funcionando

```
sudo docker run hello-world
```

### Maneira 2

> Dependendo da versão do seu Ubuntu, Debian e etc, pode
Baixe Docker com o comando mágico (funciona somente em Sistemas Operacionais). Windows, sorry :-)

```bash
curl -fsSL https://get.docker.com/ | sh
sudo usermod -aG docker <usuario>
```

Depois disso, você precisa fazer logoff para funcionar com este usuário.


### Como obter Docker para outros sistemas?

- [Link para documentação oficial](https://docs.docker.com/install/)
    - [Instalando em Windows](https://docs.docker.com/docker-for-windows/install/)
    - [Instalando em Debian](https://docs.docker.com/install/linux/docker-ce/debian/)
    - [Instalando em Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
    - [Instalando em MacOS](https://docs.docker.com/docker-for-mac/install/)
