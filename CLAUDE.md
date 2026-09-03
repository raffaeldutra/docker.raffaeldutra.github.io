# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Visão geral

Site de documentação sobre Docker, escrito em português do Brasil, publicado em
https://docker.rafaeldutra.me. Não há código de aplicação: todo o conteúdo são
arquivos Markdown em `docs/` renderizados por [MkDocs](https://www.mkdocs.org/)
com o tema [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/).

O site é **bilíngue** (português do Brasil e inglês) via o plugin
[`mkdocs-static-i18n`](https://github.com/ultrabug/mkdocs-static-i18n).
O português é o idioma padrão; a versão em inglês fica em arquivos `*.en.md`
ao lado dos originais (ex.: `docs/index.md` → `docs/index.en.md`). O build em PT
sai na raiz e o build em EN em `/en/`. O seletor de idioma aparece no cabeçalho.

Mensagens de commit e issues continuam em **português do Brasil**. Ao criar ou
editar uma página em português, crie/atualize também o `*.en.md` correspondente.

## Comandos

Não há build, lint ou testes. O fluxo é servir o site localmente e editar Markdown.

Servir com hot-reload (Docker). A imagem oficial não traz o plugin de i18n, então
é preciso instalá-lo antes:

```bash
docker container run --rm -it -p 8000:8001 -v $(pwd):/docs --entrypoint sh \
  squidfunk/mkdocs-material:9 -c \
  "pip install --no-cache-dir mkdocs-static-i18n && mkdocs serve --dev-addr=0.0.0.0:8001"
```

Ou usar `docker compose up` / `make serve` (o `docker-compose.yml` já faz esse
`pip install`), ou abrir o repositório no devcontainer
(`.devcontainer/devcontainer.json`), que também instala o plugin e roda
`mkdocs serve` na porta 8001 automaticamente.

Com MkDocs instalado localmente:

```bash
pip install mkdocs-material mkdocs-static-i18n
mkdocs serve      # servidor de desenvolvimento
mkdocs build      # gera o site estático em site/
```

## Deploy

Automático. O workflow `.github/workflows/ci.yml` roda em todo push para `main`
(ou `master`), instala `mkdocs-material` e `mkdocs-static-i18n` e executa
`mkdocs gh-deploy --force`,
que compila o site e faz push para a branch `gh-pages` (GitHub Pages). O domínio
customizado vem de `docs/CNAME` — mantenha esse arquivo ao mexer no deploy.

## Estrutura do conteúdo

- `mkdocs.yml` — configuração do site. A navegação é **manual**: ao adicionar uma
  página nova em `docs/`, é preciso registrá-la na seção `nav:`, senão ela não
  aparece no menu. A `nav:` usa só os títulos em português; a tradução dos rótulos
  do menu fica no bloco `plugins.i18n.languages` (chave `nav_translations` do
  idioma `en`). Ao adicionar um item novo com título explícito, acrescente a
  entrada correspondente em `nav_translations`.
- `docs/c1/`, `docs/c2/`, `docs/c3/` — capítulos (Containers, Imagens, Volumes).
  Imagens de cada capítulo ficam em `docs/cN/images/`.
- O tema usa extensões `admonition`, `def_list` e `pymdownx.tasklist` — blocos
  `!!! note`, listas de definição e checklists funcionam no Markdown.

## Observações

- O bloco `plugins:` em `mkdocs.yml` agora está no nível raiz e declara `search`
  e `i18n`. Ao adicionar plugins, mantenha `search` na lista (ele deixa de ser
  automático quando há um bloco `plugins:`).
- Convenção de commits do repositório: uma issue por mudança, branch
  `issue#<N>`, e mensagem `Closes #<N>. <descrição em português>`.
- Não inclua linha `Co-Authored-By: Claude` (nem qualquer atribuição ao Claude)
  nas mensagens de commit.
