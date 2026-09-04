#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

EVIDENCE_FILE="$PROJECT_ROOT/evidence/bruteforce_incident.txt"
RESPONSE_DIR="$PROJECT_ROOT/response"
RESPONSE_FILE="$RESPONSE_DIR/response.log"

INCIDENT_MANAGER="$PROJECT_ROOT/data/incident_manager.sh"
INCIDENT_FILE="$PROJECT_ROOT/data/incidents.db"

if [[ ! -f "$EVIDENCE_FILE" ]]; then
    echo "[ERROR] Investigation evidence not found."
    echo "[INFO] Run './bin/breachforge investigate' first."
    exit 1
fi

if [[ ! -f "$INCIDENT_MANAGER" ]]; then
    echo "[ERROR] Incident manager not found."
    exit 1
fi

if [[ ! -f "$INCIDENT_FILE" ]]; then
    echo "[ERROR] Incident registry not found."
    echo "[INFO] Run './bin/breachforge detect' first."
    exit 1
fi

mkdir -p "$RESPONSE_DIR"

source "$INCIDENT_MANAGER"

INCIDENT_ID=$(grep "Incident ID:" "$EVIDENCE_FILE" | awk '{print $3}')
SOURCE_IP=$(grep "Source IP:" "$EVIDENCE_FILE" | awk '{print $3}')
SEVERITY=$(grep "Severity:" "$EVIDENCE_FILE" | head -n 1 | awk '{print $2}')
INCIDENT_TYPE=$(grep "Incident Type:" "$EVIDENCE_FILE" | awk '{print $3}')

if [[ -z "$INCIDENT_ID" ]]; then
    echo "[ERROR] Incident ID not found in investigation evidence."
    exit 1
fi

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
else
    RESPONSE_ACTION="MONITOR_SOURCE_IP"
fi

STATUS="SIMULATED"

update_status "$INCIDENT_ID" "RESPONDED"

cat > "$RESPONSE_FILE" <<EOF
BreachForge Response Record
===========================

Incident ID: $INCIDENT_ID
Incident Type: $INCIDENT_TYPE
Severity: $SEVERITY

Source IP: $SOURCE_IP

Response Action: $RESPONSE_ACTION
Status: $STATUS
EOF

echo "[SUCCESS] Response completed."
echo "[INFO] Incident ID: $INCIDENT_ID"
echo "[INFO] Incident Type: $INCIDENT_TYPE"
echo "[INFO] Source IP: $SOURCE_IP"
echo "[INFO] Response Action: $RESPONSE_ACTION"
echo "[INFO] Status: $STATUS"
echo "[INFO] Incident Status: RESPONDED"
echo "[INFO] Response file: $RESPONSE_FILE"
