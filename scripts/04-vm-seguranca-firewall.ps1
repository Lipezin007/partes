<#
 Executar DENTRO da VM (PowerShell como Administrador).
 Firewall apenas para as portas necessárias; MySQL (3306) fica bloqueado para a rede.
 Opcional: -PermitirPing libera ICMP para facilitar o teste de conectividade.
#>
param([switch]$PermitirPing)
$ErrorActionPreference = "Stop"

Set-NetFirewallProfile -Profile Domain,Private,Public -Enabled True

# HTTP (80) somente da sub-rede do laboratório
New-NetFirewallRule -DisplayName "WebHostLab - HTTP 80" -Direction Inbound -Protocol TCP `
  -LocalPort 80 -RemoteAddress 192.168.100.0/24 -Action Allow -Profile Any | Out-Null

# RDP (3389) somente da sub-rede do laboratório (administração remota)
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
Set-NetFirewallRule -DisplayGroup "Remote Desktop" -RemoteAddress 192.168.100.0/24 -ErrorAction SilentlyContinue

# MySQL: bloqueio explícito de entrada na 3306 (acesso apenas local)
New-NetFirewallRule -DisplayName "WebHostLab - Bloquear MySQL 3306" -Direction Inbound -Protocol TCP `
  -LocalPort 3306 -Action Block | Out-Null

if ($PermitirPing) {
  New-NetFirewallRule -DisplayName "WebHostLab - ICMPv4 Echo" -Direction Inbound -Protocol ICMPv4 `
    -IcmpType 8 -RemoteAddress 192.168.100.0/24 -Action Allow | Out-Null
}

# Auditoria de logon (success/failure) no log de Segurança
auditpol /set /subcategory:"Logon" /success:enable /failure:enable | Out-Null

Get-NetFirewallRule -DisplayName "WebHostLab*" | Format-Table DisplayName, Enabled, Direction, Action -AutoSize
