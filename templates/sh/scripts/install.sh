#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/toml.sh"
. "$SCRIPT_DIR/lib/common.sh"

PATH_ARG="$PWD"; ALL=0; PROGRAM=""; RECURSE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --path) PATH_ARG="$2"; shift 2 ;;
    --all) ALL=1; shift ;;
    --program) PROGRAM="$2"; shift 2 ;;
    --recurse) RECURSE="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
if [ -n "$RECURSE" ]; then PATH_ARG="$(cd "$RECURSE" && pwd)"; ALL=1; fi

fail=0
while read -r dir; do
  [ -z "$dir" ] && continue
  name="$(basename "$dir")"
  cmd="$(get_step "$dir" install || true)"
  if [ -z "$cmd" ]; then result SKIP "$name" "(install)"; continue; fi
  RC=0; run_step "$cmd" "$dir" ""
  if [ "$RC" -ne 0 ]; then fail=$((fail+1)); result FAIL "$name" install; cat "$ERR_FILE" >&2
  else result PASS "$name" install; fi
  rm -f "$OUT_FILE" "$ERR_FILE"
done < <(discover_programs "$PATH_ARG" "$PROGRAM")
exit "$fail"
