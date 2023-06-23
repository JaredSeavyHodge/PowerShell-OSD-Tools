function Update-Drivers {
    <#
    .SYNOPSIS
    Updates the system's drivers.

    .DESCRIPTION
    Updates the system's drivers using the PSWindowsUpdate module.
    #>
    if (!(Get-Module PSWindowsUpdate -ListAvailable)) {
        try {
            Install-Module PSWindowsUpdate -Force -Scope CurrentUser
            Import-Module PSWindowsUpdate
        }
        catch {
            Write-Warning 'Unable to install PSWindowsUpdate Driver Updates'
        }
    }
    if (Get-Module PSWindowsUpdate -ListAvailable) {
        Write-Host -ForegroundColor Cyan 'Checking for Driver Updates...'
        Install-WindowsUpdate -UpdateType Driver -AcceptAll -IgnoreReboot -Verbose
        Write-Host -ForegroundColor Cyan 'Driver updates complete.'
    }
}