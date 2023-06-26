function Start-AutoProcess
{
    [CmdletBinding()]
    param (
        [Parameter()][string]$ComputerName,
        [Parameter()][string]$GroupId,
        [Parameter()][switch]$UpdateWindows,
        [Parameter()][switch]$UpdateDrivers,
        [Parameter()][switch]$RegisterAutopilot,
        [Parameter()][switch]$RSAT,
        [Parameter()][switch]$PrintManagement,
        [Parameter()][switch]$Google,
        [Parameter()][switch]$Intune,
        [Parameter()][switch]$Settings,
        [Parameter()][switch]$Reboot
    )
    [bool]$isRegistered = $false

    if($RSAT) {Install-Rsat}

    if($PrintManagement) {
        Add-Capability -Name "Print.Management*"
        Start-Process "C:\Windows\System32\gpedit.msc" -ErrorAction SilentlyContinue
    }

    if($Google) {Start-Process -FilePath "msedge" -ArgumentList "www.google.com"}
    
    if($Intune) {Start-Process -FilePath "msedge" -ArgumentList "endpoint.microsoft.com", "--inprivate"}

    if($Settings) {Start-Process -FilePath "ms-settings:"}
    
    if ($UpdateWindows -or $UpdateDrivers)
    {   
        if($RegisterAutopilot)
        {
            # Modified Get-WindowsAutopilotInfo in this module.
            # Get-WindowsAutoPilotInfoMod -Online -AddToGroup $GroupName
            Start-AutopilotImport -GroupId $GroupId
            $isRegistered = $true
        }
        if($UpdateWindows)
        {
            Update-Windows
        }
        if($UpdateDrivers)
        {
            Update-Drivers
        }
    }

    if($isRegistered)
    {
        #Get-WindowsAutoPilotInfoMod -AssignThisDeviceOnly
        Wait-AutopilotProfileAssignment
    }
    elseif ($RegisterAutopilot)
    {
        #Get-WindowsAutoPilotInfoMod -Online -Assign -AddToGroup $GroupName
        Start-AutopilotImport -GroupId $GroupId -WaitForProfile
    }

    if ($ComputerName)
    {
        Rename-Computer -NewName $ComputerName -WarningAction SilentlyContinue
        Write-Host -ForegroundColor Green "Computer renamed to $ComputerName"
        if(-not $Reboot) {
            Write-Host -ForegroundColor Green "Please reboot to complete the rename."
        }
    }

    if($Reboot)
    {
        Restart-Computer -Force
    }
}