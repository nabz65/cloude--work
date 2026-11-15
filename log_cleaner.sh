#!/bin/bash
set -euo pipefail

# ==============================================================================
# Script Name: log_cleaner.sh
# Description: Production utility to compress aged logs and purge expired archives.
# ==============================================================================

# Default Configuration
TARGET_DIR="/tmp/app_logs"
RETENTION_DAYS=7
MODE="archive"
AUDIT_LOG="/tmp/log_cleaner_audit.log"

log_event() {
    local LEVEL="$1"
    local MESSAGE="$2"
    local TIMESTAMP
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] [$LEVEL] $MESSAGE" | tee -a "$AUDIT_LOG"
}

usage() {
    echo "Usage: $0 [-d directory] [-r retention_days] [-m archive|purge]"
    echo "  -d : Target directory containing logs (default: /tmp/app_logs)"
    echo "  -r : Age threshold in days (default: 7)"
    echo "  -m : Operation mode: 'archive' (gzip .log) or 'purge' (delete .gz)"
    exit 1
}

# Parse CLI Flags
while getopts "d:r:m:h" opt; do
    case "${opt}" in
        d) TARGET_DIR="${OPTARG}" ;;
        r) RETENTION_DAYS="${OPTARG}" ;;
        m) MODE="${OPTARG}" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Validate Target Directory
if [ ! -d "$TARGET_DIR" ]; then
    log_event "ERROR" "Target directory '$TARGET_DIR' does not exist."
    exit 1
fi

archive_logs() {
    local DIR="$1"
    local DAYS="$2"
    local COUNT=0

    log_event "INFO" "Scanning '$DIR' for .log files older than $DAYS days to compress..."

    while IFS= read -r file; do
        gzip -f "$file"
        log_event "INFO" "Compressed: $file -> ${file}.gz"
        ((COUNT++)) || true
    done < <(find "$DIR" -maxdepth 1 -type f -name "*.log" -mtime +"$DAYS")

    log_event "SUCCESS" "Archive complete. Total files compressed: $COUNT"
}

purge_archives() {
    local DIR="$1"
    local DAYS="$2"
    local COUNT=0

    log_event "INFO" "Scanning '$DIR' for .gz archives older than $DAYS days to purge..."

    while IFS= read -r file; do
        rm -f "$file"
        log_event "WARN" "Purged expired archive: $file"
        ((COUNT++)) || true
    done < <(find "$DIR" -maxdepth 1 -type f -name "*.gz" -mtime +"$DAYS")

    log_event "SUCCESS" "Purge complete. Total archives deleted: $COUNT"
}

# --- Main Execution ---
case "$MODE" in
    archive)
        archive_logs "$TARGET_DIR" "$RETENTION_DAYS"
        ;;
    purge)
        purge_archives "$TARGET_DIR" "$RETENTION_DAYS"
        ;;
    *)
        log_event "ERROR" "Invalid mode '$MODE'. Use 'archive' or 'purge'."
        usage
        ;;
esac
