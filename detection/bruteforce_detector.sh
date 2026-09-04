#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$PROJECT_ROOT/logs/auth.log"
INCIDENT_MANAGER="$PROJECT_ROOT/data/incident_manager.sh"

THRESHOLD=5

echo "[INFO] Starting brute-force detection..."

if [[ ! -f "$LOG_FILE" ]]; then
    echo "[INFO] No authentication log found."
    exit 0
fi

if [[ ! -f "$INCIDENT_MANAGER" ]]; then
    echo "[ERROR] Incident manager not found."
    exit 1
fi

source "$INCIDENT_MANAGER"

IP_COUNT=$(grep "Failed password" "$LOG_FILE" \
    | awk '{for (i=1; i<=NF; i++) if ($i=="from") print $(i+1)}' \
    | sort \
    | uniq -c \
    | sort -nr)

if [[ -z "$IP_COUNT" ]]; then
    echo "[INFO] No failed login attempts detected."
    exit 0
fi

DETECTED=0

while read -r COUNT IP; do

    if [[ "$COUNT" -ge "$THRESHOLD" ]]; then

        TARGET_USER=$(grep "Failed password" "$LOG_FILE" \
            | grep "from $IP" \
            | head -n 1 \
            | awk '{for (i=1; i<=NF; i++) if ($i=="for") print $(i+1)}')

        INCIDENT_ID=$(create_incident \
            "SSH_BRUTE_FORCE" \
            "HIGH" \
            "$IP" \
            "$TARGET_USER" \
            "$COUNT")

        echo "[ALERT] SSH brute-force attack detected!"
        echo "[ALERT] Incident ID: $INCIDENT_ID"
        echo "[ALERT] Source IP: $IP"
        echo "[ALERT] Target User: $TARGET_USER"
        echo "[ALERT] Failed attempts: $COUNT"
        echo "[ALERT] Severity: HIGH"

        DETECTED=1
    fi

done <<< "$IP_COUNT"

if [[ "$DETECTED" -eq 0 ]]; then
    echo "[INFO] No brute-force attack detected."
fi
