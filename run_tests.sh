#!/bin/bash
PASS=0
FAIL=0

run_test() {
    file=$1
    echo -n "Testing $file... "
    if ./_build/src/main.native run "$file" > /dev/null 2>&1; then
        echo "PASS"
        PASS=$((PASS+1))
    else
        echo "FAIL"
        echo "Error output:"
        ./_build/src/main.native run "$file" 2>&1 | sed 's/^/  /'
        FAIL=$((FAIL+1))
    fi
}

echo "Running tests..."
echo "----------------"

for f in examples/*.vorlang; do
    [ -e "$f" ] || continue
    # Skip non-test files if necessary, or just run everything.
    # debug_v2.vorlang might be a partial file, but let's try running it.
    run_test "$f"
done

for f in stdlib/tests/*.vorlang; do
    [ -e "$f" ] || continue
    run_test "$f"
done

echo "----------------"
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [ $FAIL -eq 0 ]; then
    echo "All tests passed!"
    exit 0
else
    echo "Some tests failed."
    exit 1
fi
