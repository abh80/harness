#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/toml.sh"
. "$SCRIPT_DIR/lib/common.sh"

PATH_ARG="$PWD"; PROGRAM=""; FILTER=""
while [ $# -gt 0 ]; do
  case "$1" in
    --path) PATH_ARG="$2"; shift 2 ;;
    --all) shift ;;
    --program) PROGRAM="$2"; shift 2 ;;
    --filter) FILTER="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

fail=0
while read -r dir; do
  [ -z "$dir" ] && continue
  name="$(basename "$dir")"
  run_cmd="$(get_step "$dir" run || true)"
  [ -z "$run_cmd" ] && { result SKIP "$name" "(no run)"; continue; }
  tdir="$dir/__tests__"; [ -d "$tdir" ] || continue
  for c in "$tdir"/*/; do
    [ -d "$c" ] || continue
    cname="$(basename "$c")"
    if [ -n "$FILTER" ]; then case "$cname" in $FILTER) ;; *) continue ;; esac; fi
    expect="$c/expect.txt"; [ -f "$expect" ] || { result SKIP "$name" "$cname"; continue; }
    cmd="$run_cmd"
    [ -f "$c/args.txt" ] && cmd="$cmd $(tr '\n' ' ' < "$c/args.txt")"
    stdin=""; [ -f "$c/in.txt" ] && stdin="$c/in.txt"
    RC=0; run_step "$cmd" "$dir" "$stdin"
    ok=1
    if ! compare_files "$OUT_FILE" "$expect"; then ok=0; fi
    if [ -f "$c/expect.err.txt" ]; then
      if ! compare_files "$ERR_FILE" "$c/expect.err.txt"; then ok=0; fi
    fi
    exp_code=0; [ -f "$c/exit.txt" ] && exp_code="$(cat "$c/exit.txt" | tr -d '[:space:]')"
    [ "$RC" -ne "$exp_code" ] && { ok=0; echo "exit: expected=$exp_code actual=$RC"; }
    if [ "$ok" -eq 1 ]; then result PASS "$name" "$cname"
    else fail=$((fail+1)); result FAIL "$name" "$cname"; fi
    rm -f "$OUT_FILE" "$ERR_FILE"
  done
done < <(discover_programs "$PATH_ARG" "$PROGRAM")
exit "$fail"
