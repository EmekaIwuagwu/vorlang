#!/bin/bash
# Vorlang Compiler Test Suite
# Tests all examples and stdlib tests

echo "========================================="
echo "Vorlang Compiler Test Suite"
echo "========================================="
echo ""

PASS=0
FAIL=0
TOTAL=0

# Function to run a test
run_test() {
    local file=$1
    local name=$(basename "$file" .vorlang)
    TOTAL=$((TOTAL + 1))
    
    echo -n "Testing $name... "
    
    if ./vorlangc run "$file" > /dev/null 2>&1; then
        echo "✓ PASS"
        PASS=$((PASS + 1))
    else
        echo "✗ FAIL"
        FAIL=$((FAIL + 1))
        echo "  Error output:"
        ./vorlangc run "$file" 2>&1 | sed 's/^/    /'
    fi
}

# Test examples
echo "Testing Examples:"
echo "-----------------"
for file in examples/*.vorlang; do
    run_test "$file"
done

echo ""
echo "Testing Standard Library:"
echo "-------------------------"
for file in stdlib/tests/*.vorlang; do
    run_test "$file"
done

echo ""
echo "Testing Root Tests:"
echo "-------------------"
# Use ls to avoid failing if no match (though we know there are matches)
for file in test_*.vorlang; do 
    [ -e "$file" ] || continue
    run_test "$file"
done

echo ""
echo "Testing Additional Tests:"
echo "-----------------------"
for file in tests/*.vorlang; do
    [ -e "$file" ] || continue
    run_test "$file"
done

echo ""
echo "========================================="
echo "Test Results:"
echo "  Total:  $TOTAL"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "========================================="

if [ $FAIL -eq 0 ]; then
    echo "All tests passed! ✓"
    exit 0
else
    echo "Some tests failed."
    exit 1
fi
