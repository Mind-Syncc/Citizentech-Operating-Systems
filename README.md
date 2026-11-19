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
| O que cada parte faz | **Operating Systems:** infraestrutura Linux automatizada que hospeda a aplicação web |
| Indicador de impacto | Número de mensagens analisadas pela aplicação e de sinais de golpe identificados em cada uma |
| ODS conectados | **ODS 10 (redução das desigualdades):** diminui a distância digital de quem está começando a usar o celular. **ODS 9 (indústria, inovação e infraestrutura):** infraestrutura automatizada, monitorada e reproduzível. **ODS 11 (cidades e comunidades sustentáveis):** torna o ambiente digital mais seguro para as pessoas idosas |
 
### Contexto
 
Segundo o TIC Domicílios 2025 (Cetic.br), 59% das pessoas com 60 anos ou mais usam internet, e a falta de habilidade é o principal motivo apontado por quem não usa.
 
## Integrantes
 
| Nome | RM |
|---|---|
| Heloísa Fleury Jardim | RM556378 |
| Juan Fuentes Rufino | RM557673 |
| Rickelmyn de Souza Ruescas | RM556055 |
| Paulo Henrique Monteiro Golovanevsky | RM555300 |
| Pedro Henrique Silva Batista | RM558137 |
 
## Ambiente
 
- Máquina virtual **Debian 13**, no VirtualBox.
- **Adaptador 1 (NAT):** saída para a internet, usada para instalar pacotes.
- **Adaptador 2 (host-only):** rede privada entre o Windows e a VM. A interface `enp0s8` recebe o IP fixo `192.168.56.10`, e é por ele que a aplicação é acessada.
> Em instalações com interface gráfica, o NetworkManager pode deixar a placa NAT desconectada. Se faltar internet, ative-a com `nmcli device connect enp0s3`.
 
## Estrutura do repositório
 
```
.
├── evidencias/          capturas de tela de evidência do projeto funcionando
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
 
Pré-requisito: VM Debian 13 com os dois adaptadores de rede descritos acima e acesso à internet pela NAT. Todos os comandos abaixo são executados como **root**.
 
```bash
su -
apt install -y git
git clone https://github.com/Mind-Syncc/Citizentech-Operating-Systems.git
cd Citizentech-Operating-Systems
bash 05-provisionar.sh
```
 
Ao final, a tela mostra `Provisionamento concluido` e a aplicação fica disponível, a partir do Windows, em **http://192.168.56.10**.
 
- Para alterar IP, hostname, pacotes ou limites de alerta, edite apenas o `config.env`.
- Não mova nem apague a pasta clonada depois do provisionamento: o serviço do monitor aponta para o caminho dela.
## O que cada script faz
 
| Script | Função |
|---|---|
| `01-infra.sh` | Define o hostname, ajusta o `/etc/hosts`, configura o IP fixo da `enp0s8` e testa o DNS |
| `02-app.sh` | Instala as dependências, publica a página, habilita o nginx e confirma que responde HTTP 200 |
| `03-monitor.sh` | A cada 10 segundos mede CPU, memória e disco e registra um `ALERTA` quando passa do limite (80% por padrão) |
| `04-service.sh` | Grava o serviço `citizentech-monitor` no systemd, com `Restart=always`, e confirma que está ativo |
| `05-provisionar.sh` | Executa as etapas na ordem e interrompe o provisionamento se alguma falhar |
 
Os scripts são **idempotentes**: rodar duas vezes não duplica configuração e apenas registra que o item já estava correto.
 
## Serviço systemd
 
O `04-service.sh` gera o arquivo `/etc/systemd/system/citizentech-monitor.service` com este conteúdo (o caminho do `ExecStart` é a pasta onde o repositório foi clonado):
 
```ini
[Unit]
Description=Monitor CitizenTech (CPU, memoria e disco)
After=network.target
 
[Service]
Type=simple
ExecStart=<pasta-do-repositorio>/03-monitor.sh
Restart=always
RestartSec=5
 
[Install]
WantedBy=multi-user.target
```
 
- `WantedBy=multi-user.target`: inicia junto com o sistema.
- `Restart=always` e `RestartSec=5`: se o processo cair, o systemd o reinicia depois de 5 segundos.
Controle do serviço:
 
```bash
systemctl status citizentech-monitor
systemctl stop citizentech-monitor
systemctl start citizentech-monitor
systemctl restart citizentech-monitor
```
 
## Logs
 
Os scripts gravam em `/var/log/citizentech/`:
 
- `exec.log`: resultado da execução (instalações, configurações, medições, alertas e erros).
- `audit.log`: quem iniciou e finalizou cada script.
```bash
tail -n 15 /var/log/citizentech/exec.log
tail -n 5 /var/log/citizentech/audit.log
```
 
Para acompanhar o monitor em tempo real: `tail -f /var/log/citizentech/exec.log`.
 
## Testes de alerta e de falha
 
**1. Alerta de consumo elevado.** O monitor foi executado com um limite baixo de propósito, para forçar o alerta:
 
```bash
LIMITE_MEM=5 INTERVALO=3 bash 03-monitor.sh
```
 
Resultado: a memória estava em 7%, acima do limite de 5%, e cada medição gerou `ALERTA: Memoria em 7% (limite 5%)` na tela e no `exec.log`, enquanto CPU e disco, abaixo do limite, ficaram como `INFO` só no log.
 
**2. Falha do serviço de monitoramento.** O processo do monitor foi encerrado à força:
 
```bash
kill -9 $(systemctl show -p MainPID --value citizentech-monitor)
journalctl -u citizentech-monitor -n 15 --no-pager
```
 
Resultado: o systemd registrou `Main process exited, code=killed, status=9/KILL`, agendou o reinício e o serviço voltou em cerca de 5 segundos (`RestartSec=5`), com um novo PID. A queda aparece no `journalctl`, porque o `kill -9` não pode ser interceptado pelo script e, por isso, não entra no `audit.log`.

## Evidências
 
A pasta `evidencias/` reúne as capturas de tela que comprovam o funcionamento dos scripts, dos serviços, do monitoramento e da aplicação (provisionamento completo, segunda execução idempotente, aplicação no navegador em `http://192.168.56.10`, logs, `systemctl status` e testes de alerta e de falha).
 
## Decisões e limitações
 
- **DNS:** a resolução de nomes vem do DHCP da rede NAT do VirtualBox. O `01-infra.sh` valida que o DNS funciona, mas não define servidores próprios.
- **Aplicação:** o nginx usa a configuração padrão e serve a página estática da pasta `site/`.
- **Serviço systemd:** o arquivo do serviço é gerado pelo `04-service.sh`, e não mantido como arquivo separado, para que o caminho do `ExecStart` acompanhe a pasta onde o repositório foi clonado.
- **Usuários e permissões:** os serviços rodam como root, e a página é publicada com permissão `644`.
- **Análise de mensagens da página:** é uma demonstração, que roda no navegador com regras simples (pressa, links encurtados, pedido de dados). Não usa o modelo de Machine Learning da disciplina de IA e não envia nem guarda nada do que o usuário digita.
- O projeto não usa dados pessoais reais.
