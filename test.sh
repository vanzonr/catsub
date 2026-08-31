#!/usr/bin/env bash

set -u

BIN="$(cd "$(dirname "$0")" && pwd)/catsub"

fail() {
  echo "FAIL: $1" >&2
  echo "  expected: $2" >&2
  echo "  actual:   $3" >&2
  exit 1
}

check_eq() {
  local name="$1"
  local expected="$2"
  local actual="$3"
  if [[ "$actual" != "$expected" ]]; then
    fail "$name" "$expected" "$actual"
  fi
  echo "PASS: $name"
}

check_contains() {
  local name="$1"
  local needle="$2"
  local haystack="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    fail "$name" "contains: $needle" "$haystack"
  fi
  echo "PASS: $name"
}

# 1. basic substitution
check_eq "basic substitution" "Hi world" "$(echo '%HELLO %UNIVERSE' | "$BIN" %HELLO Hi %UNIVERSE world)"

# 2. substring replacement repeats the word
check_eq "substring repeat" "unkind untidy" "$(echo 'un%X' | "$BIN" %X kind tidy)"

# 3. combinatorial substitution within a word
check_eq "combinatorics" "a,c a,d b,c b,d" "$(echo '%X,%Y' | "$BIN" %X a b %Y c d)"

# 4. custom separator using -d
check_eq "custom separator" "a,b" "$(echo '%X' | "$BIN" -d, %X a b)"

# 5. newline separator using -D
check_eq "newline separator" $'a\nb' "$(echo '%X' | "$BIN" -D %X a b)"

# 6. escaped percent stays literal without -u
check_eq "escaped percent literal" "\\%" "$(echo '\%' | "$BIN" %X a)"

# 7. escaped percent becomes literal % with -u
check_eq "escaped percent unescape" "%" "$(echo '\%' | "$BIN" -u %X a)"

# 8. longest variable name wins
check_eq "longest variable wins" "bar foo" "$(echo '%HELLOWORLD %HELLO' | "$BIN" %HELLO foo %HELLOWORLD bar)"

# 9. reads template from a file
check_eq "file template" "a b" "$(tmpfile=$(mktemp) && printf '%s\n' '%X %Y' > "$tmpfile" && "$BIN" "$tmpfile" %X a %Y b && rm -f "$tmpfile")"

# 10. reads substitution values from a file, one per line
check_eq "file substitution values" "red blue" "$(values_file=$(mktemp) && printf '%s\n' 'red' 'blue' > "$values_file" && echo '%X' | "$BIN" %X @file:"$values_file" && rm -f "$values_file")"

# 11. multiple values with quoting preserve spaces
check_eq "quoted values" "a b,c d" "$(echo '%X,%Y' | "$BIN" %X 'a b' %Y 'c d')"

# 12. a missing @file source should fail clearly
if echo '%X' | "$BIN" %X @file:/no/such/file >/dev/null 2>&1; then
  fail "missing @file source" "non-zero exit" "zero exit"
fi

# 13. stats report unused variables on stderr
stderr="$(echo '%X %Y' | "$BIN" -s %X a %Z b 2>&1 >/dev/null)"
check_contains "stats report unused var" "%Z" "$stderr"
check_contains "stats report unsubstituted var" "%Y" "$stderr"

# 14. help exits successfully and mentions usage
help_output="$($BIN --help 2>&1)"
check_contains "help output" "Usage:" "$help_output"

# 15. invalid option exits non-zero
if "$BIN" --bad-option >/dev/null 2>&1; then
  fail "bad option" "non-zero exit" "zero exit"
fi

echo "All tests passed."
