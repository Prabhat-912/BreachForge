#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

EVIDENCE_FILE="$PROJECT_ROOT/evidence/bruteforce_incident.txt"
RESPONSE_FILE="$PROJECT_ROOT/response/response.log"
RECOVERY_FILE="$PROJECT_ROOT/recovery/recovery.log"

REPORT_DIR="$PROJECT_ROOT/reports"
REPORT_FILE="$REPORT_DIR/bruteforce_incident_report.txt"

if [[ ! -f "$EVIDENCE_FILE" ]]; then
    echo "[ERROR] Investigation evidence not found."
    echo "[INFO] Run './bin/breachforge investigate' first."
    exit 1
fi

if [[ ! -f "$RESPONSE_FILE" ]]; then
    echo "[ERROR] Response record not found."
    echo "[INFO] Run './bin/breachforge respond' first."
    exit 1
fi

if [[ ! -f "$RECOVERY_FILE" ]]; then
    echo "[ERROR] Recovery record not found."
    echo "[INFO] Run './bin/breachforge recover' first."
    exit 1
fi

mkdir -p "$REPORT_DIR"

INCIDENT_TYPE=$(grep "Incident Type:" "$EVIDENCE_FILE" | head -n 1 | awk '{print $3}')
SEVERITY=$(grep "Severity:" "$EVIDENCE_FILE" | head -n 1 | awk '{print $2}')
SOURCE_IP=$(grep "Source IP:" "$EVIDENCE_FILE" | awk '{print $3}')
TARGET_USER=$(grep "Target User:" "$EVIDENCE_FILE" | awk '{print $3}')
ATTEMPT_COUNT=$(grep "Failed Attempts:" "$EVIDENCE_FILE" | awk '{print $3}')

RESPONSE_ACTION=$(grep "Response Action:" "$RESPONSE_FILE" | awk '{print $3}')
RESPONSE_STATUS=$(grep "Status:" "$RESPONSE_FILE" | awk '{print $2}')

RECOVERY_STATUS=$(grep "Recovery Status:" "$RECOVERY_FILE" | awk '{print $3}')

if [[ -z "$INCIDENT_TYPE" || -z "$SEVERITY" || -z "$SOURCE_IP" ]]; then
    echo "[ERROR] Required investigation data not found."
    exit 1
fi

if [[ -z "$RESPONSE_ACTION" || -z "$RESPONSE_STATUS" ]]; then
    echo "[ERROR] Required response data not found."
    exit 1
fi

if [[ -z "$RECOVERY_STATUS" ]]; then
    echo "[ERROR] Required recovery data not found."
    exit 1
fi

if [[ "$RECOVERY_STATUS" == "RECOVERED" ]]; then
    FINAL_STATUS="INCIDENT RESOLVED"
else
    FINAL_STATUS="RECOVERY PENDING"
fi

cat > "$REPORT_FILE" <<EOF
BreachForge Incident Report
===========================

Incident Summary
----------------
Incident Type: $INCIDENT_TYPE
Severity: $SEVERITY
Source IP: $SOURCE_IP
Target User: $TARGET_USER
Failed Attempts: $ATTEMPT_COUNT

Response
--------
Response Action: $RESPONSE_ACTION
Response Status: $RESPONSE_STATUS

Recovery
--------
Recovery Status: $RECOVERY_STATUS

Final Status
------------
$FINAL_STATUS
EOF

echo "[SUCCESS] Incident report generated."
echo "[INFO] Incident Type: $INCIDENT_TYPE"
echo "[INFO] Source IP: $SOURCE_IP"
echo "[INFO] Severity: $SEVERITY"
echo "[INFO] Final Status: $FINAL_STATUS"
echo "[INFO] Report file: $REPORT_FILE"
