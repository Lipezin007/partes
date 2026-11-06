<#
 Executar DENTRO da VM (PowerShell como Administrador).
 Define nome, IP estático, DNS e perfil de rede.
 Hyper-V:    .\02-vm-rede-e-nome.ps1 -InterfaceAlias "Ethernet" -Gateway 192.168.100.1
 VirtualBox: .\02-vm-rede-e-nome.ps1 -InterfaceAlias "Ethernet"   (a interface host-only; sem gateway)
 Use Get-NetAdapter para ver os nomes. Reinicia a VM no final.
#>
param(
  [Parameter(Mandatory)] [string]$InterfaceAlias,
  [string]$IP = "192.168.100.10",
  [int]$Prefix = 24,
  [string]$Gateway,
  [string[]]$Dns = @("8.8.8.8","1.1.1.1")
)
$ErrorActionPreference = "Stop"

Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
  Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
Remove-NetRoute -InterfaceAlias $InterfaceAlias -DestinationPrefix 0.0.0.0/0 -Confirm:$false -ErrorAction SilentlyContinue

$p = @{ InterfaceAlias = $InterfaceAlias; IPAddress = $IP; PrefixLength = $Prefix }
if ($Gateway) { $p.DefaultGateway = $Gateway }
New-NetIPAddress @p | Out-Null
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $Dns
Set-NetConnectionProfile -InterfaceAlias $InterfaceAlias -NetworkCategory Private

ipconfig /all
Rename-Computer -NewName "WEB-SRV01" -Force -Restart
