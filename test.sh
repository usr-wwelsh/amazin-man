#!/bin/sh
cd "$(dirname "$0")" || exit 1
fail=0
for t in *_test.lua; do
    if lua "$t" >/dev/null; then
        echo "ok   $t"
    else
        echo "FAIL $t"
        fail=1
    fi
done
exit $fail
