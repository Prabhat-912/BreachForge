#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

EVIDENCE_FILE="$PROJECT_ROOT/evidence/bruteforce_incident.txt"
RESPONSE_DIR="$PROJECT_ROOT/response"
RESPONSE_FILE="$RESPONSE_DIR/response.log"


if [[ ! -f "$EVIDENCE_FILE" ]]; then
    echo "[ERROR] Investigation evidence not found."
    echo "[INFO] Run './bin/breachforge investigate' first."
    exit 1
fi

mkdir -p "$RESPONSE_DIR"

SOURCE_IP=$(grep "Source IP:" "$EVIDENCE_FILE" | awk '{print $3}')
SEVERITY=$(grep "Severity:" "$EVIDENCE_FILE" | head -n 1 | awk '{print $2}')
INCIDENT_TYPE=$(grep "Incident Type:" "$EVIDENCE_FILE" | awk '{print $3}')

if [[ -z "$SOURCE_IP" ]]; then
    echo "[ERROR] Source IP not found in investigation evidence."
    exit 1
fi

if [[ -z "$SEVERITY" ]]; then
    echo "[ERROR] Severity not found in investigation evidence."
    exit 1
fi

if [[ -z "$INCIDENT_TYPE" ]]; then
    echo "[ERROR] Incident type not found in investigation evidence."
    exit 1
fi

if [[ "$SEVERITY" == "HIGH" && "$INCIDENT_TYPE" == "SSH_BRUTE_FORCE" ]]; then
    RESPONSE_ACTION="BLOCK_SOURCE_IP"
    STATUS="SIMULATED"
else
    RESPONSE_ACTION="MONITOR_SOURCE_IP"
    STATUS="SIMULATED"
fi

cat > "$RESPONSE_FILE" <<EOF
BreachForge Response Record
===========================

Incident Type: $INCIDENT_TYPE
Severity: $SEVERITY

Source IP: $SOURCE_IP

Response Action: $RESPONSE_ACTION
Status: $STATUS
EOF

echo "[SUCCESS] Response completed."
echo "[INFO] Incident Type: $INCIDENT_TYPE"
echo "[INFO] Source IP: $SOURCE_IP"
echo "[INFO] Response Action: $RESPONSE_ACTION"
echo "[INFO] Status: $STATUS"
echo "[INFO] Response file: $RESPONSE_FILE"
