#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
source "$DIR/config.env"
source "$DIR/functions.sh"

exigir_root
preparar_logs
audit_log "iniciou o provisionamento completo (provisionar.sh)"
registrar "##### Provisionamento CitizenTech #####"

for etapa in 01-infra.sh 02-app.sh 04-service.sh; do
	registrar ">>> Executando $etapa"
	if ! bash "$DIR/$etapa"; then
		registrar "ERRO: $etapa falhou. Provisionamento interrompido."
		audit_log "provisionamento interrompido em $etapa"
		exit 1
	fi
done

registrar "Provisionamento concluido. Acesse http://${IP_FIXO%/*}"
audit_log "finalizou o provisionamento completo"