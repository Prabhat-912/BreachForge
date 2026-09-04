#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RESPONSE_FILE="$PROJECT_ROOT/response/response.log"
RECOVERY_DIR="$PROJECT_ROOT/recovery"
RECOVERY_FILE="$RECOVERY_DIR/recovery.log"

INCIDENT_MANAGER="$PROJECT_ROOT/data/incident_manager.sh"
INCIDENT_FILE="$PROJECT_ROOT/data/incidents.db"

if [[ ! -f "$RESPONSE_FILE" ]]; then
    echo "[ERROR] Response record not found."
    echo "[INFO] Run './bin/breachforge respond' first."
    exit 1
fi

if [[ ! -f "$INCIDENT_MANAGER" ]]; then
    echo "[ERROR] Incident manager not found."
    exit 1
fi

if [[ ! -f "$INCIDENT_FILE" ]]; then
    echo "[ERROR] Incident registry not found."
    exit 1
fi

mkdir -p "$RECOVERY_DIR"

source "$INCIDENT_MANAGER"

INCIDENT_ID=$(grep "Incident ID:" "$RESPONSE_FILE" | awk '{print $3}')
INCIDENT_TYPE=$(grep "Incident Type:" "$RESPONSE_FILE" | awk '{print $3}')
SOURCE_IP=$(grep "Source IP:" "$RESPONSE_FILE" | awk '{print $3}')
RESPONSE_ACTION=$(grep "Response Action:" "$RESPONSE_FILE" | awk '{print $3}')
STATUS=$(grep "^Status:" "$RESPONSE_FILE" | awk '{print $2}')

if [[ -z "$INCIDENT_ID" ]]; then
    echo "[ERROR] Incident ID not found in response record."
    exit 1
fi

if [[ -z "$INCIDENT_TYPE" ]]; then
    echo "[ERROR] Incident type not found in response record."
    exit 1
fi

if [[ -z "$SOURCE_IP" ]]; then
    echo "[ERROR] Source IP not found in response record."
    exit 1
fi

if [[ -z "$RESPONSE_ACTION" ]]; then
    echo "[ERROR] Response action not found in response record."
    exit 1
fi

if [[ -z "$STATUS" ]]; then
    echo "[ERROR] Response status not found in response record."
    exit 1
fi

if [[ "$STATUS" == "SIMULATED" ]]; then
    RECOVERY_STATUS="RECOVERED"
    update_status "$INCIDENT_ID" "$RECOVERY_STATUS"
else
    RECOVERY_STATUS="PENDING"
fi

printf '%s\n' \
    "BreachForge Recovery Record" \
    "===========================" \
    "" \
    "Incident ID: $INCIDENT_ID" \
    "Incident Type: $INCIDENT_TYPE" \
    "Source IP: $SOURCE_IP" \
    "" \
    "Response Action: $RESPONSE_ACTION" \
    "Response Status: $STATUS" \
    "" \
    "Recovery Status: $RECOVERY_STATUS" \
    > "$RECOVERY_FILE"

echo "[SUCCESS] Recovery completed."
echo "[INFO] Incident ID: $INCIDENT_ID"
echo "[INFO] Incident Type: $INCIDENT_TYPE"
echo "[INFO] Source IP: $SOURCE_IP"
echo "[INFO] Response Action: $RESPONSE_ACTION"
echo "[INFO] Recovery Status: $RECOVERY_STATUS"
echo "[INFO] Incident Status: $RECOVERY_STATUS"
echo "[INFO] Recovery file: $RECOVERY_FILE"
