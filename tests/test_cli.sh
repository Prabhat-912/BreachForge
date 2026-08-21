#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$PROJECT_ROOT/bin/breachforge"

PASS=0
FAIL=0

run_test() {
    local name="$1"
    local expected_exit="$2"
    shift 2

    local output
    local actual_exit

    set +e
    output="$("$@" 2>&1)"
    actual_exit=$?
    set -e

    if [[ "$actual_exit" -eq "$expected_exit" ]]; then
        echo "[PASS] $name"
        ((PASS+=1))
    else
        echo "[FAIL] $name"
        echo "       Expected exit: $expected_exit"
        echo "       Actual exit:   $actual_exit"
        echo "       Output: $output"
        ((FAIL+=1))
    fi
}

echo "BreachForge CLI Test Suite"
echo "=========================="
echo

run_test "Help command" 0 "$CLI" help
run_test "Status command" 0 "$CLI" status
run_test "Attack command" 0 "$CLI" attack
run_test "Detect command" 0 "$CLI" detect
run_test "Investigate command" 0 "$CLI" investigate
run_test "Respond command" 0 "$CLI" respond
run_test "Recover command" 0 "$CLI" recover
run_test "Report command" 0 "$CLI" report
run_test "Invalid command" 1 "$CLI" invalid-command

echo
echo "=========================="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "=========================="

if [[ "$FAIL" -ne 0 ]]; then
    exit 1
fi

echo "All CLI tests passed."
