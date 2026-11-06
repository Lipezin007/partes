<#
 Executar no HOST (Windows 10/11 Pro, Enterprise ou Education) como Administrador.
 Cria switch interno + NAT, a VM WEB-SRV01 e anexa a ISO.
 Uso: .\01a-host-criar-vm-hyperv.ps1 -IsoPath "C:\ISO\WindowsServer2022.iso"
#>
param(
  [Parameter(Mandatory)] [string]$IsoPath,
  [string]$VmName = "WEB-SRV01",
  [string]$VmRoot = "C:\HyperV",
  [string]$SwitchName = "vSwitch-WebHostLab"
)
$ErrorActionPreference = "Stop"

Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart | Out-Null

# Switch interno + NAT (rede isolada; a VM acessa a internet apenas para atualizações)
if (-not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) {
  New-VMSwitch -Name $SwitchName -SwitchType Internal | Out-Null
}
$idx = (Get-NetAdapter | Where-Object Name -like "*$SwitchName*").ifIndex
if (-not (Get-NetIPAddress -InterfaceIndex $idx -IPAddress 192.168.100.1 -ErrorAction SilentlyContinue)) {
  New-NetIPAddress -IPAddress 192.168.100.1 -PrefixLength 24 -InterfaceIndex $idx | Out-Null
}
if (-not (Get-NetNat -Name "WebHostLabNAT" -ErrorAction SilentlyContinue)) {
  New-NetNat -Name "WebHostLabNAT" -InternalIPInterfaceAddressPrefix 192.168.100.0/24 | Out-Null
}

# VM: 2 vCPU, 4 GB, disco dinâmico de 60 GB, Geração 2
New-Item -ItemType Directory -Force -Path "$VmRoot\$VmName" | Out-Null
New-VM -Name $VmName -Generation 2 -MemoryStartupBytes 4GB `
  -NewVHDPath "$VmRoot\$VmName\$VmName.vhdx" -NewVHDSizeBytes 60GB `
  -Path $VmRoot -SwitchName $SwitchName | Out-Null
Set-VMProcessor -VMName $VmName -Count 2
Set-VMMemory -VMName $VmName -DynamicMemoryEnabled $false
Add-VMDvdDrive -VMName $VmName -Path $IsoPath
$dvd = Get-VMDvdDrive -VMName $VmName
Set-VMFirmware -VMName $VmName -FirstBootDevice $dvd

Start-VM -Name $VmName
Get-VM -Name $VmName | Format-List Name, State, ProcessorCount, MemoryStartup, Generation
Write-Host "VM criada. Abra o console (vmconnect localhost $VmName) e instale o Windows Server 2022." -ForegroundColor Green
