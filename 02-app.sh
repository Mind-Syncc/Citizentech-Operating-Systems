#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/config.env"
source "$DIR/functions.sh"

exigir_root
preparar_logs
audit_log "iniciou o script 02-app.sh"
registrar "=== Provisionamento da aplicacao ==="

# Dependencias
apt-get update -qq
for pacote in $PACOTES; do
	if dpkg -s "$pacote" > /dev/null 2>&1; then
		registrar "Pacote $pacote ja instalado"
	elif apt-get install -y "$pacote" > /dev/null 2>&1; then
		registrar "Pacote $pacote instalado"
	else
		registrar "ERRO: falha ao instalar $pacote"
		exit 1
	fi
done

# Publicar a pagina
cp "$DIR/site/index.html" "$SITE_DESTINO"
chmod 644 "$SITE_DESTINO"
registrar "Pagina publicada em $SITE_DESTINO"

# Servico
systemctl enable --now nginx
registrar "Servico nginx habilitado e iniciado"

# Verificacao
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
if [ "$STATUS" = "200" ]; then
	registrar "Aplicacao respondeu HTTP 200 em http://${IP_FIXO%/*}"
else
	registrar "ALERTA: aplicacao respondeu HTTP $STATUS"
fi

audit_log "finalizou o script 02-app.sh"