#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/config.env"
source "$DIR/functions.sh"

exigir_root
preparar_logs

cpu_uso() {
	read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat
	sleep 1
	read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
	local total=$(( (u2+n2+s2+i2+w2+q2+sq2) - (u1+n1+s1+i1+w1+q1+sq1) ))
	local ocioso=$(( (i2+w2) - (i1+w1) ))
	[ "$total" -eq 0 ] && { echo 0; return; }
	echo $(( (total - ocioso) * 100 / total ))
}

mem_uso() {
	awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf "%d", (t-a)*100/t}' /proc/meminfo
}

disco_uso() {
	df / | awk 'NR==2 {gsub("%","",$5); print $5}'
}

checar() {
	local nome="$1" valor="$2" limite="$3"
	if [ "$valor" -ge "$limite" ]; then
		registrar "ALERTA: $nome em ${valor}% (limite ${limite}%)"
	else
		log_exec "INFO: $nome em ${valor}%"
	fi
}

trap 'audit_log "encerrou o 03-monitor.sh"' EXIT
audit_log "iniciou o 03-monitor.sh"
registrar "=== Monitor iniciado (a cada ${INTERVALO}s) ==="

while true; do
	checar "CPU" "$(cpu_uso)" "$LIMITE_CPU"
	checar "Memoria" "$(mem_uso)" "$LIMITE_MEM"
	checar "Disco" "$(disco_uso)" "$LIMITE_DISCO"
	sleep "$INTERVALO"
done