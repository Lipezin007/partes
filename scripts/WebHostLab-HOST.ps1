<#
 WebHost Lab - script para rodar no NOTEBOOK (host), PowerShell como Administrador.
 Depois que a VM WEB-SRV01 estiver com IP 192.168.100.10, o IIS e o MySQL prontos.
     .\WebHostLab-HOST.ps1
 Se der erro de execucao de scripts:  Set-ExecutionPolicy -Scope Process Bypass
#>
$ip = "192.168.100.10"

Write-Host "`n== IP do host na rede do laboratorio (deve existir 192.168.100.1) ==" -ForegroundColor Cyan
ipconfig | Select-String "192.168.100"

# binding por nome: webhostlab.local -> IP do servidor
$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
if (-not (Select-String -Path $hosts -Pattern "webhostlab.local" -Quiet)) {
  Add-Content -Path $hosts -Value "`r`n$ip  webhostlab.local"
  Write-Host "Entrada webhostlab.local adicionada ao arquivo hosts." -ForegroundColor Yellow
}

Write-Host "`n== 1. Ping ==" -ForegroundColor Cyan
Test-Connection $ip -Count 2

Write-Host "`n== 2. Porta HTTP 80 (esperado: True) ==" -ForegroundColor Cyan
Test-NetConnection $ip -Port 80 | Format-List ComputerName, RemotePort, InterfaceAlias, SourceAddress, TcpTestSucceeded

Write-Host "`n== 3. Porta MySQL 3306 (esperado: False, bloqueada) ==" -ForegroundColor Cyan
Test-NetConnection $ip -Port 3306 -WarningAction SilentlyContinue | Format-List ComputerName, RemotePort, TcpTestSucceeded

Write-Host "`n== 4. Requisicao HTTP pelo IP ==" -ForegroundColor Cyan
$r = Invoke-WebRequest "http://$ip" -UseBasicParsing
"{0} {1} | Server: {2} | contem o texto: {3}" -f $r.StatusCode, $r.StatusDescription, $r.Headers["Server"], ($r.Content -match "Meu Primeiro Servidor WEB")
$c = Invoke-WebRequest "http://$ip/style.css" -UseBasicParsing
"style.css: {0}" -f $c.StatusCode

Write-Host "`n== 5. Binding por nome ==" -ForegroundColor Cyan
try { "webhostlab.local: " + (Invoke-WebRequest "http://webhostlab.local" -UseBasicParsing).StatusCode } catch { "Falhou: " + $_.Exception.Message }

Start-Process "http://$ip"
