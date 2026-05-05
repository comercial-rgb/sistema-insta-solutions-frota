#!/usr/bin/env bash
# Espelha o código da raiz do repositório em production/ (deploy legado em
# /var/www/.../production). A raiz é a fonte da verdade; rode isto após merges
# antes de empacotar ou abrir PR, depois scripts/check_production_mirror.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
MIRROR="${1:-production}"

if [[ ! -d "$MIRROR" ]]; then
  echo "Diretório espelho inexistente: $MIRROR" >&2
  exit 1
fi

RSYNC_EXCLUDES=(
  --exclude='.DS_Store'
)

sync_dir() {
  local name="$1"
  if [[ ! -d "$name" ]]; then
    echo "Aviso: sem diretório $name — ignorado." >&2
    return 0
  fi
  mkdir -p "$MIRROR/$name"
  rsync -a "${RSYNC_EXCLUDES[@]}" --delete "$name/" "$MIRROR/$name/"
  echo "OK: $name/ -> $MIRROR/$name/"
}

for d in app config db lib bin spec; do
  sync_dir "$d"
done

copy_root_file() {
  local f="$1"
  if [[ -f "$f" ]]; then
    cp "$f" "$MIRROR/$f"
    echo "OK: $f"
  fi
}

for f in Gemfile Gemfile.lock config.ru Rakefile .ruby-version package.json yarn.lock; do
  copy_root_file "$f"
done

if [[ -d public ]]; then
  sync_dir public
fi

echo "Espelho atualizado em $MIRROR (revise git diff antes do commit)."
