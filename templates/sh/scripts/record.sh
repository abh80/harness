#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/toml.sh"
. "$SCRIPT_DIR/lib/common.sh"

PATH_ARG="$PWD"; PROGRAM=""; FILTER=""; RECURSE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --path) PATH_ARG="$2"; shift 2 ;;
    --all) shift ;;
    --program) PROGRAM="$2"; shift 2 ;;
    --filter) FILTER="$2"; shift 2 ;;
    --recurse) RECURSE="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
if [ -n "$RECURSE" ]; then PATH_ARG="$(cd "$RECURSE" && pwd)"; fi

while read -r dir; do
  [ -z "$dir" ] && continue
  name="$(basename "$dir")"
  run_cmd="$(get_step "$dir" run || true)"
  [ -z "$run_cmd" ] && continue
  tdir="$dir/__tests__"; [ -d "$tdir" ] || continue
  for c in "$tdir"/*/; do
    cname="$(basename "$c")"
    if [ -n "$FILTER" ]; then case "$cname" in $FILTER) ;; *) continue ;; esac; fi
    cmd="$run_cmd"
    [ -f "$c/args.txt" ] && cmd="$cmd $(tr '\n' ' ' < "$c/args.txt")"
    stdin=""; [ -f "$c/in.txt" ] && stdin="$c/in.txt"
    RC=0; run_step "$cmd" "$dir" "$stdin"
    cp "$OUT_FILE" "$c/expect.txt"
    if [ -s "$ERR_FILE" ]; then cp "$ERR_FILE" "$c/expect.err.txt"
    else rm -f "$c/expect.err.txt"; fi
    if [ "$RC" -ne 0 ]; then echo "$RC" > "$c/exit.txt"
    else rm -f "$c/exit.txt"; fi
    result REC "$name" "$cname"
    rm -f "$OUT_FILE" "$ERR_FILE"
  done
done < <(discover_programs "$PATH_ARG" "$PROGRAM")
