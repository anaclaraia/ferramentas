#!/usr/bin/env bash
# Botao Codex para Hermes WebUI, pacote de compatibilidade com WebUI v0.52.613.
# Requer Docker Compose, Python 3, patch, e acesso ao daemon Docker.
set -Eeuo pipefail

usage() {
  echo "Uso: bash $(basename "$0") --check|--apply|--rollback CAMINHO_DO_COMPOSE"
  echo "Exemplo: bash $(basename "$0") --apply /docker/hermes-webui-nova"
}

if [ "$#" -ne 2 ]; then usage; exit 2; fi
MODE="$1"
PROJECT_DIR="$2"
case "$MODE" in --check|--apply|--rollback) ;; *) usage; exit 2 ;; esac
[ -d "$PROJECT_DIR" ] || { echo "Projeto inexistente: $PROJECT_DIR" >&2; exit 1; }
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
cd "$PROJECT_DIR"
COMPOSE=""
for candidate in compose.yaml compose.yml docker-compose.yml docker-compose.yaml; do
  if [ -f "$candidate" ]; then COMPOSE="$candidate"; break; fi
done
[ -n "$COMPOSE" ] || { echo "Nao achei um arquivo Compose." >&2; exit 1; }
command -v docker >/dev/null
command -v python3 >/dev/null
[ "$MODE" = "--rollback" ] || command -v patch >/dev/null
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATCH_FILE="$SCRIPT_DIR/codex-login-button.patch"
TARGET="./customizations/codex-login-button"
PANEL_MOUNT="      - $TARGET/panels.js:/apptoo/static/panels.js:ro"
ONBOARD_MOUNT="      - $TARGET/onboarding.js:/apptoo/static/onboarding.js:ro"

docker compose -f "$COMPOSE" config --quiet
if [ "$MODE" = "--rollback" ]; then
  if ! grep -Fq -- "$PANEL_MOUNT" "$COMPOSE"; then
    echo "Nao existe o patch deste instalador no Compose. Nada a desfazer."
    exit 0
  fi
  echo "Removendo apenas os dois mounts do botao Codex..."
  ROLLBACK_BACKUP="$COMPOSE.bak-codex-rollback-$(date +%Y%m%d-%H%M%S)"
  cp -p "$COMPOSE" "$ROLLBACK_BACKUP"
  chmod 600 "$ROLLBACK_BACKUP"
  python3 - "$COMPOSE" "$PANEL_MOUNT" "$ONBOARD_MOUNT" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); original=p.read_text()
lines=original.splitlines(keepends=True)
requested={sys.argv[2],sys.argv[3]}
present={line.rstrip('\r\n') for line in lines if line.rstrip('\r\n') in requested}
if present!=requested:
    raise SystemExit("Mounts incompletos; revise manualmente, nada removido")
p.write_text(''.join(line for line in lines if line.rstrip('\r\n') not in requested))
PY
  docker compose -f "$COMPOSE" config --quiet
  docker compose -f "$COMPOSE" up -d --no-deps --force-recreate hermes-webui
  echo "Reversao efetuada. Arquivos locais de backup foram preservados."
  exit 0
fi

# Uma segunda execucao nao pode sobrepor uma instalacao ja personalizada.
if grep -Fq -- "$PANEL_MOUNT" "$COMPOSE"; then
  if grep -Fq -- "$ONBOARD_MOUNT" "$COMPOSE"; then
    echo "O botao Codex ja esta configurado neste Compose. Nada foi alterado."
    exit 0
  fi
  echo "Mount parcial do botao Codex. Revise o Compose antes de continuar." >&2
  exit 1
fi

[ -f "$PATCH_FILE" ] || { echo "Falta $PATCH_FILE (baixe o pacote completo do GitHub)." >&2; exit 1; }

CID="$(docker compose -f "$COMPOSE" ps -q hermes-webui | head -n 1)"
[ -n "$CID" ] || { echo "Container hermes-webui nao esta em execucao." >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/static"
docker cp "$CID:/app/static/panels.js" "$TMP/static/panels.js" >/dev/null
docker cp "$CID:/app/static/onboarding.js" "$TMP/static/onboarding.js" >/dev/null

if grep -Fq 'function _buildCodexOAuthLogin(p)' "$TMP/static/panels.js"; then
  echo "O Hermes ja inclui o botao oficial de login Codex. Nenhuma alteracao necessaria."
  exit 0
fi
if grep -Fq 'OX local enhancement: reuse the existing server-owned' "$TMP/static/panels.js"; then
  echo "Uma personalizacao Codex ja foi aplicada. Nao dupliquei o botao."
  exit 0
fi

echo "Verificando se o patch e compativel com esta versao do WebUI..."
(cd "$TMP" && patch --batch --fuzz=0 -p1 --dry-run < "$PATCH_FILE")
if [ "$MODE" = "--check" ]; then
  echo "Compatibilidade OK. Execute --apply para instalar; nenhum arquivo foi modificado."
  exit 0
fi

if grep -Eq '/(app|apptoo)/static/(panels|onboarding).js' "$COMPOSE"; then
  echo "O Compose ja substitui arquivos JS do WebUI. Pare para revisar os mounts." >&2
  exit 1
fi
if [ -e "$TARGET/panels.js" ] || [ -e "$TARGET/onboarding.js" ]; then
  echo "Arquivos de personalizacao anteriores encontrados. Nao sobrescrevi." >&2
  exit 1
fi

(cd "$TMP" && patch --batch --fuzz=0 -p1 < "$PATCH_FILE")
if command -v node >/dev/null; then
  node --check "$TMP/static/panels.js"
  node --check "$TMP/static/onboarding.js"
fi

# Confirme o bloco do servico antes de modificar qualquer configuracao.
python3 - "$COMPOSE" "$PANEL_MOUNT" "$ONBOARD_MOUNT" "$TMP/compose-new" <<'PY'
from pathlib import Path
import re,sys
p=Path(sys.argv[1]); text=p.read_text()
m=re.search(r'^  hermes-webui:\s*\n',text,re.M)
if not m:
    raise SystemExit("Servico hermes-webui nao encontrado; nada modificado")
rest=text[m.end():]
end=re.search(r'^(?:  [\w-]+:|networks:|volumes:|configs:|secrets:)\s*$',rest,re.M)
chunk=rest[:end.start()] if end else rest
if chunk.count("    volumes:\n")!=1:
    raise SystemExit("Estrutura de volumes desconhecida; nada modificado")
if '/app/static/panels.js' in chunk or '/app/static/onboarding.js' in chunk:
    raise SystemExit("Conflito com outro override de JS")
newchunk=chunk.replace("    volumes:\n",
                       "    volumes:\n"+sys.argv[2]+"\n"+sys.argv[3]+"\n",1)
out=text[:m.end()]+newchunk+rest[len(chunk):]
Path(sys.argv[4]).write_text(out)
PY

mkdir -p "$TARGET"
cp "$TMP/static/panels.js" "$TARGET/panels.js"
cp "$TMP/static/onboarding.js" "$TARGET/onboarding.js"
docker cp "$CID:/app/static/panels.js" "$TARGET/panels.js.original" >/dev/null
docker cp "$CID:/app/static/onboarding.js" "$TARGET/onboarding.js.original" >/dev/null
chmod 644 "$TARGET"/*.js
chmod 600 "$TARGET"/*.original
BACKUP="$COMPOSE.bak-codex-$(date +%Y%m%d-%H%M%S)"
cp -p "$COMPOSE" "$BACKUP"
chmod 600 "$BACKUP"
cp "$TMP/compose-new" "$COMPOSE"
if ! docker compose -f "$COMPOSE" config --quiet; then
  cp -p "$BACKUP" "$COMPOSE"
  echo "Compose invalido. Configuracao original restaurada." >&2
  exit 1
fi
echo "Recriando apenas o contêiner hermes-webui; o Agent fica intocado."
if ! docker compose -f "$COMPOSE" up -d --no-deps --force-recreate hermes-webui; then
  cp -p "$BACKUP" "$COMPOSE"
  docker compose -f "$COMPOSE" up -d --no-deps --force-recreate hermes-webui || true
  echo "Falha na recriacao. Compose anterior restaurado; confira o container." >&2
  exit 1
fi
NEW_CID="$(docker compose -f "$COMPOSE" ps -q hermes-webui | head -n 1)"
docker inspect "$NEW_CID" --format '{{.State.Status}}' | grep -qx 'running'
echo "Pronto. Botao Codex instalado. Atualize Preferencias > Provedores."
echo "Para reverter: bash $(basename "$0") --rollback $PROJECT_DIR"
