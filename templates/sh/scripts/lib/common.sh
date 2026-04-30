#!/usr/bin/env bash
set -euo pipefail

# discover_programs <root> [program-name]
discover_programs() {
  local root="$1" want="${2:-}"
  find "$root" -type d 2>/dev/null | while read -r d; do
    local has=0
    [ -f "$d/harness.toml" ] && has=1
    for s in install build run clean; do
      [ -f "$d/$s.sh" ] && has=1
    done
    if [ "$has" -eq 1 ]; then
      local name; name="$(basename "$d")"
      [ -n "$want" ] && [ "$name" != "$want" ] && continue
      echo "$d"
    fi
  done
}

# get_step <program-dir> <step>  -> prints command (empty if absent)
get_step() {
  local dir="$1" step="$2"
  if [ -f "$dir/harness.toml" ]; then
    toml_get "$dir/harness.toml" "$step"
  elif [ -f "$dir/$step.sh" ]; then
    echo "bash $dir/$step.sh"
  fi
}

# run_step <cmd> <cwd> <stdin-file-or-empty> -> sets RC, OUT_FILE, ERR_FILE
run_step() {
  local cmd="$1" cwd="$2" stdin="$3"
  OUT_FILE="$(mktemp)"; ERR_FILE="$(mktemp)"
  if [ -n "$stdin" ] && [ -f "$stdin" ]; then
    ( cd "$cwd" && bash -c "$cmd" < "$stdin" > "$OUT_FILE" 2> "$ERR_FILE" ) || RC=$?
  else
    ( cd "$cwd" && bash -c "$cmd" </dev/null > "$OUT_FILE" 2> "$ERR_FILE" ) || RC=$?
  fi
  RC="${RC:-0}"
}

# compare_files <actual> <expected> -> RC 0 match, 1 diff (and prints first 20 diff lines)
compare_files() {
  if diff -q "$1" "$2" >/dev/null 2>&1; then return 0; fi
  diff -u "$2" "$1" | head -n 22
  return 1
}

c_red()   { printf '\033[31m%s\033[0m\n' "$*"; }
c_green() { printf '\033[32m%s\033[0m\n' "$*"; }
c_gray()  { printf '\033[90m%s\033[0m\n' "$*"; }
c_cyan()  { printf '\033[36m%s\033[0m\n' "$*"; }

result() { # tag prog case
  case "$1" in
    PASS) c_green "[PASS] $2/$3" ;;
    FAIL) c_red   "[FAIL] $2/$3" ;;
    SKIP) c_gray  "[SKIP] $2/$3" ;;
    REC)  c_cyan  "[REC]  $2/$3" ;;
    *)    echo   "[$1] $2/$3" ;;
  esac
}
