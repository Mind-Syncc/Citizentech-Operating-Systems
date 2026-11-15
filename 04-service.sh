#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/config.env"
source "$DIR/functions.sh"

exigir_root
preparar_logs
audit_log "iniciou o script 04-servico.sh"
registrar "=== Configuracao do servico de monitoramento ==="

chmod +x "$DIR/03-monitor.sh"

cat > /etc/systemd/system/citizentech-monitor.service <<EOF
[Unit]
Description=Monitor CitizenTech (CPU, memoria e disco)
After=network.target

[Service]
Type=simple
ExecStart=$DIR/03-monitor.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
registrar "Arquivo do servico gravado"

systemctl daemon-reload
systemctl enable citizentech-monitor
systemctl restart citizentech-monitor
sleep 2

if systemctl is-active --quiet citizentech-monitor; then
	registrar "Servico citizentech-monitor ativo"
else
	registrar "ERRO: servico citizentech-monitor nao iniciou"
	exit 1
fi

audit_log "finalizou o script 04-servico.sh"