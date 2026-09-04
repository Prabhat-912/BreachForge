#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$PROJECT_ROOT/bin/breachforge"

LOG_FILE="$PROJECT_ROOT/logs/auth.log"
EVIDENCE_FILE="$PROJECT_ROOT/evidence/bruteforce_incident.txt"
RESPONSE_FILE="$PROJECT_ROOT/response/response.log"
RECOVERY_FILE="$PROJECT_ROOT/recovery/recovery.log"
INCIDENT_FILE="$PROJECT_ROOT/data/incidents.db"
REPORT_FILE="$PROJECT_ROOT/reports/bruteforce_incident_report.txt"

PASS=0
FAIL=0

echo "BreachForge CLI Test Suite"
echo "=========================="

run_test() {
    local name="$1"
    local expected_exit="$2"
    shift 2

    set +e
    OUTPUT=$("$@" 2>&1)
    EXIT_CODE=$?
    set -e

    if [[ "$EXIT_CODE" -eq "$expected_exit" ]]; then
        echo "[PASS] $name"
        ((PASS+=1))
    else
        echo "[FAIL] $name"
        echo "       Expected exit: $expected_exit"
        echo "       Actual exit:   $EXIT_CODE"
        echo "       Output: $OUTPUT"
        ((FAIL+=1))
    fi
}

assert_contains() {
    local name="$1"
    local expected="$2"
    local actual="$3"

    if echo "$actual" | grep -q "$expected"; then
        echo "[PASS] $name"
        ((PASS+=1))
    else
        echo "[FAIL] $name"
        echo "       Expected: $expected"
        echo "       Actual:   $actual"
        ((FAIL+=1))
    fi
}

# Clean runtime files
rm -f "$LOG_FILE"
rm -f "$EVIDENCE_FILE"
rm -f "$RESPONSE_FILE"
rm -f "$RECOVERY_FILE"
rm -f "$INCIDENT_FILE"
rm -f "$REPORT_FILE"

mkdir -p "$PROJECT_ROOT/data"
mkdir -p "$PROJECT_ROOT/reports"

echo

# --------------------------------------------------
# Basic CLI tests
# --------------------------------------------------

run_test "Help command" 0 "$CLI" help

run_test "Status command" 0 "$CLI" status

run_test "Invalid command" 1 "$CLI" invalid-command

# --------------------------------------------------
# Attack simulation
# --------------------------------------------------

echo
echo "[TEST] Attack simulation"

ATTACK_OUTPUT=$("$CLI" attack 2>&1)

assert_contains \
    "Attack simulation output" \
    "Simulating SSH brute-force attack" \
    "$ATTACK_OUTPUT"

if [[ -f "$LOG_FILE" ]]; then
    echo "[PASS] Attack log created"
    ((PASS+=1))
else
    echo "[FAIL] Attack log created"
    ((FAIL+=1))
fi

FAILED_COUNT=$(grep -c "Failed password" "$LOG_FILE")

if [[ "$FAILED_COUNT" -eq 5 ]]; then
    echo "[PASS] Five failed login events generated"
    ((PASS+=1))
else
    echo "[FAIL] Five failed login events generated"
    echo "       Expected: 5"
    echo "       Actual:   $FAILED_COUNT"
    ((FAIL+=1))
fi

# --------------------------------------------------
# Detection engine
# --------------------------------------------------

echo
echo "[TEST] Detection engine"

DETECT_OUTPUT=$("$CLI" detect 2>&1)

assert_contains \
    "Brute-force attack detected" \
    "SSH brute-force attack detected" \
    "$DETECT_OUTPUT"

assert_contains \
    "Correct source IP detected" \
    "Source IP: 192.168.1.50" \
    "$DETECT_OUTPUT"

assert_contains \
    "Correct attempt count detected" \
    "Failed attempts: 5" \
    "$DETECT_OUTPUT"

assert_contains \
    "Correct severity detected" \
    "Severity: HIGH" \
    "$DETECT_OUTPUT"

assert_contains \
    "Incident ID created" \
    "Incident ID: INC-001" \
    "$DETECT_OUTPUT"

if grep -q "^INC-001|SSH_BRUTE_FORCE|HIGH|192.168.1.50|admin|5|DETECTED$" "$INCIDENT_FILE"; then
    echo "[PASS] Incident recorded as DETECTED"
    ((PASS+=1))
else
    echo "[FAIL] Incident recorded as DETECTED"
    ((FAIL+=1))
fi

# --------------------------------------------------
# Investigation engine
# --------------------------------------------------

echo
echo "[TEST] Investigation engine"

run_test "Investigate command" 0 "$CLI" investigate

INVESTIGATE_OUTPUT=$("$CLI" investigate 2>&1)

assert_contains \
    "Investigation completed" \
    "Investigation completed" \
    "$INVESTIGATE_OUTPUT"

if [[ -f "$EVIDENCE_FILE" ]]; then
    echo "[PASS] Investigation evidence created"
    ((PASS+=1))
else
    echo "[FAIL] Investigation evidence created"
    ((FAIL+=1))
fi

assert_contains \
    "Incident ID recorded in investigation" \
    "Incident ID: INC-001" \
    "$(cat "$EVIDENCE_FILE")"

assert_contains \
    "Incident type recorded" \
    "Incident Type: SSH_BRUTE_FORCE" \
    "$(cat "$EVIDENCE_FILE")"

assert_contains \
    "Source IP recorded" \
    "Source IP: 192.168.1.50" \
    "$(cat "$EVIDENCE_FILE")"

assert_contains \
    "Target user recorded" \
    "Target User: admin" \
    "$(cat "$EVIDENCE_FILE")"

assert_contains \
    "Severity recorded" \
    "Severity: HIGH" \
    "$(cat "$EVIDENCE_FILE")"

if grep -q "^INC-001|SSH_BRUTE_FORCE|HIGH|192.168.1.50|admin|5|INVESTIGATING$" "$INCIDENT_FILE"; then
    echo "[PASS] Incident status updated to INVESTIGATING"
    ((PASS+=1))
else
    echo "[FAIL] Incident status updated to INVESTIGATING"
    ((FAIL+=1))
fi

# --------------------------------------------------
# Response engine
# --------------------------------------------------

echo
echo "[TEST] Response engine"

run_test "Respond command" 0 "$CLI" respond

RESPONSE_OUTPUT=$("$CLI" respond 2>&1)

assert_contains \
    "Response completed" \
    "Response completed" \
    "$RESPONSE_OUTPUT"

if [[ -f "$RESPONSE_FILE" ]]; then
    echo "[PASS] Response record created"
    ((PASS+=1))
else
    echo "[FAIL] Response record created"
    ((FAIL+=1))
fi

assert_contains \
    "Incident ID recorded in response" \
    "Incident ID: INC-001" \
    "$(cat "$RESPONSE_FILE")"

assert_contains \
    "Source IP recorded in response" \
    "Source IP: 192.168.1.50" \
    "$(cat "$RESPONSE_FILE")"

assert_contains \
    "Correct response action recorded" \
    "Response Action: BLOCK_SOURCE_IP" \
    "$(cat "$RESPONSE_FILE")"

assert_contains \
    "Response marked as simulated" \
    "Status: SIMULATED" \
    "$(cat "$RESPONSE_FILE")"

if grep -q "^INC-001|SSH_BRUTE_FORCE|HIGH|192.168.1.50|admin|5|RESPONDED$" "$INCIDENT_FILE"; then
    echo "[PASS] Incident status updated to RESPONDED"
    ((PASS+=1))
else
    echo "[FAIL] Incident status updated to RESPONDED"
    ((FAIL+=1))
fi

# --------------------------------------------------
# Recovery engine
# --------------------------------------------------

echo
echo "[TEST] Recovery engine"

run_test "Recover command" 0 "$CLI" recover

RECOVERY_OUTPUT=$("$CLI" recover 2>&1)

assert_contains \
    "Recovery completed" \
    "Recovery completed" \
    "$RECOVERY_OUTPUT"

if [[ -f "$RECOVERY_FILE" ]]; then
    echo "[PASS] Recovery record created"
    ((PASS+=1))
else
    echo "[FAIL] Recovery record created"
    ((FAIL+=1))
fi

assert_contains \
    "Incident ID recorded in recovery" \
    "Incident ID: INC-001" \
    "$(cat "$RECOVERY_FILE")"

assert_contains \
    "Source IP recorded in recovery" \
    "Source IP: 192.168.1.50" \
    "$(cat "$RECOVERY_FILE")"

assert_contains \
    "Response status recorded" \
    "Response Status: SIMULATED" \
    "$(cat "$RECOVERY_FILE")"

assert_contains \
    "Recovery marked as recovered" \
    "Recovery Status: RECOVERED" \
    "$(cat "$RECOVERY_FILE")"

if grep -q "^INC-001|SSH_BRUTE_FORCE|HIGH|192.168.1.50|admin|5|RECOVERED$" "$INCIDENT_FILE"; then
    echo "[PASS] Incident status updated to RECOVERED"
    ((PASS+=1))
else
    echo "[FAIL] Incident status updated to RECOVERED"
    ((FAIL+=1))
fi

# --------------------------------------------------
# Report engine
# --------------------------------------------------

echo
echo "[TEST] Report engine"

run_test "Report command" 0 "$CLI" report

REPORT_OUTPUT=$(cat "$REPORT_FILE")

if [[ -f "$REPORT_FILE" ]]; then
    echo "[PASS] Incident report created"
    ((PASS+=1))
else
    echo "[FAIL] Incident report created"
    ((FAIL+=1))
fi

assert_contains \
    "Incident ID recorded in report" \
    "Incident ID: INC-001" \
    "$REPORT_OUTPUT"

assert_contains \
    "Incident type recorded in report" \
    "Incident Type: SSH_BRUTE_FORCE" \
    "$REPORT_OUTPUT"

assert_contains \
    "Severity recorded in report" \
    "Severity: HIGH" \
    "$REPORT_OUTPUT"

assert_contains \
    "Source IP recorded in report" \
    "Source IP: 192.168.1.50" \
    "$REPORT_OUTPUT"

assert_contains \
    "Target user recorded in report" \
    "Target User: admin" \
    "$REPORT_OUTPUT"

assert_contains \
    "Failed attempt count recorded in report" \
    "Failed Attempts: 5" \
    "$REPORT_OUTPUT"

assert_contains \
    "Response action recorded in report" \
    "Response Action: BLOCK_SOURCE_IP" \
    "$REPORT_OUTPUT"

assert_contains \
    "Recovery status recorded in report" \
    "Recovery Status: RECOVERED" \
    "$REPORT_OUTPUT"

assert_contains \
    "Final incident status recorded" \
    "INCIDENT RESOLVED" \
    "$REPORT_OUTPUT"

# --------------------------------------------------
# Summary
# --------------------------------------------------

echo "=========================="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "=========================="

if [[ "$FAIL" -eq 0 ]]; then
    echo "All CLI tests passed."
    exit 0
else
    echo "Some CLI tests failed."
    exit 1
fi
