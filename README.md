# Memória Digital: infraestrutura Linux da CitizenTech
 
Global Solution FIAP 2026.2 · Operating Systems · Engenharia de Software (3º ano)
 
Este repositório entrega a infraestrutura Linux que hospeda a página web da **Memória Digital**. Um conjunto de scripts Bash provisiona, de forma automática, a rede, a aplicação web (nginx) e um monitoramento de CPU, memória e disco que roda como serviço do systemd com reinício automático.
 
## Ficha da CitizenTech
 
| Campo | Resposta |
|---|---|
| Nome da CitizenTech | Memória Digital |
| Cidadão beneficiado | Pessoas que estão começando no mundo digital e as famílias que querem protegê-las |
| Problema, em uma frase | Idosos dependem de terceiros para usar o celular e são alvo frequente de golpes por mensagem, sem uma ferramenta simples para conferir se uma mensagem é segura |
| Como funciona | A pessoa cola uma mensagem suspeita e recebe, em linguagem simples, os sinais de golpe encontrados e o que fazer. Há também um simulador de golpes e dicas de segurança |
| O que cada parte faz | **Operating Systems:** infraestrutura Linux automatizada que hospeda a aplicação web *(demais disciplinas: preencher conforme a entrega de cada uma)* |
| Indicador de impacto | *(a definir pela equipe, por exemplo: número de mensagens analisadas e de sinais de golpe identificados)* |
| ODS conectados | ODS 10 (redução das desigualdades), ODS 9 (indústria, inovação e infraestrutura) e ODS 11 (cidades e comunidades sustentáveis). *Explicar a contribuição de cada um antes da entrega* |
 
### Contexto
 
Segundo o TIC Domicílios 2025 (Cetic.br), 59% das pessoas com 60 anos ou mais usam internet, e a falta de habilidade é o principal motivo apontado por quem não usa. *Conferir os números na fonte antes de entregar.*
 
## Integrantes
 
| Nome | RM |
|---|---|
| Heloísa Fleury Jardim | RM556378 |
| Juan Fuentes Rufino | RM557673 |
| Rickelmyn de Souza Ruescas | RM556055 |
| Paulo Henrique Monteiro Golovanevsky | RM555300 |
| Pedro Henrique Silva Batista | RM558137 |
 
## Ambiente
 
- Máquina virtual **Debian 13**, sem interface gráfica, no VirtualBox.
- **Adaptador 1 (NAT):** saída para a internet, usada para instalar pacotes.
- **Adaptador 2 (host-only):** rede privada entre o Windows e a VM. A interface `enp0s8` recebe o IP fixo `192.168.56.10`, e é por ele que a aplicação é acessada.
## Estrutura do repositório
 
```
.
├── config.env           variáveis do projeto (interface, IP, hostname, pacotes, limites)
├── functions.sh         funções compartilhadas (logs, checagem de root)
├── 01-infra.sh          hostname, IP fixo e teste de DNS
├── 02-app.sh            instala o nginx, publica a página e testa o HTTP
├── 03-monitor.sh        monitor de CPU, memória e disco (loop)
├── 04-service.sh        cria o serviço systemd do monitor
├── 05-provisionar.sh    script mestre: roda 01, 02 e 04 em sequência
├── .gitattributes       mantém os .sh com fim de linha LF
└── site/
    └── index.html       página da Memória Digital
```
 
## Como executar
 
Pré-requisito: VM Debian 13 com os dois adaptadores de rede descritos acima. Todos os comandos abaixo são executados como **root**.
 
```bash
su -
apt install -y git
git clone https://github.com/Mind-Syncc/Citizentech-Operating-Systems.git
cd Citizentech-Operating-Systems
bash 05-provisionar.sh
```
 
Ao final, a tela mostra `Provisionamento concluido` e a aplicação fica disponível, a partir do Windows, em **http://192.168.56.10**.
 
Para alterar IP, hostname, pacotes ou limites de alerta, edite apenas o `config.env`.
 
## O que cada script faz
 
| Script | Função |
|---|---|
| `01-infra.sh` | Define o hostname, ajusta o `/etc/hosts`, configura o IP fixo da `enp0s8` e testa o DNS |
| `02-app.sh` | Instala as dependências, publica a página, habilita o nginx e confirma que responde HTTP 200 |
| `03-monitor.sh` | A cada 10 segundos mede CPU, memória e disco e registra um `ALERTA` quando passa do limite (80% por padrão) |
| `04-service.sh` | Grava o serviço `citizentech-monitor` no systemd, com `Restart=always`, e confirma que está ativo |
| `05-provisionar.sh` | Executa as etapas na ordem e interrompe o provisionamento se alguma falhar |
 
Os scripts são **idempotentes**: rodar duas vezes não duplica configuração e apenas registra que o item já estava correto.
 
## Logs
 
Os scripts gravam em `/var/log/citizentech/`:
 
- `exec.log`: resultado da execução (medições, instalações, alertas).
- `audit.log`: quem iniciou e finalizou cada script.
```bash
tail -n 15 /var/log/citizentech/exec.log
tail -n 5 /var/log/citizentech/audit.log
```
 
Teste rápido do alerta, com limite baixo de propósito:
 
```bash
LIMITE_MEM=5 INTERVALO=3 bash 03-monitor.sh
```
 
## Teste de falha
 
O processo do monitor foi encerrado à força para verificar a recuperação automática:
 
```bash
kill -9 $(systemctl show -p MainPID --value citizentech-monitor)
journalctl -u citizentech-monitor -n 15 --no-pager
```
 
Resultado: o systemd registrou `Main process exited, code=killed, status=9/KILL`, agendou o reinício e o serviço voltou em cerca de 5 segundos (`RestartSec=5`), com um novo PID.
