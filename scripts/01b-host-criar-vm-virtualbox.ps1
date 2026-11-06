<#
 ALTERNATIVA ao Hyper-V (somente com autorização do professor).
 Executar no HOST (inclusive Windows Home) com o VirtualBox instalado.
 Cria a VM WEB-SRV01 com: adaptador 1 = Host-Only (192.168.100.1/24), adaptador 2 = NAT (internet p/ atualizações).
 Uso: .\01b-host-criar-vm-virtualbox.ps1 -IsoPath "C:\ISO\WindowsServer2022.iso"
#>
param(
  [Parameter(Mandatory)] [string]$IsoPath,
  [string]$VmName = "WEB-SRV01",
  [string]$VmRoot = "$env:USERPROFILE\VirtualBox VMs"
)
$ErrorActionPreference = "Stop"
$vb = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

# Interface host-only com IP 192.168.100.1
$out = & $vb hostonlyif create
$ifName = ($out | Select-String "'(.+)'").Matches[0].Groups[1].Value
& $vb hostonlyif ipconfig "$ifName" --ip 192.168.100.1 --netmask 255.255.255.0

& $vb createvm --name $VmName --ostype Windows2022_64 --register --basefolder $VmRoot
& $vb modifyvm $VmName --cpus 2 --memory 4096 --vram 128 --firmware efi `
  --nic1 hostonly --hostonlyadapter1 "$ifName" --nic2 nat
& $vb createmedium disk --filename "$VmRoot\$VmName\$VmName.vdi" --size 61440 --variant Standard   # 60 GB dinâmico
& $vb storagectl $VmName --name "SATA" --add sata --controller IntelAhci
& $vb storageattach $VmName --storagectl "SATA" --port 0 --device 0 --type hdd --medium "$VmRoot\$VmName\$VmName.vdi"
& $vb storageattach $VmName --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium $IsoPath
& $vb startvm $VmName
Write-Host "VM criada. Instale o Windows Server 2022 pelo console do VirtualBox." -ForegroundColor Green
