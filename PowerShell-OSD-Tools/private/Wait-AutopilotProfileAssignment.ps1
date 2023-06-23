function Wait-AutopilotProfileAssignment
{
    <#
        .SYNOPSIS
            Waits for the Autopilot profile to be assigned to the device.
        .DESCRIPTION
            Waits for the Autopilot profile to be assigned to the device by Autopilot device Id.  If autopilot device id is not specified, the local device is used.
    #>
    [CmdLetBinding()]
    param
    (
        [Parameter(HelpMessage="The Autopilot Device Id.")]
        [string]$Id
    )

    $AutopilotDevice

    try {
        Sync-Autopilot -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to sync Autopilot. Waiting for profile assignment may take longer than normal.$($_.Exception.Message))"
    }

    if(!$Id)
    {
        $Serial = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber
        $AutopilotDevice = Get-AutopilotMgDevice -SerialNumber $Serial
        $Id = $AutopilotDevice.Id
    }
    else
    {
        $AutopilotDevice = Get-AutopilotMgDevice -DeviceRegistrationId $Id
    }

    # Wait for assignment for up to 10 minutes
    $Count = 0
    try {
        while (!$AutopilotDevice.DeploymentProfileAssignmentStatus.ToString().StartsWith("assigned")) {
            $Count++
            if($Count -gt 150) {
                throw "Assigning a profile to the device is taking longer than usual. Check the device in Autopilot/Intune manually."
            }
            if ($Count%5 -eq 0) {
                Write-Host -ForegroundColor DarkGray "Waiting for profile assignment to complete..."
            }
            Start-Sleep -Seconds 4
            $AutopilotDevice = Get-AutopilotMgDevice -DeviceRegistrationId $Id
        }
        Write-Host -ForegroundColor Green "Profile assignment complete."
    }
    catch {
        throw $_
    }
}
