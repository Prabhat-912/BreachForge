#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$PROJECT_ROOT/bin/breachforge"
LOG_FILE="$PROJECT_ROOT/logs/auth.log"
EVIDENCE_FILE="$PROJECT_ROOT/evidence/bruteforce_incident.txt"
RESPONSE_FILE="$PROJECT_ROOT/response/response.log"
RECOVERY_FILE="$PROJECT_ROOT/recovery/recovery.log"
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

# --------------------------------------------------
# CLI Tests
# --------------------------------------------------

run_test "Help command" 0 "$CLI" help
run_test "Status command" 0 "$CLI" status
run_test "Investigate command" 0 "$CLI" investigate
run_test "Respond command" 0 "$CLI" respond
run_test "Recover command" 0 "$CLI" recover
run_test "Report command" 0 "$CLI" report
run_test "Invalid command" 1 "$CLI" invalid-command

echo

# --------------------------------------------------
# Attack Simulation Tests
# --------------------------------------------------

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

# --------------------------------------------------
# Detection Engine Tests
# --------------------------------------------------

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

# --------------------------------------------------
# Investigation Engine Tests
# --------------------------------------------------

echo "[TEST] Investigation engine"

rm -f "$EVIDENCE_FILE"

INVESTIGATION_OUTPUT="$("$CLI" investigate 2>&1)"

if [[ "$INVESTIGATION_OUTPUT" == *"[SUCCESS] Investigation completed."* ]]; then
    echo "[PASS] Investigation completed"
    ((PASS+=1))
else
    echo "[FAIL] Investigation completed"
    echo "$INVESTIGATION_OUTPUT"
    ((FAIL+=1))
fi

if [[ -f "$EVIDENCE_FILE" ]]; then
    echo "[PASS] Investigation evidence created"
    ((PASS+=1))
else
    echo "[FAIL] Investigation evidence created"
    ((FAIL+=1))
fi

if [[ -f "$EVIDENCE_FILE" ]] && grep -q "Incident Type: SSH_BRUTE_FORCE" "$EVIDENCE_FILE"; then
    echo "[PASS] Incident type recorded"
    ((PASS+=1))
else
    echo "[FAIL] Incident type recorded"
    ((FAIL+=1))
fi

if [[ -f "$EVIDENCE_FILE" ]] && grep -q "Source IP: 192.168.1.50" "$EVIDENCE_FILE"; then
    echo "[PASS] Source IP recorded"
    ((PASS+=1))
else
    echo "[FAIL] Source IP recorded"
    ((FAIL+=1))
fi

if [[ -f "$EVIDENCE_FILE" ]] && grep -q "Target User: admin" "$EVIDENCE_FILE"; then
    echo "[PASS] Target user recorded"
    ((PASS+=1))
else
    echo "[FAIL] Target user recorded"
    ((FAIL+=1))
fi

if [[ -f "$EVIDENCE_FILE" ]] && grep -q "Severity: HIGH" "$EVIDENCE_FILE"; then
    echo "[PASS] Severity recorded"
    ((PASS+=1))
else
    echo "[FAIL] Severity recorded"
    ((FAIL+=1))
fi

echo

# --------------------------------------------------
# Response Engine Tests
# --------------------------------------------------

echo "[TEST] Response engine"

rm -f "$RESPONSE_FILE"

RESPONSE_OUTPUT="$("$CLI" respond 2>&1)"

if [[ "$RESPONSE_OUTPUT" == *"[SUCCESS] Response completed."* ]]; then
    echo "[PASS] Response completed"
    ((PASS+=1))
else
    echo "[FAIL] Response completed"
    echo "$RESPONSE_OUTPUT"
    ((FAIL+=1))
fi

if [[ -f "$RESPONSE_FILE" ]]; then
    echo "[PASS] Response record created"
    ((PASS+=1))
else
    echo "[FAIL] Response record created"
    ((FAIL+=1))
fi

if [[ -f "$RESPONSE_FILE" ]] && grep -q "Source IP: 192.168.1.50" "$RESPONSE_FILE"; then
    echo "[PASS] Source IP recorded in response"
    ((PASS+=1))
else
    echo "[FAIL] Source IP recorded in response"
    ((FAIL+=1))
fi

if [[ -f "$RESPONSE_FILE" ]] && grep -q "Response Action: BLOCK_SOURCE_IP" "$RESPONSE_FILE"; then
    echo "[PASS] Correct response action recorded"
    ((PASS+=1))
else
    echo "[FAIL] Correct response action recorded"
    ((FAIL+=1))
fi

if [[ -f "$RESPONSE_FILE" ]] && grep -q "Status: SIMULATED" "$RESPONSE_FILE"; then
    echo "[PASS] Response marked as simulated"
    ((PASS+=1))
else
    echo "[FAIL] Response marked as simulated"
    ((FAIL+=1))
fi

echo

# --------------------------------------------------
# Recovery Engine Tests
# --------------------------------------------------

echo "[TEST] Recovery engine"

rm -f "$RECOVERY_FILE"

RECOVERY_OUTPUT="$("$CLI" recover 2>&1)"

if [[ "$RECOVERY_OUTPUT" == *"[SUCCESS] Recovery completed."* ]]; then
    echo "[PASS] Recovery completed"
    ((PASS+=1))
else
    echo "[FAIL] Recovery completed"
    echo "$RECOVERY_OUTPUT"
    ((FAIL+=1))
fi

if [[ -f "$RECOVERY_FILE" ]]; then
    echo "[PASS] Recovery record created"
    ((PASS+=1))
else
    echo "[FAIL] Recovery record created"
    ((FAIL+=1))
fi

if [[ -f "$RECOVERY_FILE" ]] && grep -q "Source IP: 192.168.1.50" "$RECOVERY_FILE"; then
    echo "[PASS] Source IP recorded in recovery"
    ((PASS+=1))
else
    echo "[FAIL] Source IP recorded in recovery"
    ((FAIL+=1))
fi

if [[ -f "$RECOVERY_FILE" ]] && grep -q "Response Status: SIMULATED" "$RECOVERY_FILE"; then
    echo "[PASS] Response status recorded"
    ((PASS+=1))
else
    echo "[FAIL] Response status recorded"
    ((FAIL+=1))
fi

if [[ -f "$RECOVERY_FILE" ]] && grep -q "Recovery Status: RECOVERED" "$RECOVERY_FILE"; then
    echo "[PASS] Recovery marked as recovered"
    ((PASS+=1))
else
    echo "[FAIL] Recovery marked as recovered"
    ((FAIL+=1))
fi

# --------------------------------------------------
# Report Engine Tests
# --------------------------------------------------

echo
echo "[TEST] Report engine"

REPORT_FILE="$PROJECT_ROOT/reports/bruteforce_incident_report.txt"

if [[ -f "$REPORT_FILE" ]]; then
    echo "[PASS] Incident report created"
    ((PASS+=1))
else
    echo "[FAIL] Incident report created"
    ((FAIL+=1))
fi

if grep -q "Incident Type: SSH_BRUTE_FORCE" "$REPORT_FILE"; then
    echo "[PASS] Incident type recorded in report"
    ((PASS+=1))
else
    echo "[FAIL] Incident type recorded in report"
    ((FAIL+=1))
fi

if grep -q "Severity: HIGH" "$REPORT_FILE"; then
    echo "[PASS] Severity recorded in report"
    ((PASS+=1))
else
    echo "[FAIL] Severity recorded in report"
    ((FAIL+=1))
fi

if grep -q "Source IP: 192.168.1.50" "$REPORT_FILE"; then
    echo "[PASS] Source IP recorded in report"
    ((PASS+=1))
else
    echo "[FAIL] Source IP recorded in report"
    ((FAIL+=1))
fi

if grep -q "Target User: admin" "$REPORT_FILE"; then
    echo "[PASS] Target user recorded in report"
    ((PASS+=1))
else
    echo "[FAIL] Target user recorded in report"
    ((FAIL+=1))
fi

if grep -q "Failed Attempts: 5" "$REPORT_FILE"; then
    echo "[PASS] Failed attempt count recorded in report"
    ((PASS+=1))
else
    echo "[FAIL] Failed attempt count recorded in report"
    ((FAIL+=1))
fi

if grep -q "Response Action: BLOCK_SOURCE_IP" "$REPORT_FILE"; then
    echo "[PASS] Response action recorded in report"
    ((PASS+=1))
else
    echo "[FAIL] Response action recorded in report"
    ((FAIL+=1))
fi

if grep -q "Recovery Status: RECOVERED" "$REPORT_FILE"; then
    echo "[PASS] Recovery status recorded in report"
    ((PASS+=1))
else
    echo "[FAIL] Recovery status recorded in report"
    ((FAIL+=1))
fi

if grep -q "INCIDENT RESOLVED" "$REPORT_FILE"; then
    echo "[PASS] Final incident status recorded"
    ((PASS+=1))
else
    echo "[FAIL] Final incident status recorded"
    ((FAIL+=1))
fi

# --------------------------------------------------
# Test Summary
# --------------------------------------------------

echo "=========================="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "=========================="

if [[ "$FAIL" -ne 0 ]]; then
    exit 1
fi

echo "All CLI tests passed."
