#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

INCIDENT_DIR="$PROJECT_ROOT/data"
INCIDENT_FILE="$INCIDENT_DIR/incidents.db"

mkdir -p "$INCIDENT_DIR"

create_incident() {
    local incident_type="$1"
    local severity="$2"
    local source_ip="$3"
    local target_user="$4"
    local attempt_count="$5"

    local next_id
    local incident_number

    if [[ ! -f "$INCIDENT_FILE" ]]; then
        incident_number=1
    else
        incident_number=$(awk -F'|' '
            BEGIN { max=0 }
            /^INC-/ {
                id=$1
                sub("INC-", "", id)
                if (id > max)
                    max=id
            }
            END {
                print max + 1
            }
        ' "$INCIDENT_FILE")
    fi

    next_id=$(printf "INC-%03d" "$incident_number")

    echo "$next_id|$incident_type|$severity|$source_ip|$target_user|$attempt_count|DETECTED" >> "$INCIDENT_FILE"

    echo "$next_id"
}

get_incident() {
    local incident_id="$1"

    if [[ ! -f "$INCIDENT_FILE" ]]; then
        return 1
    fi

    grep "^${incident_id}|" "$INCIDENT_FILE"
}

update_status() {
    local incident_id="$1"
    local new_status="$2"

    if [[ ! -f "$INCIDENT_FILE" ]]; then
        echo "[ERROR] Incident registry not found."
        return 1
    fi

    awk -F'|' -v id="$incident_id" -v status="$new_status" '
        BEGIN { OFS="|" }
        $1 == id {
            $7 = status
        }
        {
            print
        }
    ' "$INCIDENT_FILE" > "$INCIDENT_FILE.tmp"

    mv "$INCIDENT_FILE.tmp" "$INCIDENT_FILE"
}
