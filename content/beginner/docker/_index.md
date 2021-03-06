---
title: Por que usar Docker ?
weight: 1
pre: "<b>1 </b>"
chapter: false
---

1. Isolamento

O que estiver dentro do container, não irá afetar o restante de seu ambiente.  
Utilizando containers separados, cada componente de uma determinada aplicação faz com que você evite conflito de dependências.

2. Reproducibilidade

Uma vez que você consiga rodar o seu container em Docker, você será capaz de executá-lo exatamente da mesma maneira em outro ambiente que tenha Docker, simples assim, ou seja, se você rodar sua aplicação em uma máquina X e logo depois ir para uma máquina Y, você irá rodar sem problemas sua aplicação, pois tudo está encapsulado em uma mesma unidade de "medida", Docker.

3. Gerenciamento de ambientes

Usando Docker é muito fácil você ter diferentes tipos de ambientes, como teste, desenvolvimento, qualidade e produção. Você pode versionar toda sua infraestrutura e ter todo o controle do que está entrando em seu ambiente.

4. Integração contínua

Aqui está um grande ponto do uso Docker. Temos hoje uma vasta quantidade de ferramentas para usarmos como CI (Continuous Integratation), como Jenkins, Bamboo, Travis e etc. Cada vez que seu código fonte é atualizado, essas ferramentas salvam uma nova imagem e podem ir para produção.
