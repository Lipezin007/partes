<#
 Executar no HOST (ou outra máquina da rede) para validar o ambiente.
 Uso: .\06-testes-host.ps1 -ServerIP 192.168.100.10
#>
param([string]$ServerIP = "192.168.100.10")

Write-Host "`n== 1. ipconfig (cliente) ==" -ForegroundColor Cyan
ipconfig | Select-String "IPv4|Máscara|Mask|Gateway"

Write-Host "`n== 2. Ping ==" -ForegroundColor Cyan
Test-Connection $ServerIP -Count 2

Write-Host "`n== 3. Porta HTTP 80 (deve estar aberta) ==" -ForegroundColor Cyan
Test-NetConnection $ServerIP -Port 80

Write-Host "`n== 4. Porta MySQL 3306 (deve estar FECHADA para a rede) ==" -ForegroundColor Cyan
Test-NetConnection $ServerIP -Port 3306 -WarningAction SilentlyContinue

Write-Host "`n== 5. Requisição HTTP pelo IP ==" -ForegroundColor Cyan
$r = Invoke-WebRequest "http://$ServerIP" -UseBasicParsing
"{0} {1} | Server: {2}" -f $r.StatusCode, $r.StatusDescription, $r.Headers["Server"]
$r.Content -match "Meu Primeiro Servidor WEB"

Write-Host "`n== 6. Binding por nome (adicione '$ServerIP webhostlab.local' ao arquivo hosts) ==" -ForegroundColor Cyan
try { (Invoke-WebRequest "http://webhostlab.local" -UseBasicParsing).StatusCode } catch { "Falhou: configure o arquivo hosts" }
