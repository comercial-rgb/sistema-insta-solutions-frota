#!/usr/bin/env bash
# Falha (exit 1) se production/ divergir da raiz nos diretórios espelhados.
# Uso: CI, pre-push, ou após editar só um dos lados por engano.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
MIRROR="${1:-production}"
FAIL=0

if [[ ! -d "$MIRROR" ]]; then
  echo "Diretório espelho inexistente: $MIRROR" >&2
  exit 1
fi

filter_noise() {
  grep -v '.DS_Store' || true
}

check_dir_pair() {
  local name="$1"
  if [[ ! -d "$name" ]] || [[ ! -d "$MIRROR/$name" ]]; then
    echo "SKIP (diretório ausente): $name" >&2
    return 0
  fi
  local out
  out=$(diff -rq "$name" "$MIRROR/$name" 2>/dev/null | filter_noise || true)
  if [[ -n "$out" ]]; then
    echo "--- Divergência: $name/ vs $MIRROR/$name/ ---"
    echo "$out"
    FAIL=1
  fi
}

for d in app config db lib bin spec public; do
  check_dir_pair "$d"
done

check_file_pair() {
  local f="$1"
  if [[ -f "$f" && -f "$MIRROR/$f" ]]; then
    if ! diff -q "$f" "$MIRROR/$f" >/dev/null 2>&1; then
      echo "--- Divergência: $f vs $MIRROR/$f ---"
      FAIL=1
    fi
  elif [[ -f "$f" && ! -f "$MIRROR/$f" ]]; then
    echo "--- Falta no espelho: $MIRROR/$f ---" >&2
    FAIL=1
  elif [[ ! -f "$f" && -f "$MIRROR/$f" ]]; then
    echo "--- Só no espelho (remova ou copie da raiz): $MIRROR/$f ---" >&2
    FAIL=1
  fi
}

for f in Gemfile Gemfile.lock config.ru Rakefile .ruby-version package.json yarn.lock; do
  if [[ "$f" == "yarn.lock" ]] && [[ ! -f "$f" ]]; then
    continue
  fi
  check_file_pair "$f"
done

if [[ "$FAIL" -ne 0 ]]; then
  echo >&2
  echo "Corrija com: bash scripts/sync_production_mirror.sh" >&2
  exit 1
fi

echo "OK: $MIRROR alinhado com a raiz (app, config, db, lib, bin, spec, public, Gemfile*, config.ru, Rakefile, .ruby-version, package.json, yarn.lock)."
