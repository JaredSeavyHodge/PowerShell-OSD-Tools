<#
    .SYNOPSIS
    Imports the PowerShell-OSD-Tools module from GitHub from a temporary location.
    .DESCRIPTION
    Simple script to download and extract this module to a temporary location and import it.
    .NOTES
    You can use iex (Invoke-Expression) with irm (Invoke-RestMethod) to run this script directly from GitHub:
    Powershell.exe -executionpolicy bypass 'iex (irm https://raw.githubusercontent.com/JaredSeavyHodge/PowerShell-OSD-Tools/Main/PowerShell-OSD-Tools/Import-TempModule.ps1)'
#>

$ModuleUri = 'https://github.com/JaredSeavyHodge/PowerShell-OSD-Tools/archive/refs/heads/Main.zip'

Invoke-WebRequest -Uri $ModuleUri -OutFile "$env:TEMP\PowerShell-OSD-Tools.zip"

Expand-Archive -Path "$env:TEMP\PowerShell-OSD-Tools.zip" -DestinationPath "$env:TEMP\PowerShell-OSD-Tools" -Force

Import-Module -Name "$env:TEMP\PowerShell-OSD-Tools\PowerShell-OSD-Tools-Main\PowerShell-OSD-Tools\PowerShell-OSD-Tools.psd1" -Force

Get-Command -Module 'PowerShell-OSD-Tools' | Format-Table -AutoSize

Write-Host -ForegroundColor Green "PowerShell-OSD-Tools module imported from temporary location."
Write-Host -ForegroundColor Green "Calling entry command (Start-OsdPhase)."
Start-OsdPhase
