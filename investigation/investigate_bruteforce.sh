#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

LOG_FILE="$PROJECT_ROOT/logs/auth.log"
EVIDENCE_DIR="$PROJECT_ROOT/evidence"
EVIDENCE_FILE="$EVIDENCE_DIR/bruteforce_incident.txt"

THRESHOLD=5

echo "[INFO] Starting investigation..."

if [[ ! -f "$LOG_FILE" ]]; then
    echo "[ERROR] Authentication log not found."
    exit 1
fi

mkdir -p "$EVIDENCE_DIR"

FAILED_LOGINS=$(grep "Failed password" "$LOG_FILE" || true)

if [[ -z "$FAILED_LOGINS" ]]; then
    echo "[INFO] No failed SSH login events found."
    exit 0
fi

SOURCE_IP=$(echo "$FAILED_LOGINS" \
    | awk '{for (i=1; i<=NF; i++) if ($i=="from") print $(i+1)}' \
    | sort \
    | uniq -c \
    | sort -nr \
    | head -n 1 \
    | awk '{print $2}')

ATTEMPT_COUNT=$(echo "$FAILED_LOGINS" \
    | awk -v ip="$SOURCE_IP" '
        {
            for (i=1; i<=NF; i++) {
                if ($i=="from" && $(i+1)==ip)
                    count++
            }
        }
        END {print count}
    ')

TARGET_USER=$(echo "$FAILED_LOGINS" \
    | grep "from $SOURCE_IP" \
    | head -n 1 \
    | awk '{for (i=1; i<=NF; i++) if ($i=="for") print $(i+1)}')

FIRST_EVENT=$(echo "$FAILED_LOGINS" \
    | grep "from $SOURCE_IP" \
    | head -n 1)

LAST_EVENT=$(echo "$FAILED_LOGINS" \
    | grep "from $SOURCE_IP" \
    | tail -n 1)

if [[ "$ATTEMPT_COUNT" -ge "$THRESHOLD" ]]; then
    INCIDENT_TYPE="SSH_BRUTE_FORCE"
    SEVERITY="HIGH"
else
    INCIDENT_TYPE="SUSPICIOUS_LOGIN_ACTIVITY"
    SEVERITY="MEDIUM"
fi

cat > "$EVIDENCE_FILE" <<EOF
BreachForge Investigation Report
================================

Incident Type: $INCIDENT_TYPE
Severity: $SEVERITY

Source IP: $SOURCE_IP
Target User: $TARGET_USER
Failed Attempts: $ATTEMPT_COUNT

First Observed Event:
$FIRST_EVENT

Last Observed Event:
$LAST_EVENT
EOF

echo "[SUCCESS] Investigation completed."
echo "[INFO] Incident Type: $INCIDENT_TYPE"
echo "[INFO] Source IP: $SOURCE_IP"
echo "[INFO] Target User: $TARGET_USER"
echo "[INFO] Failed Attempts: $ATTEMPT_COUNT"
echo "[INFO] Severity: $SEVERITY"
echo "[INFO] Evidence file: $EVIDENCE_FILE"
