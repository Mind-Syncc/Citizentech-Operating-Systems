#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/config.env"
source "$DIR/functions.sh"

exigir_root
preparar_logs
audit_log "iniciou o script 01-infra.sh"
registrar "=== Provisionamento de infraestrutura ==="

#Parte de Hostname
if [ "$(hostname)" != "$HOSTNAME_ALVO" ]; then
	hostnamectl set-hostname "$HOSTNAME_ALVO"
	registrar "Hostname alterado para $HOSTNAME_ALVO"
else
	registrar "Hostname ja esta correto"
fi

if grep -q "^127.0.1.1" /etc/hosts; then
	sed -i "s/^127.0.1.1.*/127.0.1.1\t$HOSTNAME_ALVO/" /etc/hosts
else
	echo -e "127.0.1.1\t$HOSTNAME_ALVO" >> /etc/hosts
fi

if ! grep -q "iface $INTERFACE inet static" /etc/network/interfaces; then
	cat  >> /etc/network/interfaces <<EOF

auto $INTERFACE
iface $INTERFACE inet static
	address $IP_FIXO
EOF
	registrar "Bloco de rede de $INTERFACE adicionado"
else
	registrar "Interface $INTERFACE ja configurada"
fi

if ! ip -4 addr show "$INTERFACE" | grep -qF "inet $IP_FIXO"; then
	ifup "$INTERFACE"
	registrar "Interface $INTERFACE ativada"
fi

if getent hosts debian.org > /dev/null; then
	registrar "DNS funcionando"
else
	registrar "DNS nao resolveu"
fi

registrar "Hostname: $(hostname) | IP: ${IP_FIXO%/*}"
audit_log "finalizou o script 01-infra.sh"