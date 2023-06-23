function Update-Windows {
    <#
    .SYNOPSIS
    Updates the Windows system.

    .DESCRIPTION
    Updates the Windows system using the PSWindowsUpdate module.
    #>
    if (!(Get-Module PSWindowsUpdate -ListAvailable)) {
        try {
            Install-Module PSWindowsUpdate -Force -Scope CurrentUser
            Import-Module PSWindowsUpdate
        }
        catch {
            Write-Warning 'Unable to install PSWindowsUpdate Windows Updates'
        }
    }
    if (Get-Module PSWindowsUpdate -ListAvailable) {
        Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
        Write-Host -ForegroundColor Cyan 'Checking for Windows Updates...'
        Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -NotTitle 'Preview' -NotKBArticleID 'KB890830','KB5005463','KB4481252' -Verbose
        Write-Host -ForegroundColor Cyan 'Windows updates complete.'
    }
}