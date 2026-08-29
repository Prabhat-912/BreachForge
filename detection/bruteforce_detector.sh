#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$PROJECT_ROOT/logs/auth.log"

THRESHOLD=5

echo "[INFO] Starting brute-force detection..."

if [[ ! -f "$LOG_FILE" ]]; then
    echo "[INFO] No authentication log found."
    exit 0
fi

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
        echo "[ALERT] SSH brute-force attack detected!"
        echo "[ALERT] Source IP: $IP"
        echo "[ALERT] Failed attempts: $COUNT"
        echo "[ALERT] Severity: HIGH"
        DETECTED=1
    fi

done <<< "$IP_COUNT"

if [[ "$DETECTED" -eq 0 ]]; then
    echo "[INFO] No brute-force attack detected."
fi
