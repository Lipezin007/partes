<#
 Executar DENTRO da VM. Coleta as evidências de serviços, MySQL, logs e eventos.
#>
$mysqlBin = "C:\Program Files\MySQL\MySQL Server 8.4\bin"

Write-Host "== Serviços ==" -ForegroundColor Cyan
Get-Service W3SVC, MySQL* | Format-Table Name, Status, StartType -AutoSize

Write-Host "== Portas em escuta (80 em 0.0.0.0, 3306 só em 127.0.0.1) ==" -ForegroundColor Cyan
Get-NetTCPConnection -State Listen | Where-Object { $_.LocalPort -in 80, 3306 } |
  Format-Table LocalAddress, LocalPort, OwningProcess -AutoSize

Write-Host "== Logs do IIS ==" -ForegroundColor Cyan
$ult = Get-ChildItem "C:\inetpub\logs\LogFiles" -Recurse -Filter *.log | Sort-Object LastWriteTime | Select-Object -Last 1
if ($ult) { $ult.FullName; Get-Content $ult.FullName -Tail 5 }

Write-Host "== Visualizador de Eventos (erros/avisos do sistema nas últimas 24 h) ==" -ForegroundColor Cyan
Get-WinEvent -FilterHashtable @{LogName="System"; Level=2,3; StartTime=(Get-Date).AddDays(-1)} -MaxEvents 5 -ErrorAction SilentlyContinue |
  Format-Table TimeCreated, ProviderName, Id -AutoSize

Write-Host "== Consulta ao MySQL ==" -ForegroundColor Cyan
& "$mysqlBin\mysql.exe" -u root -p -e "SELECT * FROM webhost_lab.servidores;"
