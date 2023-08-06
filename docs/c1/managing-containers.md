# Gerenciando containers

Para podermos utilizar os comandos de stop e start, por exemplo, precisamos ter um container que de fato esta parado ou rodando, certo? então agora vamos rodar um container um pouco mais "complexo".

> Atenção, localhost é para máquinas que estão com Docker rodando diretamente no "bare metal", se estiver utilizando VM acesse o IP desta VM, algo como 192.168.25.100 - 10.100.111.222

Abra um browser e acesse http://localhost:45000 e a página não foi localizada, certo?

Execute o seguinte comando:

```
docker container run --detach --publish 45000:80 nginx
```

Agora abra novamente o endereço http://localhost:45000 - Magic!

Certo, agora temos um servidor web funcionando com apenas um comando na porta 45000 e com isso em funcionamento podemos utilizar os comandos de stop e start.

Vamos parar o container:

```
docker container stop <id do container>
```

Acesse novamente o seu browser e tente acessar a porta 45000.

Vamos subir novamente o container com o comando:

```
docker container start <id do container>
```
