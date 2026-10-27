#!/bin/bash

# ==============================================================================
# Script Name: health_daemon.sh
# Description: Monitors CPU, Memory, and Disk metrics. Triggers alerts on threshold breaches.
# ==============================================================================

LOG_FILE="/tmp/system_daemon.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Set Alert Thresholds (in percentage)
MEM_THRESHOLD=80
DISK_THRESHOLD=85

# --- 1. Gather System Metrics ---

# Memory usage calculation using 'free' and 'awk'
MEM_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100)}')

# Disk usage calculation for root partition '/' using 'df' and 'awk'
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

# CPU load calculation over 1 minute using 'top' or 'uptime'
CPU_LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | awk '{ print $1 }' | sed 's/,//')

# --- 2. Logging & Alert Evaluation Logic ---

STATUS="OK"
ALERTS=()

if [ "$MEM_USAGE" -gt "$MEM_THRESHOLD" ]; then
    STATUS="WARNING"
    ALERTS+=("High Memory Usage: ${MEM_USAGE}% (Threshold: ${MEM_THRESHOLD}%)")
fi

if [ "$DISK_USAGE" -gt "$DISK_THRESHOLD" ]; then
    STATUS="CRITICAL"
    ALERTS+=("High Disk Space Usage: ${DISK_USAGE}% (Threshold: ${DISK_THRESHOLD}%)")
fi

# --- 3. Format and Output Logs ---

echo "[$TIMESTAMP] STATUS=$STATUS | CPU_LOAD=$CPU_LOAD | MEM=$MEM_USAGE% | DISK=$DISK_USAGE%" >> "$LOG_FILE"

# Log individual alerts if any rule was breached
if [ ${#ALERTS[@]} -gt 0 ]; then
    for alert in "${ALERTS[@]}"; do
        echo "[$TIMESTAMP] [ALERT_TRIGGERED] $alert" >> "$LOG_FILE"
    done
fi
