#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/toml.sh"
. "$SCRIPT_DIR/lib/common.sh"

PATH_ARG="$PWD"; PROGRAM=""; REFS=0; WHATIF=0
while [ $# -gt 0 ]; do
  case "$1" in
    --path) PATH_ARG="$2"; shift 2 ;;
    --all) shift ;;
    --program) PROGRAM="$2"; shift 2 ;;
    --refs) REFS=1; shift ;;
    --what-if) WHATIF=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

fail=0
while read -r dir; do
  name="$(basename "$dir")"
  cmd="$(get_step "$dir" clean || true)"
  if [ -n "$cmd" ]; then
    if [ "$WHATIF" -eq 1 ]; then echo "would clean: $name ($cmd)"
    else RC=0; run_step "$cmd" "$dir" ""
      if [ "$RC" -ne 0 ]; then fail=$((fail+1)); result FAIL "$name" clean
      else result PASS "$name" clean; fi
      rm -f "$OUT_FILE" "$ERR_FILE"
    fi
  fi
  if [ "$REFS" -eq 1 ]; then
    find "$dir/__tests__" -maxdepth 2 -type f \( -name 'expect.txt' -o -name 'expect.err.txt' -o -name 'exit.txt' \) 2>/dev/null | while read -r f; do
      if [ "$WHATIF" -eq 1 ]; then echo "would remove: $f"; else rm -f "$f"; fi
    done
  fi
done < <(discover_programs "$PATH_ARG" "$PROGRAM")
exit "$fail"
