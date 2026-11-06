<#
 Executar DENTRO da VM (PowerShell como Administrador).
 Backup do site (ZIP) e do banco (mysqldump). Pede a senha do MySQL de forma segura (não fica no script).
#>
param(
  [string]$SiteDir = "D:\Sites\WebHostLab",
  [string]$BackupDir = "C:\Backup",
  [string]$MysqlBin = "C:\Program Files\MySQL\MySQL Server 8.4\bin",
  [string]$DbUser = "root"
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path $SiteDir)) { $SiteDir = "C:\Sites\WebHostLab" }
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

# 1) Site
$zip = "$BackupDir\site-WebHostLab-$stamp.zip"
Compress-Archive -Path "$SiteDir\*" -DestinationPath $zip -Force
Write-Host "Backup do site: $zip" -ForegroundColor Green

# 2) Banco
$sql = "$BackupDir\webhost_lab-$stamp.sql"
$cred = Read-Host "Senha do usuario MySQL $DbUser" -AsSecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($cred))
$env:MYSQL_PWD = $plain
try {
  & "$MysqlBin\mysqldump.exe" -u $DbUser --databases webhost_lab --routines --single-transaction --result-file=$sql
} finally { Remove-Item Env:\MYSQL_PWD; $plain = $null }
Write-Host "Backup do banco: $sql" -ForegroundColor Green

# 3) Teste da cópia: lista arquivos, confere o dump e restaura o ZIP em pasta temporária
Get-ChildItem $BackupDir | Format-Table Name, Length, LastWriteTime -AutoSize
Select-String -Path $sql -Pattern "CREATE TABLE","INSERT INTO" | Select-Object -First 3 | ForEach-Object { $_.Line }
$tmp = "$env:TEMP\teste-restore-$stamp"
Expand-Archive $zip -DestinationPath $tmp -Force
Get-ChildItem $tmp | Format-Table Name, Length
Remove-Item $tmp -Recurse -Force
