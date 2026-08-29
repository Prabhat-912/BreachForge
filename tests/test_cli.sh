#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$PROJECT_ROOT/bin/breachforge"
LOG_FILE="$PROJECT_ROOT/logs/auth.log"

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
run_test "Investigate command" 0 "$CLI" investigate
run_test "Respond command" 0 "$CLI" respond
run_test "Recover command" 0 "$CLI" recover
run_test "Report command" 0 "$CLI" report
run_test "Invalid command" 1 "$CLI" invalid-command

echo

echo "[TEST] Attack simulation"

rm -f "$LOG_FILE"

ATTACK_OUTPUT="$("$CLI" attack 2>&1)"

if [[ "$ATTACK_OUTPUT" == *"[SUCCESS] Generated 5 failed SSH login events."* ]]; then
    echo "[PASS] Attack simulation output"
    ((PASS+=1))
else
    echo "[FAIL] Attack simulation output"
    echo "$ATTACK_OUTPUT"
    ((FAIL+=1))
fi

if [[ -f "$LOG_FILE" ]]; then
    echo "[PASS] Attack log created"
    ((PASS+=1))
else
    echo "[FAIL] Attack log created"
    ((FAIL+=1))
fi

if [[ -f "$LOG_FILE" ]] && [[ "$(grep -c "Failed password" "$LOG_FILE")" -eq 5 ]]; then
    echo "[PASS] Five failed login events generated"
    ((PASS+=1))
else
    echo "[FAIL] Five failed login events generated"
    ((FAIL+=1))
fi

echo

echo "[TEST] Detection engine"

DETECT_OUTPUT="$("$CLI" detect 2>&1)"

if [[ "$DETECT_OUTPUT" == *"[ALERT] SSH brute-force attack detected!"* ]]; then
    echo "[PASS] Brute-force attack detected"
    ((PASS+=1))
else
    echo "[FAIL] Brute-force attack detected"
    echo "$DETECT_OUTPUT"
    ((FAIL+=1))
fi

if [[ "$DETECT_OUTPUT" == *"[ALERT] Source IP: 192.168.1.50"* ]]; then
    echo "[PASS] Correct source IP detected"
    ((PASS+=1))
else
    echo "[FAIL] Correct source IP detected"
    echo "$DETECT_OUTPUT"
    ((FAIL+=1))
fi

if [[ "$DETECT_OUTPUT" == *"[ALERT] Failed attempts: 5"* ]]; then
    echo "[PASS] Correct attempt count detected"
    ((PASS+=1))
else
    echo "[FAIL] Correct attempt count detected"
    echo "$DETECT_OUTPUT"
    ((FAIL+=1))
fi

if [[ "$DETECT_OUTPUT" == *"[ALERT] Severity: HIGH"* ]]; then
    echo "[PASS] Correct severity detected"
    ((PASS+=1))
else
    echo "[FAIL] Correct severity detected"
    echo "$DETECT_OUTPUT"
    ((FAIL+=1))
fi

echo
echo "=========================="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "=========================="

if [[ "$FAIL" -ne 0 ]]; then
    exit 1
fi

echo "All CLI tests passed."
