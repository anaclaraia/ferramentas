# Prompt para traduzir e instalar skills no OpenClaw

Acesse o repositório de destino:

https://github.com/anaclaraia/ferramentas.git

Use como origem das skills:

https://github.com/mattpocock/skills/tree/main/skills

## Tarefa

Converta todas as skills disponíveis no repositório original para português do Brasil e prepare-as para instalação no OpenClaw.

Preserve obrigatoriamente:

- nomes das pastas;
- identificadores técnicos das skills;
- nomes dos comandos;
- caminhos de arquivos;
- URLs;
- nomes de variáveis;
- blocos de código;
- scripts;
- exemplos de terminal;
- estrutura de diretórios;
- frontmatter compatível com o sistema de skills.

Traduza somente o texto explicativo, as descrições, títulos, instruções e comentários destinados ao usuário ou ao agente.

Não traduza nomes de arquivos, comandos, nomes de APIs, nomes de bibliotecas, palavras reservadas de programação ou identificadores usados por scripts.

## Compatibilidade com OpenClaw

Adapte as instruções originalmente específicas do Claude Code para o funcionamento do OpenClaw.

Quando o texto mencionar a “ferramenta Skill”, substitua por uma instrução compatível com o OpenClaw, como “ative a skill” ou “use a skill correspondente”.

Mantenha os identificadores técnicos em inglês quando eles forem usados para localizar ou ativar uma skill. Por exemplo:

- `grill-me`
- `grilling`
- `domain-modeling`
- `code-review`
- `tdd`

Não remova as skills que estiverem em desenvolvimento. Mantenha-as em uma pasta `in-progress`, como no repositório original.

## Instalação correta

O comando `cp -R skills/* ~/.openclaw/workspace/skills/` só funciona quando você já está dentro de uma pasta que contém `skills`. Executá-lo diretamente em `/root` causa o erro `cannot stat 'skills/*'`.

Depois de baixar o arquivo `openclaw-skills-ptbr.zip` para a VPS, execute:

```bash
cd /root
unzip -q openclaw-skills-ptbr.zip
mkdir -p /root/.openclaw/workspace/skills
cp -a /root/openclaw-skills-ptbr/skills/. /root/.openclaw/workspace/skills/
find /root/.openclaw/workspace/skills -name SKILL.md | wc -l
```

O último comando deve mostrar `38`.

Se o arquivo ainda estiver no computador local, envie-o para a VPS com:

```bash
scp openclaw-skills-ptbr.zip root@IP_DA_VPS:/root/
```

Substitua `IP_DA_VPS` pelo endereço real da VPS.

Não use `cp -R skills/*` antes de baixar e extrair o pacote.

## Estrutura esperada

Após a instalação, deve existir, por exemplo:

```
/root/.openclaw/workspace/skills/productivity/grill-me/SKILL.md
/root/.openclaw/workspace/skills/engineering/tdd/SKILL.md
```

Depois da cópia, reinicie o agente ou o processo do OpenClaw para que ele recarregue as skills.

Crie também um README em português com:

1. quantidade total de skills convertidas;
2. instruções de instalação;
3. lista das skills principais;
4. limitações ou adaptações necessárias no OpenClaw;
5. exemplo de reinicialização ou recarregamento das skills.

Antes de finalizar:

- valide o frontmatter de todos os arquivos `SKILL.md`;
- confirme que não existem placeholders de tradução;
- confirme que os blocos de código permanecem intactos;
- confirme que todas as referências internas continuam apontando para arquivos existentes;
- não envie nenhuma campanha, mensagem ou alteração fora deste repositório.
