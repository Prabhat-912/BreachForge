#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="$PROJECT_ROOT/logs/auth.log"

TIMESTAMP="$(date '+%b %d %H:%M:%S')"
SOURCE_IP="192.168.1.50"
USERNAME="admin"

echo "[INFO] Simulating SSH brute-force attack..."
echo "[INFO] Source IP: $SOURCE_IP"
echo "[INFO] Target user: $USERNAME"

for i in {1..5}; do
    echo "$TIMESTAMP breachforge sshd[$$]: Failed password for $USERNAME from $SOURCE_IP port $((2200 + i)) ssh2" >> "$LOG_FILE"
done

echo "[SUCCESS] Generated 5 failed SSH login events."
echo "[INFO] Log file: $LOG_FILE"
