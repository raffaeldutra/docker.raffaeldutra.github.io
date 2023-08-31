![Docker](https://developers.redhat.com/sites/default/files/styles/article_feature/public/blog/2015/01/docker-whale-home-logo.png?itok=nf2cLFMc)


---

**Documentação do projeto**: <a href="https://docker.com/docs" target="_blank">https://docker.com/docs</a>

**Código fonte dessa página**: <a href="https://github.com/raffaeldutra/docker.raffaeldutra.github.io" target="_blank">https://github.com/raffaeldutra/docker.raffaeldutra.github.io</a>

---

## O que é?

_Docker_ é um software aberto que pode ser instalado para Linux (grande número de distribuições), Windows e MacOS, com o objetivo de agilizar e facilitar o desenvolvimento de aplicações em ambientes totalmente isolados e criando uma forma padronizada de como entregar software.

Antigamente, tinhamos uma grande barreira de como desenvolvedores e operadores lidavam com a entrega do software. Desenvolvedores criavam software e não estavam preocupados de que forma ele seria entregue para o time de operações, porém o time de operações prezava pelo funcionamento correto das aplicações, criando assim um atrito entre ambos os times.

## Infraestrutura

Quando utilizamos _Docker_, temos todos os passos de como a infraestrutura para este software foi criada em uma única imagem, viabilizando e muito em como o time de operações irá colocar este software em funcionamento. quais os diretórios, arquivos, scripts, comandos e serviço que devem ser criados e executados para que o software funcione.

Uma vez definida toda esta infaestrutura, empacotamos este software em uma imagem e esta imagem pode ser executada em qualquer Sistema Operacional devido ao modelo que _Docker_ utiliza de padronização de como aquele software deve ser construído.

Para rodar estas imagens precisamos criar os containers e estes containers é que vão de fato rodar sua aplicação e fazer ela ganhar vida. Quando o container iniciar, _Docker_ automaticamente isolará os recursos utilizados por este container, como memória, processamento e disco no hardware, garantindo assim a existência dos demais softwares com diferentes tecnologias sem a influência dos demais containers em execução.

Toda vez que for iniciado um novo container, apenas o processo é criado, levando com ele todas bibliotecas e configurações necessárias para que este processo fique completamente isolado, criando um overhead minímo, o que não acontece quando utilizamos Máquinas Virtuais (veremos um desenho sobre overhead e a diferença entre Máquinas Virtuais e containers mais à frente).

!!! note "Quando estamos falando em Hardware"

    Estamos falando do seu laptop, desktop ou servidor, o importante é entender que todos os containers feitos em _Docker_ são isolados e que ao executar o comando `ps -faux` você irá ver estes containers como sendo apenas processos da sua máquina.
