#!/usr/bin/env bash
# Copyright (c) 2018-2026 Ramses van Zon

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

expect_fail() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    fail "$name" "non-zero exit" "zero exit"
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

# 10. reads substitution values from a file, one per line, when it is inside the current directory
check_eq "file substitution values" "red blue" "$(values_file=$(mktemp "${PWD}/catsub-values.XXXXXX") && printf '%s\n' 'red' 'blue' > "$values_file" && echo '%X' | "$BIN" %X @file:"$values_file" && rm -f "$values_file")"

# 11. accepts a user-owned file in /tmp, if /tmp exists
if [[ -d /tmp ]]; then
  check_eq "tmp file source" "alpha beta" "$(tmpfile=$(mktemp /tmp/catsub-values.XXXXXX) && printf '%s\n' 'alpha' 'beta' > "$tmpfile" && echo '%X' | "$BIN" %X @file:"$tmpfile" && rm -f "$tmpfile")"
else
  echo "WARNING: /tmp does not exist; skipping tmp file source test." >&2
fi

# 12. accepts a user-owned file in /dev/shm, if /dev/shm exists
if [[ -d /dev/shm ]]; then
  check_eq "dev-shm file source" "gamma delta" "$(tmpfile=$(mktemp /dev/shm/catsub-values.XXXXXX) && printf '%s\n' 'gamma' 'delta' > "$tmpfile" && echo '%X' | "$BIN" %X @file:"$tmpfile" && rm -f "$tmpfile")"
else
  echo "WARNING: /dev/shm does not exist; skipping dev-shm file source test." >&2
fi

# 13. uses a template directory as an allowed source root
check_eq "template-dir file source" "alpha beta" "$(tmpdir=$(mktemp -d) && printf '%s\n' 'alpha' 'beta' > "$tmpdir/vals.txt" && printf '%s\n' '%X' > "$tmpdir/tmpl.txt" && "$BIN" "$tmpdir/tmpl.txt" %X @file:"$tmpdir/vals.txt" && rm -rf "$tmpdir")"

# 14. percent-prefixed file imports accept user-owned files in /tmp
if [[ -d /tmp ]]; then
  check_eq "percent file import from tmp" "alpha beta" "$(tmpfile=$(mktemp /tmp/catsub-percent-values.XXXXXX) && printf '%s\n' '%X' 'alpha' 'beta' > "$tmpfile" && echo '%X' | "$BIN" %@file:"$tmpfile" && rm -f "$tmpfile")"
  check_eq "percent file import preserves spaces" "alpha beta" "$(tmpfile=$(mktemp /tmp/catsub-percent-values.XXXXXX) && printf '%s\n' '%X' 'alpha beta' > "$tmpfile" && echo '%X' | "$BIN" -d, %@file:"$tmpfile" && rm -f "$tmpfile")"
  check_eq "percent file import preserves lines" "alpha beta,gamma delta" "$(tmpfile=$(mktemp /tmp/catsub-percent-values.XXXXXX) && printf '%s\n' '%X' 'alpha beta' 'gamma delta' > "$tmpfile" && echo '%X' | "$BIN" -d, %@file:"$tmpfile" && rm -f "$tmpfile")"
  check_eq "percent file import splits with -E" "alpha,beta" "$(tmpfile=$(mktemp /tmp/catsub-percent-values.XXXXXX) && printf '%s\n' '%X' 'alpha beta' > "$tmpfile" && echo '%X' | "$BIN" -E -d, %@file:"$tmpfile" && rm -f "$tmpfile")"
  check_eq "percent file import splits lines with -E" "alpha,beta,gamma,delta" "$(tmpfile=$(mktemp /tmp/catsub-percent-values.XXXXXX) && printf '%s\n' '%X' 'alpha beta' 'gamma delta' > "$tmpfile" && echo '%X' | "$BIN" -E -d, %@file:"$tmpfile" && rm -f "$tmpfile")"
  invalid_percent_file=$(mktemp /tmp/catsub-percent-values.XXXXXX)
  printf '%s\n' 'alpha' > "$invalid_percent_file"
  expect_fail "percent file import requires leading percent" bash -c "echo '%X' | \"$BIN\" %X %@file:\"$invalid_percent_file\""
  rm -f "$invalid_percent_file"
  invalid_percent_file=$(mktemp /tmp/catsub-percent-values.XXXXXX)
  printf '%s\n' '%X' 'alpha' > "$invalid_percent_file"
  expect_fail "value after percent file requires leading percent" bash -c "echo '%X' | \"$BIN\" %@file:\"$invalid_percent_file\" bad"
  rm -f "$invalid_percent_file"
else
  echo "WARNING: /tmp does not exist; skipping percent file import test." >&2
fi

# 15. percent-prefixed file imports accept user-owned files in /dev/shm
if [[ -d /dev/shm ]]; then
  check_eq "percent file import from dev-shm" "gamma delta" "$(tmpfile=$(mktemp /dev/shm/catsub-percent-values.XXXXXX) && printf '%s\n' '%X' 'gamma' 'delta' > "$tmpfile" && echo '%X' | "$BIN" %@file:"$tmpfile" && rm -f "$tmpfile")"
else
  echo "WARNING: /dev/shm does not exist; skipping percent file import test." >&2
fi

# 14. multiple values with quoting preserve spaces
check_eq "quoted values" "a b,c d" "$(echo '%X,%Y' | "$BIN" %X 'a b' %Y 'c d')"

# 14. a missing @file source should fail clearly
expect_fail "missing @file source" bash -c "echo '%X' | \"$BIN\" %X @file:/no/such/file"

# 15. an empty @file target should fail clearly
expect_fail "empty @file target" bash -c "echo '%X' | \"$BIN\" %X @file:"

# 16. a directory is not accepted as a @file source
expect_fail "directory @file source" bash -c "echo '%X' | \"$BIN\" %X @file:$(mktemp -d)"

# 17. a file outside the allowed directories is rejected
expect_fail "outside-worktree @file source" bash -c "echo '%X' | \"$BIN\" %X @file:/etc/hosts"

# 18. stats report unused variables on stderr
stderr="$(echo '%X %Y' | "$BIN" -s %X a %Z b 2>&1 >/dev/null)"
check_contains "stats report unused var" "%Z" "$stderr"
check_contains "stats report unsubstituted var" "%Y" "$stderr"

# 19. help exits successfully and mentions usage
help_output="$($BIN --help 2>&1)"
check_contains "help output" "Usage:" "$help_output"

# 20. -h is equivalent to --help
help_short_output="$($BIN -h 2>&1)"
check_contains "short help output" "Usage:" "$help_short_output"

# 21. invalid option exits non-zero
expect_fail "invalid option" bash -c "\"$BIN\" --bad-option"

if command -v python2 >/dev/null 2>&1; then
  unicode_value="$(printf '\303\251')"
  unicode_error="catsub does not support unicode when used with python version < 3."

  # 22. Python 2 rejects non-ASCII command-line values clearly
  if stderr="$(LC_ALL=C.UTF-8 python2 "$BIN" %X "$unicode_value" </dev/null 2>&1 >/dev/null)"; then
    fail "Python 2 command-line unicode" "non-zero exit" "zero exit"
  fi
  check_contains "Python 2 command-line unicode" "$unicode_error" "$stderr"

  # 23. Python 2 rejects non-ASCII template input clearly
  if stderr="$(printf '%s\n' "$unicode_value %X" | LC_ALL=C.UTF-8 python2 "$BIN" %X value 2>&1 >/dev/null)"; then
    fail "Python 2 template unicode" "non-zero exit" "zero exit"
  fi
  check_contains "Python 2 template unicode" "$unicode_error" "$stderr"
else
  echo "WARNING: python2 is unavailable; skipping Python 2 unicode tests." >&2
fi

echo "All tests passed."
