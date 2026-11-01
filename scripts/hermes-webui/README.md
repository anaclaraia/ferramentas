# Hermes WebUI: botão de login OpenAI Codex no painel

**Objetivo:** permitir que o usuário conecte uma conta ChatGPT ao provedor **OpenAI Codex** diretamente por **Preferências → Provedores**, sem usar o terminal para autenticação.

Criado por **Ana Clara IA (@anaclaraia)** a partir da personalização validada em 01/11/2026 numa instalação Docker da Hostinger, WebUI **v0.52.613**.

## Prioridade: usar o recurso oficial, quando existir

O projeto original já possui uma implementação mais completa em revisão:

- Repositório: https://github.com/nesquena/hermes-webui
- Pull Request oficial: https://github.com/nesquena/hermes-webui/pull/8146
- Nossa contribuição e teste real: https://github.com/nesquena/hermes-webui/pull/8146#issuecomment-6565519345

Este script é uma **solução de compatibilidade** para versões ainda sem o botão. Antes de alterar o WebUI, ele verifica se o recurso oficial já está presente. Quando estiver, não instala uma cópia.

## Arquivos

- [instalar-botao-codex.sh](instalar-botao-codex.sh): instalador, verificação, reaplicação segura e reversão.
- [codex-login-button.patch](codex-login-button.patch): alterações exatas dos arquivos estáticos `static/panels.js` e `static/onboarding.js`, sem segredos ou credenciais.

## Uso numa nova instalação da Hostinger / Docker Compose

Depois de instalar e iniciar o Hermes WebUI, na VPS:

```bash
git clone https://github.com/anaclaraia/ferramentas.git /tmp/ferramentas-anaclaraia
cd /tmp/ferramentas-anaclaraia/scripts/hermes-webui

# Primeiro, verificar a compatibilidade sem alterar nada:
bash instalar-botao-codex.sh --check /docker/SEU-PROJETO-HERMES

# Se a verificação passar, instalar:
bash instalar-botao-codex.sh --apply /docker/SEU-PROJETO-HERMES
```

Substitua `/docker/SEU-PROJETO-HERMES` pelo diretório real da instalação, aquele que contém `docker-compose.yml` ou `compose.yaml`.

Em seguida, entre no WebUI por **HTTPS**, abra **Preferências → Provedores → OpenAI Codex** e clique em **Entrar com Codex (ChatGPT)**. A página oficial de autorização será aberta e o código aparecerá no painel. **O proprietário precisa autorizar o login na própria conta.** Não são necessárias chaves da API OpenAI para o fluxo Codex OAuth.

**Não cole senhas, tokens, códigos de autenticação ou arquivos `auth.json` no GitHub.**

## Desfazer

```bash
bash instalar-botao-codex.sh --rollback /docker/SEU-PROJETO-HERMES
```

O script remove somente os dois mounts que criou, recria apenas o container do WebUI e conserva os arquivos de backup locais.

## Proteções

- Faz uma verificação de aplicação do patch com `--fuzz=0` e não força modificações em código incompatível.
- Não duplica o botão se o Compose já estiver configurado.
- Interrompe se outros volumes já substituírem `panels.js` ou `onboarding.js`.
- Salva backup local do Compose com permissão restrita (`0600`), pois ele pode conter informações sensíveis.
- Monta os arquivos JS personalizados em modo somente leitura (`:ro`) e não modifica o código do Hermes Agent.
- Recria apenas o serviço `hermes-webui`, após validar o Compose.
- Permite reversão sem apagar outras alterações feitas depois no Compose.
- Detecta a implementação nativa do PR oficial para evitar instalar duas vezes.

**Limite de compatibilidade:** o patch foi desenvolvido e testado contra os arquivos de **v0.52.613**. Pode aplicar em revisões próximas se as regiões modificadas forem idênticas, mas **não há garantia** de compatibilidade com toda versão nova. Se a verificação falhar, confira o PR oficial e adapte/teste o patch antes de instalar.

**Segurança:** configure HTTPS no painel antes de autenticar uma conta. No caso de múltiplos perfis/contas, prefira a implementação oficial do PR #8146, que inclui salvaguardas adicionais para associação do perfil, persistência de credenciais e concorrência. Nosso patch é um atalho de interface testado, não substitui esses controles.

## Testes realizados

- A versão local foi testada manualmente com login Codex concluído pelo operador.
- Aplicação do patch sobre os dois arquivos JS originais, com correspondência exata com a versão que funcionou.
- `node --check` para os dois arquivos JS.
- Teste do instalador com Docker simulado: **--check, --apply, execução repetida e --rollback**.
- Nenhum dado de login ou token foi armazenado neste repositório.

## Como pedir futuramente

**“Clara, instale o botão de login do Codex no novo Hermes WebUI.”**

A Clara deve identificar a VPS e o projeto Compose, inspecionar a versão instalada, executar `--check` e só então aplicar com `--apply`. Se a versão oficial já incluir o botão, não é necessário usar o patch.
