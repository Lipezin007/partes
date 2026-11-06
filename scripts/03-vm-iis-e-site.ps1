<#
 Executar DENTRO da VM (PowerShell como Administrador).
 Instala o IIS, cria o diretório exclusivo, aplica NTFS, publica o site WebHostLab (porta 80).
 Antes: copie index.html e style.css para C:\Temp\site\ dentro da VM.
#>
param(
  [string]$Origem = "C:\Temp\site",
  [string]$Pasta = "D:\Sites\WebHostLab",
  [string]$SiteName = "WebHostLab",
  [string]$HostHeader = "webhostlab.local"
)
$ErrorActionPreference = "Stop"

Install-WindowsFeature -Name Web-Server, Web-Mgmt-Tools, Web-Http-Logging -IncludeManagementTools | Out-Null
Import-Module WebAdministration

# Diretório do site: usa D: se existir, senão C:\Sites (separado de C:\inetpub e do sistema)
if (-not (Test-Path (Split-Path $Pasta -Qualifier))) { $Pasta = "C:\Sites\WebHostLab" }
New-Item -ItemType Directory -Force -Path $Pasta | Out-Null
Copy-Item "$Origem\*" $Pasta -Force

# NTFS: remove herança; Administradores/SYSTEM controle total; IIS_IUSRS e IUSR somente leitura
icacls $Pasta /inheritance:r | Out-Null
icacls $Pasta /grant "SYSTEM:(OI)(CI)F" "Administrators:(OI)(CI)F" "IIS_IUSRS:(OI)(CI)RX" "IUSR:(OI)(CI)RX" | Out-Null

# O Default Web Site é parado para não conflitar na porta 80 (conteúdo separado da página padrão)
Stop-Website -Name "Default Web Site" -ErrorAction SilentlyContinue

if (Get-Website -Name $SiteName -ErrorAction SilentlyContinue) { Remove-Website -Name $SiteName }
New-Website -Name $SiteName -PhysicalPath $Pasta -Port 80 -IPAddress "*" | Out-Null
# binding adicional por nome (para testes com arquivo hosts)
New-WebBinding -Name $SiteName -Protocol http -Port 80 -HostHeader $HostHeader

# Logs
$logDir = (Get-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -Name logFile.directory).Value
Write-Host "Logs do IIS: $([Environment]::ExpandEnvironmentVariables($logDir))\W3SVC<ID do site>" -ForegroundColor Cyan
Get-Website | Format-Table Name, ID, State, PhysicalPath, Bindings -AutoSize
Get-Service W3SVC | Format-Table Name, Status, StartType
