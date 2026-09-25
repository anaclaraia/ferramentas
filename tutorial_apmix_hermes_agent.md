# Tutorial completo: conectar a APMix ao Hermes Agent

## Objetivo

Configurar o Hermes Agent para usar os modelos LLM disponíveis na conta APMix através de uma API compatível com OpenAI.

Endpoint principal:

```text
https://api.apmix.ai/v1
```

Modelos atualmente identificados na conta:

```text
deepseek-v4-flash-free
gpt-6-luna-free
```

Modelo principal recomendado inicialmente:

```text
gpt-6-luna-free
```

> IMPORTANTE: nunca grave a chave real em GitHub, documentos públicos, logs, prints ou mensagens.
> Use a chave completa somente diretamente na VPS durante a configuração.

---

# 1. Dados necessários

Antes de começar, tenha em mãos:

```text
APMIX_BASE_URL=https://api.apmix.ai/v1
APMIX_API_KEY=apx_live_SUA_CHAVE_COMPLETA
MODELO_PRINCIPAL=gpt-6-luna-free
MODELO_ALTERNATIVO=deepseek-v4-flash-free
```

A chave real deve substituir:

```text
apx_live_SUA_CHAVE_COMPLETA
```

---

# 2. Confirmar usuário do Hermes

O Hermes desta VPS roda com o usuário:

```text
hermes
```

Verifique:

```bash
id hermes
```

Também confirme o diretório:

```bash
ls -la /home/hermes/.hermes
```

---

# 3. Fazer backup da configuração atual

Antes de qualquer alteração, crie backup.

```bash
sudo -u hermes -H cp /home/hermes/.hermes/config.yaml \
  /home/hermes/.hermes/config.yaml.backup-$(date +%Y%m%d-%H%M%S)
```

Se existir `.env`, faça backup também:

```bash
if [ -f /home/hermes/.hermes/.env ]; then
  sudo -u hermes -H cp /home/hermes/.hermes/.env \
    /home/hermes/.hermes/.env.backup-$(date +%Y%m%d-%H%M%S)
fi
```

Confira:

```bash
ls -lh /home/hermes/.hermes/
```

---

# 4. Testar a chave APMix

Execute:

```bash
curl https://api.apmix.ai/v1/models \
  -H "Authorization: Bearer apx_live_SUA_CHAVE_COMPLETA"
```

O retorno esperado é semelhante a:

```json
{
  "object": "list",
  "data": [
    {
      "id": "deepseek-v4-flash-free",
      "object": "model",
      "owned_by": "deepseek",
      "display_name": "DeepSeek V4 Flash Free",
      "context_window": 1048576,
      "plan": "free"
    },
    {
      "id": "gpt-6-luna-free",
      "object": "model",
      "owned_by": "openai",
      "display_name": "GPT 6 Luna Free",
      "context_window": 1050000,
      "plan": "free"
    }
  ]
}
```

Se isso funcionar, a chave APMix e a URL estão corretas.

---

# 5. Testar diretamente o modelo GPT 6 Luna Free

Antes de configurar o Hermes, valide a geração de texto diretamente pela APMix:

```bash
curl https://api.apmix.ai/v1/chat/completions \
  -H "Authorization: Bearer apx_live_SUA_CHAVE_COMPLETA" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-6-luna-free",
    "messages": [
      {
        "role": "user",
        "content": "Responda somente: APMix funcionando"
      }
    ]
  }'
```

Procure na resposta algo semelhante a:

```text
APMix funcionando
```

Se houver erro HTTP 401:

```text
A chave está incorreta, expirada ou não foi aceita.
```

Se houver erro relacionado a modelo:

```text
Confirme novamente o ID usando /v1/models.
```

---

# 6. Testar também o DeepSeek

Execute:

```bash
curl https://api.apmix.ai/v1/chat/completions \
  -H "Authorization: Bearer apx_live_SUA_CHAVE_COMPLETA" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-v4-flash-free",
    "messages": [
      {
        "role": "user",
        "content": "Responda somente: DeepSeek funcionando"
      }
    ]
  }'
```

Assim serão validados os dois modelos antes de alterar o Hermes.

---

# 7. Configuração preferencial pelo próprio Hermes

Entre no usuário do Hermes:

```bash
sudo -u hermes -H bash
```

Confirme:

```bash
whoami
```

O resultado deve ser:

```text
hermes
```

Agora execute:

```bash
hermes model
```

No assistente interativo, escolha uma opção equivalente a:

```text
Custom endpoint
```

ou:

```text
Custom provider
```

ou:

```text
OpenAI-compatible endpoint
```

Os nomes podem variar conforme a versão instalada.

---

# 8. Valores a informar no assistente

Quando o Hermes solicitar a URL:

```text
Base URL
```

informe:

```text
https://api.apmix.ai/v1
```

Quando solicitar a API Key:

```text
API Key
```

informe:

```text
apx_live_SUA_CHAVE_COMPLETA
```

Quando solicitar o modelo:

```text
Model
```

informe:

```text
gpt-6-luna-free
```

Se perguntar pelo tipo de API ou transporte, escolha:

```text
chat_completions
```

ou a opção equivalente a:

```text
OpenAI Chat Completions
```

Se solicitar tamanho de contexto:

```text
1050000
```

Caso o Hermes suporte detecção automática, esse campo também pode ser deixado em branco.

---

# 9. Confirmar configuração salva

Saia do shell do usuário `hermes`:

```bash
exit
```

Depois visualize:

```bash
sudo -u hermes -H cat /home/hermes/.hermes/config.yaml
```

A configuração deve conter referências equivalentes a:

```yaml
model:
  default: gpt-6-luna-free
  provider: custom
  base_url: https://api.apmix.ai/v1
```

A estrutura exata pode variar conforme a versão do Hermes.

Não altere o YAML manualmente se o `hermes model` já tiver feito a configuração corretamente.

---

# 10. Forma mais segura de armazenar a chave

Se a versão instalada do Hermes aceitar variável de ambiente para provedor customizado, prefira armazenar a chave em:

```text
/home/hermes/.hermes/.env
```

Edite:

```bash
sudo -u hermes -H nano /home/hermes/.hermes/.env
```

Adicione:

```bash
APMIX_API_KEY=apx_live_SUA_CHAVE_COMPLETA
```

Depois proteja:

```bash
chown hermes:hermes /home/hermes/.hermes/.env
chmod 600 /home/hermes/.hermes/.env
```

Confirme:

```bash
ls -l /home/hermes/.hermes/.env
```

A permissão esperada é semelhante a:

```text
-rw------- hermes hermes
```

Não mover a chave para o `.env` manualmente até confirmar que a versão atual do Hermes suporta essa variável para o provedor configurado.

---

# 11. Iniciar o Hermes para teste

Execute:

```bash
sudo -u hermes -H hermes
```

Faça uma pergunta simples:

```text
Responda apenas com o nome do modelo que você está usando.
```

Em seguida:

```text
Responda: conexão APMix ativa.
```

Se o modelo responder normalmente, a conexão básica está concluída.

---

# 12. Testar ferramentas do Hermes

Depois do teste de texto, valide se o agente continua tendo acesso às ferramentas.

Peça algo seguro e simples, por exemplo:

```text
Mostre a data e hora atual do sistema.
```

Ou:

```text
Liste os arquivos do diretório de trabalho sem alterar nada.
```

O objetivo é confirmar que a troca de LLM não prejudicou a camada de ferramentas do Hermes.

---

# 13. Configurar o modelo DeepSeek como alternativa

A conta possui também:

```text
deepseek-v4-flash-free
```

Se o Hermes permitir troca dinâmica de modelo, tente no chat:

```text
/model
```

e procure o modelo:

```text
deepseek-v4-flash-free
```

Em algumas versões de endpoint customizado também pode funcionar algo equivalente a:

```text
/model custom:deepseek-v4-flash-free
```

Não assumir que esse comando existe sem conferir a listagem apresentada pelo próprio `/model`.

---

# 14. Modelo principal recomendado

Inicialmente usar:

```text
gpt-6-luna-free
```

Modelo de contingência:

```text
deepseek-v4-flash-free
```

Estratégia:

```text
Principal:
gpt-6-luna-free

Fallback manual:
deepseek-v4-flash-free
```

Não criar fallback automático sem confirmar que a versão do Hermes suporta múltiplos modelos/provedores dessa forma.

---

# 15. Reiniciar os serviços do Hermes, se necessário

Primeiro descubra os serviços:

```bash
systemctl list-units --type=service | grep -i hermes
```

E também:

```bash
systemctl --user -M hermes@ list-units --type=service 2>/dev/null | grep -i hermes
```

Se os serviços conhecidos forem:

```text
hermes-dashboard.service
hermes-gateway.service
```

reinicie somente os que realmente existirem:

```bash
systemctl restart hermes-dashboard.service
```

```bash
systemctl restart hermes-gateway.service
```

Caso sejam serviços de usuário do `hermes`, utilize o método correspondente à instalação existente.

Nunca executar `systemctl restart` em um nome inventado.

---

# 16. Verificar status após reiniciar

Execute:

```bash
systemctl status hermes-dashboard.service --no-pager
```

e:

```bash
systemctl status hermes-gateway.service --no-pager
```

Se forem serviços de usuário, verificar pelo contexto correto do usuário `hermes`.

Também confira processos:

```bash
ps aux | grep -i hermes
```

---

# 17. Consultar logs se houver erro

Para serviços systemd:

```bash
journalctl -u hermes-dashboard.service -n 100 --no-pager
```

```bash
journalctl -u hermes-gateway.service -n 100 --no-pager
```

Para acompanhar em tempo real:

```bash
journalctl -u hermes-gateway.service -f
```

Não publicar logs contendo:

```text
Authorization
Bearer
API_KEY
apx_live_
tokens
cookies
```

---

# 18. Diagnóstico de erros comuns

## Erro 401

Sintoma:

```text
401 Unauthorized
```

Ação:

1. Verificar se a chave está correta.
2. Verificar se não há espaços antes/depois da chave.
3. Testar novamente `/v1/models`.

---

## Erro 404

Sintoma:

```text
404 Not Found
```

Ação:

Confirmar que a URL usada é:

```text
https://api.apmix.ai/v1
```

e não apenas:

```text
https://api.apmix.ai
```

---

## Modelo não encontrado

Sintoma:

```text
model not found
```

Execute:

```bash
curl https://api.apmix.ai/v1/models \
  -H "Authorization: Bearer apx_live_SUA_CHAVE_COMPLETA"
```

Use exatamente o valor retornado no campo:

```text
id
```

---

## Chat completions não suportado

Se houver erro envolvendo endpoint ou formato, teste diretamente:

```bash
curl https://api.apmix.ai/v1/chat/completions \
  -H "Authorization: Bearer apx_live_SUA_CHAVE_COMPLETA" \
  -H "Content-Type: application/json" \
  -d '{
    "model":"gpt-6-luna-free",
    "messages":[
      {"role":"user","content":"teste"}
    ]
  }'
```

Se esse comando funcionar, o problema está na configuração do Hermes e não na APMix.

---

# 19. Rollback

Se o Hermes parar de funcionar após a alteração, não apagar nada.

Liste os backups:

```bash
ls -lt /home/hermes/.hermes/config.yaml.backup-*
```

Identifique o backup mais recente.

Então restaure:

```bash
cp /home/hermes/.hermes/config.yaml.backup-AAAAmmdd-HHMMSS \
   /home/hermes/.hermes/config.yaml
```

Depois:

```bash
chown hermes:hermes /home/hermes/.hermes/config.yaml
```

Reinicie apenas os serviços Hermes existentes na máquina.

---

# 20. Regras para a Clara Hermes executar esta tarefa sozinha

A agente deve obedecer estas regras:

1. Fazer backup antes de qualquer alteração.
2. Nunca apagar a configuração original sem backup.
3. Nunca exibir a chave APMix completa nos logs ou respostas.
4. Nunca salvar a chave em GitHub.
5. Nunca publicar o `.env`.
6. Testar `/v1/models` antes de configurar.
7. Testar `/v1/chat/completions` antes de alterar o Hermes.
8. Preferir o assistente oficial `hermes model`.
9. Não inventar campos YAML.
10. Não substituir configurações existentes que não estejam relacionadas ao provedor de LLM.
11. Não alterar Telegram, Dashboard, Gateway, Listmonk, Vault ou outros serviços durante esta tarefa.
12. Após configurar, testar texto e ferramentas.
13. Se houver erro, consultar logs antes de fazer novas alterações.
14. Se a configuração quebrar o Hermes, restaurar o backup.
15. Ao concluir, apresentar um relatório sem revelar segredos.

---

# 21. Prompt operacional para a Clara Hermes Agent

Use o bloco abaixo como instrução direta para o agente:

```text
Você está autorizada a configurar a integração APMix no Hermes Agent desta VPS.

Objetivo:
usar a API APMix como provedor compatível com OpenAI.

Endpoint:
https://api.apmix.ai/v1

Modelo principal:
gpt-6-luna-free

Modelo alternativo:
deepseek-v4-flash-free

A chave APMix deverá ser obtida de forma segura do ambiente ou fornecida diretamente pelo administrador. Nunca exiba a chave completa em respostas, logs públicos, GitHub ou documentação.

Procedimento obrigatório:

1. Identifique a versão atual do Hermes.
2. Confirme o usuário e os diretórios usados pela instalação.
3. Faça backup de /home/hermes/.hermes/config.yaml e de qualquer arquivo de ambiente relacionado.
4. Teste GET https://api.apmix.ai/v1/models usando Bearer authentication.
5. Confirme que gpt-6-luna-free e/ou deepseek-v4-flash-free estão disponíveis.
6. Teste POST /v1/chat/completions com gpt-6-luna-free.
7. Se o teste funcionar, configure a APMix usando preferencialmente o comando oficial:
   hermes model
8. Configure:
   Base URL: https://api.apmix.ai/v1
   Model: gpt-6-luna-free
   API mode: OpenAI Chat Completions / chat_completions, se solicitado.
   Context window: 1050000, somente se o Hermes solicitar e não fizer detecção automática.
9. Não invente estrutura YAML. Se for necessário editar manualmente, primeiro examine a estrutura e documentação da versão instalada.
10. Prefira armazenar a chave em arquivo .env protegido por chmod 600 se a versão atual suportar isso.
11. Reinicie somente os serviços Hermes que realmente existirem.
12. Valide o status dos serviços.
13. Faça um teste de conversa.
14. Faça um teste simples de ferramenta.
15. Confirme que Telegram, Dashboard e Gateway continuam funcionando.
16. Caso a alteração provoque falha, restaure o backup.
17. Ao terminar, gere um relatório com:
    - provedor configurado
    - endpoint
    - modelo principal
    - modelo alternativo disponível
    - testes realizados
    - serviços reiniciados
    - resultado final
    - eventuais erros encontrados

Nunca revelar a chave APMix no relatório.

Não alterar nenhuma integração não relacionada a esta tarefa.
```

---

# 22. Resultado esperado

Ao final, a arquitetura deve ficar:

```text
Usuário
   │
   ▼
Hermes Agent
   │
   ▼
APMix
   │
   ├── gpt-6-luna-free
   │
   └── deepseek-v4-flash-free
```

A Clara Hermes continua responsável pelas ferramentas, memória, integrações e automações.

A APMix passa a ser o gateway para os modelos de linguagem.

---

# Checklist final

```text
[ ] Backup criado
[ ] Chave APMix validada
[ ] /v1/models funcionando
[ ] gpt-6-luna-free disponível
[ ] deepseek-v4-flash-free disponível
[ ] /v1/chat/completions funcionando
[ ] APMix configurada no Hermes
[ ] Modelo principal selecionado
[ ] Hermes inicia normalmente
[ ] Conversa funcionando
[ ] Ferramentas funcionando
[ ] Gateway funcionando
[ ] Dashboard funcionando
[ ] Telegram funcionando
[ ] Nenhuma chave exposta
[ ] Relatório final produzido
```
