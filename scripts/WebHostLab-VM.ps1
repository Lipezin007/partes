<#
 WebHost Lab - script unico para rodar DENTRO da VM (PowerShell como Administrador).

 PARTE 1 (antes do MySQL): IIS + site (HTML/CSS ja embutidos) + NTFS + firewall + IP estatico + nome WEB-SRV01.
          A VM reinicia no final.
     .\WebHostLab-VM.ps1 -Parte 1

 PARTE 2 (depois de instalar o MySQL): cria banco/tabela, restringe o MySQL, faz backup e mostra as evidencias.
     .\WebHostLab-VM.ps1 -Parte 2

 Se der erro de execucao de scripts:  Set-ExecutionPolicy -Scope Process Bypass
#>
param([ValidateSet(1, 2)] [int]$Parte = 0)

$ErrorActionPreference = "Stop"
if ($Parte -eq 0) { $Parte = [int](Read-Host "Qual parte executar? (1 = IIS/site/firewall/rede, 2 = MySQL/backup)") }

# ---------------------------------------------------------------- PARTE 1
function Parte1 {
  $nome = Read-Host "Digite seu nome completo (vai aparecer no site)"
  $pasta = "C:\Sites\WebHostLab"
  $site = "WebHostLab"

  Write-Host "`n[1/6] Instalando o IIS..." -ForegroundColor Cyan
  Install-WindowsFeature -Name Web-Server, Web-Mgmt-Tools, Web-Http-Logging -IncludeManagementTools | Out-Null
  Import-Module WebAdministration

  Write-Host "[2/6] Criando o site (HTML + CSS separados)..." -ForegroundColor Cyan
  New-Item -ItemType Directory -Force -Path $pasta | Out-Null

$html = @'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>WebHost Lab - WEB-SRV01</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <header>
    <h1>Meu Primeiro Servidor WEB</h1>
    <p class="badge">Hospedado no Internet Information Services (IIS)</p>
  </header>
  <main>
    <section class="card">
      <h2>Identifica&ccedil;&atilde;o do projeto</h2>
      <ul>
        <li><strong>Projeto:</strong> WebHost Lab &mdash; Implanta&ccedil;&atilde;o Segura de um Servidor Web com Windows Server, IIS e MySQL</li>
        <li><strong>Disciplina:</strong> Server and Data Center Administration &mdash; UniFECAF</li>
        <li><strong>Respons&aacute;vel:</strong> @@NOME@@</li>
      </ul>
    </section>
    <section class="card">
      <h2>Caracter&iacute;sticas do servidor</h2>
      <table>
        <tr><th>Item</th><th>Valor</th></tr>
        <tr><td>Nome do servidor</td><td>WEB-SRV01</td></tr>
        <tr><td>Sistema operacional</td><td>Windows Server 2022</td></tr>
        <tr><td>Hipervisor</td><td>Oracle VirtualBox</td></tr>
        <tr><td>Recursos</td><td>2 vCPU, 4 GB RAM, disco din&acirc;mico de 60 GB</td></tr>
        <tr><td>Endere&ccedil;o IP</td><td>192.168.100.10 (est&aacute;tico)</td></tr>
        <tr><td>Servidor web</td><td>IIS &mdash; porta 80 (HTTP)</td></tr>
        <tr><td>Banco de dados</td><td>MySQL (acesso restrito ao pr&oacute;prio servidor)</td></tr>
      </table>
    </section>
    <section class="card">
      <h2>Status</h2>
      <p class="ok">&#10003; Site publicado com sucesso no IIS, separado da p&aacute;gina padr&atilde;o.</p>
    </section>
  </main>
  <footer>
    <p>WebHost Lab &middot; ambiente de laborat&oacute;rio em rede isolada &middot; WebCore Solutions</p>
  </footer>
</body>
</html>
'@
$css = @'
:root { --azul: #0b4f8a; --azul-escuro: #082f54; --fundo: #f2f5f9; --verde: #1b7f3b; }
* { box-sizing: border-box; }
body { margin: 0; font-family: "Segoe UI", Arial, sans-serif; background: var(--fundo); color: #1d2733; line-height: 1.5; }
header { background: linear-gradient(135deg, var(--azul-escuro), var(--azul)); color: #fff; text-align: center; padding: 48px 16px; }
header h1 { margin: 0 0 12px; font-size: 2.2rem; }
.badge { display: inline-block; margin: 0; padding: 6px 16px; border-radius: 999px; background: rgba(255,255,255,0.18); font-size: 0.95rem; }
main { max-width: 820px; margin: 32px auto; padding: 0 16px; }
.card { background: #fff; border-radius: 8px; padding: 20px 24px; margin-bottom: 20px; box-shadow: 0 1px 4px rgba(0,0,0,0.12); }
.card h2 { margin-top: 0; color: var(--azul); }
ul { padding-left: 20px; }
table { width: 100%; border-collapse: collapse; }
th, td { text-align: left; padding: 8px 10px; border-bottom: 1px solid #dde3ea; }
th { background: var(--fundo); }
.ok { color: var(--verde); font-weight: 600; margin: 0; }
footer { text-align: center; padding: 20px 16px 32px; color: #5b6773; font-size: 0.85rem; }
'@
  $nomeHtml = [System.Net.WebUtility]::HtmlEncode($nome)
  Set-Content -Path "$pasta\index.html" -Value $html.Replace("@@NOME@@", $nomeHtml) -Encoding UTF8
  Set-Content -Path "$pasta\style.css" -Value $css -Encoding UTF8

  Write-Host "[3/6] Permissoes NTFS e publicacao no IIS..." -ForegroundColor Cyan
  icacls $pasta /inheritance:r | Out-Null
  icacls $pasta /grant "SYSTEM:(OI)(CI)F" "Administrators:(OI)(CI)F" "IIS_IUSRS:(OI)(CI)RX" "IUSR:(OI)(CI)RX" | Out-Null
  Stop-Website -Name "Default Web Site" -ErrorAction SilentlyContinue
  if (Get-Website -Name $site -ErrorAction SilentlyContinue) { Remove-Website -Name $site }
  New-Website -Name $site -PhysicalPath $pasta -Port 80 -IPAddress "*" | Out-Null
  New-WebBinding -Name $site -Protocol http -Port 80 -HostHeader "webhostlab.local"
  Start-Website -Name $site
  Get-Website | Format-Table Name, ID, State, PhysicalPath -AutoSize
  Get-Service W3SVC | Format-Table Name, Status, StartType
  $logDir = [Environment]::ExpandEnvironmentVariables((Get-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -Name logFile.directory).Value)
  Write-Host "Logs do IIS: $logDir\W3SVC<ID do site>" -ForegroundColor Yellow

  Write-Host "[4/6] Firewall (so as portas necessarias)..." -ForegroundColor Cyan
  Set-NetFirewallProfile -Profile Domain, Private, Public -Enabled True
  Get-NetFirewallRule -DisplayName "WebHostLab*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
  New-NetFirewallRule -DisplayName "WebHostLab - HTTP 80" -Direction Inbound -Protocol TCP -LocalPort 80 -RemoteAddress 192.168.100.0/24 -Action Allow -Profile Any | Out-Null
  New-NetFirewallRule -DisplayName "WebHostLab - ICMPv4 Echo" -Direction Inbound -Protocol ICMPv4 -IcmpType 8 -RemoteAddress 192.168.100.0/24 -Action Allow -Profile Any | Out-Null
  New-NetFirewallRule -DisplayName "WebHostLab - Bloquear MySQL 3306" -Direction Inbound -Protocol TCP -LocalPort 3306 -Action Block -Profile Any | Out-Null
  auditpol /set /subcategory:"Logon" /success:enable /failure:enable | Out-Null
  Get-NetFirewallRule -DisplayName "WebHostLab*" | Format-Table DisplayName, Enabled, Direction, Action -AutoSize

  Write-Host "[5/6] IP estatico na placa host-only..." -ForegroundColor Cyan
  # a placa host-only e a que NAO tem IP 10.0.2.x (a NAT)
  $alvo = Get-NetAdapter | Where-Object Status -eq "Up" | Where-Object {
    -not (Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object IPAddress -like "10.0.2.*")
  } | Select-Object -First 1
  if (-not $alvo) { Get-NetAdapter | Format-Table Name, Status, InterfaceDescription; throw "Nao achei a placa host-only. Confira se o Adaptador 2 (Host-only) esta ligado na VM." }
  $alias = $alvo.Name
  Write-Host "Placa host-only: $alias" -ForegroundColor Yellow
  Get-NetIPAddress -InterfaceAlias $alias -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
  New-NetIPAddress -InterfaceAlias $alias -IPAddress 192.168.100.10 -PrefixLength 24 | Out-Null
  Set-DnsClientServerAddress -InterfaceAlias $alias -ServerAddresses 8.8.8.8, 1.1.1.1
  Set-NetConnectionProfile -InterfaceAlias $alias -NetworkCategory Private
  ipconfig /all

  Write-Host "`n[6/6] Renomeando para WEB-SRV01 e reiniciando em 10 s..." -ForegroundColor Cyan
  Start-Sleep -Seconds 10
  Rename-Computer -NewName "WEB-SRV01" -Force -Restart
}

# ---------------------------------------------------------------- PARTE 2
function Parte2 {
  $exe = Get-ChildItem "C:\Program Files\MySQL\MySQL Server *\bin\mysql.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $exe) { throw "mysql.exe nao encontrado. Instale o MySQL Server antes da Parte 2." }
  $bin = $exe.DirectoryName
  $svc = Get-Service "MySQL*" | Select-Object -First 1
  Write-Host "MySQL: $bin | servico: $($svc.Name) ($($svc.Status))" -ForegroundColor Yellow

  $sec = Read-Host "Senha do usuario root do MySQL" -AsSecureString
  $env:MYSQL_PWD = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
  $secApp = Read-Host "Crie uma senha forte para o usuario app_web (usuario limitado da aplicacao)" -AsSecureString
  $senhaApp = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secApp))

  try {
    Write-Host "`n[1/4] Banco, tabela e registros..." -ForegroundColor Cyan
$sql = @'
CREATE DATABASE IF NOT EXISTS webhost_lab CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE webhost_lab;
CREATE TABLE IF NOT EXISTS servidores (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(50) NOT NULL,
  funcao VARCHAR(100) NOT NULL,
  ip VARCHAR(15) NOT NULL,
  sistema VARCHAR(50) NOT NULL,
  criado_em TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
TRUNCATE TABLE servidores;
INSERT INTO servidores (nome, funcao, ip, sistema) VALUES
  ('WEB-SRV01', 'Servidor web (IIS)', '192.168.100.10', 'Windows Server 2022'),
  ('WEB-SRV01', 'Banco de dados (MySQL)', '192.168.100.10', 'Windows Server 2022'),
  ('HOST-LAB', 'Hospedeiro VirtualBox', '192.168.100.1', 'Windows 11');
CREATE USER IF NOT EXISTS 'app_web'@'localhost' IDENTIFIED BY '@@SENHA@@';
GRANT SELECT, INSERT, UPDATE, DELETE ON webhost_lab.* TO 'app_web'@'localhost';
FLUSH PRIVILEGES;
'@
    $sql.Replace("@@SENHA@@", $senhaApp.Replace("'", "''")) | & "$bin\mysql.exe" -u root --default-character-set=utf8mb4
    if ($LASTEXITCODE -ne 0) { throw "Falha ao executar o SQL (senha do root correta?)." }

    Write-Host "[2/4] Restringindo o MySQL a localhost (bind-address)..." -ForegroundColor Cyan
    $ini = Get-ChildItem "C:\ProgramData\MySQL\MySQL Server *\my.ini" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($ini) {
      $txt = Get-Content $ini.FullName
      if (-not ($txt -match "^\s*bind-address")) {
        $txt = $txt -replace "^\[mysqld\]\s*$", "[mysqld]`r`nbind-address=127.0.0.1"
        Set-Content -Path $ini.FullName -Value $txt
        Restart-Service $svc.Name
      }
    } else { Write-Host "my.ini nao encontrado: adicione bind-address=127.0.0.1 na secao [mysqld] manualmente." -ForegroundColor Red }

    Write-Host "[3/4] Backup do site e do banco em C:\Backup..." -ForegroundColor Cyan
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    New-Item -ItemType Directory -Force -Path C:\Backup | Out-Null
    $zip = "C:\Backup\site-WebHostLab-$stamp.zip"
    $dump = "C:\Backup\webhost_lab-$stamp.sql"
    Compress-Archive -Path "C:\Sites\WebHostLab\*" -DestinationPath $zip -Force
    & "$bin\mysqldump.exe" -u root --databases webhost_lab --routines --single-transaction --result-file=$dump
    Get-ChildItem C:\Backup | Format-Table Name, Length, LastWriteTime -AutoSize
    Select-String -Path $dump -Pattern "CREATE TABLE", "INSERT INTO" | Select-Object -First 2 | ForEach-Object { $_.Line.Substring(0, [Math]::Min(80, $_.Line.Length)) }
    $tmp = "$env:TEMP\teste-restore-$stamp"
    Expand-Archive $zip -DestinationPath $tmp -Force
    Write-Host "Teste de restauracao do ZIP:" -ForegroundColor Yellow
    Get-ChildItem $tmp | Format-Table Name, Length
    Remove-Item $tmp -Recurse -Force

    Write-Host "[4/4] Evidencias..." -ForegroundColor Cyan
    Get-Service W3SVC, "MySQL*" | Format-Table Name, Status, StartType -AutoSize
    Get-NetTCPConnection -State Listen | Where-Object { $_.LocalPort -in 80, 3306 } | Format-Table LocalAddress, LocalPort, OwningProcess -AutoSize
    & "$bin\mysql.exe" -u root -e "SELECT * FROM webhost_lab.servidores;"
    $log = Get-ChildItem "C:\inetpub\logs\LogFiles" -Recurse -Filter *.log -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -Last 1
    if ($log) { Write-Host "Log do IIS: $($log.FullName)" -ForegroundColor Yellow; Get-Content $log.FullName -Tail 5 }
    Get-WinEvent -FilterHashtable @{LogName = "System"; Level = 2, 3; StartTime = (Get-Date).AddDays(-1)} -MaxEvents 5 -ErrorAction SilentlyContinue | Format-Table TimeCreated, ProviderName, Id -AutoSize
  }
  finally { Remove-Item Env:\MYSQL_PWD -ErrorAction SilentlyContinue; $senhaApp = $null }
}

if ($Parte -eq 1) { Parte1 } else { Parte2 }
