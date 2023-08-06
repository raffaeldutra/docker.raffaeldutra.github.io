# Criando uma imagem

Para criamos nossa imagem, precisamos de um arquivo Dockerfile conforme vistoacima. Com este arquivo podemos criar nossas próprias imagens de uma forma organizada e automatizada.

Para criarmos ela, devemos executar o comando

```
docker build --tag nomeDaImagemQueDeseja:versao.1 .
```

Devemos atentar par duas coisas aqui:

1 - O arquivo Dockerfile deve estar (mas podemos passar parâmetro, mas não vamos discutir isso agora) no mesmo diretório onde você está executando o comando.

2 - Existe sim um . (ponto) final no comando, ele diz de uma maneira simplificada que nosso Dockerfile está neste diretório.


É realmente simples gerarmos uma imagem com o nosso arquivo, segue um exemplo de como isto pode ser feito.

```
docker build --tag fossday/nginx:0.1 .
```

Agora vamos executar o nosso container baseado na imagem que acabamos de gerar.

```
docker container run --interactive --tty --publish 46000:80 fossday/nginx:0.1 /bin/bash
```

Vamos acessa a url e ver o que nos espera, http://localhost:46000

* O que aconteceu?
* Qual o motivo de alterarmos o arquivo index.html em nossa máquina e nada aconteceu na página?
