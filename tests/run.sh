#!/bin/sh
cd "$(dirname "$0")/.." || exit 1
export LUA_PATH="./?.lua;;"
fail=0
for t in tests/*_test.lua; do
    if ${LUA:-lua} "$t" >/dev/null; then
        echo "ok   $t"
    else
        echo "FAIL $t"
        fail=1
    fi
done
exit $fail
