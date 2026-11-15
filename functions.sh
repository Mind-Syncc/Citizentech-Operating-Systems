#!/bin/bash
LOG_DIR="/var/log/citizentech"
EXEC_LOG="$LOG_DIR/exec.log"
AUDIT_LOG="$LOG_DIR/audit.log"

timestamp() { date '+%d/%m/%Y %H:%M:%S'; }

log_exec() { echo "[$(timestamp)] $1" >> "$EXEC_LOG"; }
audit_log() { echo "[$(timestamp)] Usuario ${SUDO_USER:-$USER} $1" >> "$AUDIT_LOG"; }
mostrar() { echo "$1" ; }
registrar() { mostrar "$1"; log_exec "$1"; }

exigir_root() {
	if [ "$EUID" -ne 0 ]; then
		echo "Execute como seu root (su -)."
		exit 1
	fi
}


preparar_logs() { mkdir -p "$LOG_DIR"; touch "$EXEC_LOG" "$AUDIT_LOG"; }