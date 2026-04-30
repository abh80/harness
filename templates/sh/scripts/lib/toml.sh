#!/usr/bin/env bash
# usage: parse_harness_toml <file>
# prints lines: <key>=<value>
parse_harness_toml() {
  local file="$1"
  awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=/ {
      key=$1
      sub(/^[[:space:]]*/,"",key); sub(/[[:space:]]*$/,"",key)
      val=$0
      sub(/^[^=]*=[[:space:]]*/,"",val)
      # strip quotes
      if (match(val, /^"[^"]*"/)) { val=substr(val, RSTART+1, RLENGTH-2) }
      else if (match(val, /^'\''[^'\'']*'\''/)) { val=substr(val, RSTART+1, RLENGTH-2) }
      else { sub(/[[:space:]]+#.*$/,"",val) }
      print key "=" val
    }
  ' "$file"
}

# usage: toml_get <file> <key>
toml_get() {
  parse_harness_toml "$1" | awk -F= -v k="$2" '$1==k { sub(/^[^=]*=/,""); print; exit }'
}
