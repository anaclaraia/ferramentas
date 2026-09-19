# Diagnóstico e Correção do OpenClaw — Persona, Skills, Memória, Voz e Autogestão

## Objetivo

Diagnosticar esta instalação do OpenClaw antes de alterar qualquer configuração.

O agente deve deixar de se comportar apenas como um chatbot remoto e passar a reconhecer corretamente:
- que está rodando dentro do OpenClaw;
- quais skills estão instaladas e disponíveis;
- quais ferramentas locais realmente pode utilizar;
- sua identidade/persona;
- sua memória e arquivos de contexto;
- os recursos de terminal, arquivos e execução disponíveis;
- o pipeline de voz;
- sua capacidade real de administrar e melhorar o próprio ambiente.

IMPORTANTE: não invente capacidades. Primeiro descubra o que existe nesta instalação. Não remova nem substitua configurações que já funcionam sem antes fazer backup.

---

## 1. Descobrir a instalação real

Execute comandos de diagnóstico equivalentes aos seguintes, adaptando-os se necessário:

```bash
openclaw --version 2>/dev/null || true
which openclaw || true
node --version || true
npm --version || true
pwd
ps aux | grep -i '[o]penclaw' || true
pm2 list 2>/dev/null || true
systemctl --type=service --all | grep -i openclaw || true
```

Localize diretórios relacionados ao OpenClaw:

```bash
find /root /opt /etc -maxdepth 4 \( -iname '*openclaw*' -o -iname 'SKILL.md' \) 2>/dev/null | head -300
```

Não presuma caminhos antes de verificar.

---

## 2. Inventário das skills

Descubra onde as skills estão instaladas.

Liste todas as skills encontradas e seus respectivos arquivos `SKILL.md`.

Exemplo:

```bash
find /root/.openclaw /opt/openclaw -type f -name 'SKILL.md' 2>/dev/null
```

Depois informe:

1. quantidade total;
2. nome de cada skill;
3. caminho;
4. se a skill está apenas armazenada no disco ou realmente carregada/disponível para o agente.

Quando o usuário perguntar “quantas skills você tem?”, a resposta deve vir do inventário real do OpenClaw, e não do conhecimento genérico do modelo da OpenAI.

---

## 3. Descobrir as ferramentas locais do agente

Identifique quais ferramentas o modelo recebe em tempo de execução.

Procure recursos como:

- shell/terminal;
- execução de comandos;
- leitura de arquivos;
- gravação/edição de arquivos;
- gerenciamento de skills;
- processos;
- HTTP/web;
- memória;
- subagentes;
- TTS;
- STT;
- Telegram.

Procure configurações e código relacionados a tools/functions:

```bash
grep -RniE 'tools|function.?call|shell|exec|terminal|write_file|read_file|skill' /root/.openclaw /opt/openclaw 2>/dev/null | head -300
```

Não exponha tokens, senhas, chaves de API ou credenciais na resposta.

---

## 4. Teste obrigatório de autonomia local

Tente criar um arquivo temporário usando uma ferramenta disponibilizada ao próprio agente, não apenas descrevendo um comando para o usuário executar.

Arquivo:

```text
/tmp/teste-clara.txt
```

Conteúdo:

```text
OpenClaw conseguiu utilizar uma ferramenta local para criar este arquivo.
```

Depois:

1. leia o arquivo novamente;
2. confirme o conteúdo;
3. remova o arquivo de teste.

Se não conseguir fazer isso autonomamente, informe exatamente qual ferramenta está faltando.

Nesse caso, o problema não deve ser tratado apenas como problema de prompt ou personalidade. É necessário expor ao agente uma ferramenta segura de execução/leitura/escrita.

---

## 5. Persona e consciência do ambiente

Localize os arquivos de configuração, system prompt, persona, workspace e memória usados nesta instalação.

O agente deve saber, no mínimo:

- seu nome/persona configurada;
- que está executando através do OpenClaw;
- que a OpenAI fornece o modelo de linguagem, mas não representa todo o sistema;
- quais ferramentas estão realmente disponíveis;
- quais skills estão realmente instaladas;
- que pode consultar o ambiente antes de responder perguntas sobre suas próprias capacidades.

Não faça o agente alegar uma capacidade que não foi confirmada.

Quando uma pergunta depender do estado da VPS, consulte o estado real antes de responder.

---

## 6. Memória

Descubra como esta versão do OpenClaw implementa memória.

Procure arquivos, banco de dados ou configurações relacionados a:

```bash
find /root/.openclaw /opt/openclaw -maxdepth 5 \( -iname '*memory*' -o -iname '*.db' -o -iname '*.sqlite*' \) 2>/dev/null
```

Informe:

- mecanismo encontrado;
- localização;
- se está habilitado;
- se a memória é persistente;
- como a persona/contexto é carregada em uma nova conversa do Telegram.

Não substitua banco ou memória existente sem backup.

---

## 7. Diagnóstico da voz

O cenário atual é:

- Telegram por texto funciona;
- Telegram por áudio é transcrito localmente;
- STT local semelhante ao Whisper já está funcionando;
- Microsoft Neural/Francisca Neural está sendo usada para TTS;
- quando chega áudio, o sistema às vezes devolve texto + áudio;
- quando o usuário escreve “responda em áudio”, o modelo pode dizer incorretamente que não consegue gerar áudio.

Isso indica que STT e TTS provavelmente existem, mas a política de saída ou a ferramenta de TTS não está sendo corretamente apresentada ao modelo.

Descubra:

1. onde o Telegram recebe mensagens;
2. onde áudio é transcrito;
3. onde a resposta do modelo é processada;
4. onde o TTS é acionado;
5. qual condição decide enviar áudio;
6. se o TTS aparece como ferramenta para o modelo ou se é pós-processamento do gateway.

Procure:

```bash
grep -RniE 'telegram|voice|audio|tts|stt|whisper|edge.?tts|neural|Francisca' /root/.openclaw /opt/openclaw 2>/dev/null | head -400
```

---

## 8. Comportamento desejado para voz

Queremos suportar uma preferência persistente semelhante a:

```text
voice_reply_mode = always
```

Modos desejáveis:

```text
always
incoming_audio
text_only
```

Comportamento:

- `always`: respostas do Telegram devem incluir áudio sempre que o TTS estiver operacional;
- `incoming_audio`: responder com áudio quando a mensagem recebida for áudio;
- `text_only`: não gerar áudio automaticamente.

Se a arquitetura atual já possuir configuração equivalente, use a implementação nativa em vez de criar outra.

Se o usuário pedir explicitamente “responda em áudio”, o gateway deve acionar o TTS disponível. Essa decisão não deve depender exclusivamente de o modelo “achar” que consegue gerar áudio.

---

## 9. Autogestão controlada

O objetivo é permitir que o agente consiga realizar tarefas administrativas quando solicitado, por exemplo:

- instalar uma skill;
- atualizar uma configuração;
- criar/editar arquivos;
- verificar logs;
- diagnosticar serviços;
- reiniciar apenas o serviço necessário;
- testar a alteração;
- desfazer uma mudança se o teste falhar.

Isso NÃO significa dar liberdade irrestrita.

Antes de ações destrutivas, o agente deve:

1. identificar o arquivo/serviço;
2. criar backup;
3. aplicar mudança mínima;
4. validar sintaxe/configuração;
5. reiniciar somente se necessário;
6. verificar logs e funcionamento;
7. restaurar backup se houver falha.

Nunca revelar credenciais.

Não apagar bancos, diretórios, configurações ou serviços sem autorização explícita.

---

## 10. Atualização de skills

Descubra primeiro qual é o mecanismo oficial desta versão do OpenClaw para instalar/atualizar skills.

Não invente comandos.

Se não houver gerenciador próprio, identifique como as skills existentes foram estruturadas e proponha o procedimento compatível com essa instalação.

Depois teste apenas com uma operação não destrutiva.

---

## 11. Backup antes de mudanças

Antes de editar qualquer arquivo importante:

```bash
cp ARQUIVO ARQUIVO.bak-$(date +%Y%m%d-%H%M%S)
```

Para diretórios/configurações maiores, faça um backup adequado antes da alteração.

Não inclua arquivos contendo segredos em repositórios públicos.

---

## 12. Relatório antes da correção

Antes de realizar mudanças maiores, apresente um relatório curto contendo:

```text
OPENCLAW
Versão:
Processo/serviço:
Diretório principal:

MODELO
Provider:
Modelo configurado:

SKILLS
Quantidade:
Diretório:
Carregadas pelo agente:

FERRAMENTAS
Shell:
Leitura:
Escrita:
Execução:
Gerenciamento de skills:

MEMÓRIA
Tipo:
Persistente:
Local:

TELEGRAM
Status:

STT
Implementação:
Status:

TTS
Implementação:
Voz:
Status:

AUTOGESTÃO
Consegue criar arquivo:
Consegue ler arquivo:
Consegue executar comando:
Consegue editar configuração:
Consegue instalar skill:

PROBLEMAS ENCONTRADOS
1.
2.
3.

CORREÇÕES PROPOSTAS
1.
2.
3.
```

---

## 13. Aplicação das correções

Após o diagnóstico, faça primeiro somente correções seguras e reversíveis.

Prioridade:

1. garantir que o agente reconheça o ambiente OpenClaw;
2. disponibilizar corretamente o inventário de skills;
3. garantir acesso controlado às ferramentas locais;
4. corrigir persona/contexto;
5. validar memória;
6. corrigir a lógica do TTS;
7. implementar preferência persistente de resposta por áudio, se suportada;
8. testar autogestão;
9. validar Telegram;
10. verificar consumo de RAM e CPU após as mudanças.

A VPS possui poucos recursos. Evite instalar painéis, browsers, serviços pesados ou dependências desnecessárias.

---

## 14. Testes finais

Depois das correções, execute testes equivalentes a estes:

### Teste A
Pergunta:

```text
Quantas skills você tem instaladas e quais são?
```

A resposta deve consultar o ambiente real.

### Teste B

```text
Crie um arquivo temporário, leia o conteúdo e depois apague.
```

O agente deve executar a operação usando suas ferramentas locais.

### Teste C

```text
Qual versão do OpenClaw está rodando?
```

Consultar a instalação real.

### Teste D

```text
Responda esta mensagem em áudio.
```

O Telegram deve receber áudio através do TTS configurado.

### Teste E

Enviar uma mensagem de voz.

O fluxo deve ser:

```text
Telegram
   ↓
STT local
   ↓
OpenClaw
   ↓
modelo OpenAI
   ↓
resposta
   ↓
TTS Microsoft Neural
   ↓
Telegram
```

### Teste F

```text
Instale/ative uma skill de teste segura.
```

O agente deve descobrir o mecanismo correto, executar, validar e informar exatamente o que mudou.

---

## Resultado esperado

Ao final, esta instalação deve funcionar como um agente OpenClaw consciente do próprio ambiente, e não como uma simples janela para o modelo da OpenAI.

O modelo é o cérebro de linguagem.

O OpenClaw é o agente/orquestrador.

As skills são capacidades adicionais.

As ferramentas locais permitem agir na VPS.

A memória mantém contexto persistente.

Telegram é a interface.

STT entende a voz do usuário.

TTS produz a resposta falada.

Todas essas camadas devem estar conectadas de forma explícita, verificável, segura e compatível com a versão realmente instalada.
