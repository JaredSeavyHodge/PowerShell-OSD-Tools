function Start-AutopilotImport {
    <#
    .SYNOPSIS
        Imports the local device into Autopilot.
    .DESCRIPTION
        Imports the local device into Autopilot and assigns it to the specified group. It will wait up to 5 minutes for the import to complete and wait for the Autopilot profile to be assigned.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string]$GroupId,
        [switch]$WaitForProfile
    )

    $provider = Get-PackageProvider NuGet -ErrorAction Ignore
    if (-not $provider) {
        Write-Host -ForegroundColor DarkGray "Installing provider NuGet"
        Find-PackageProvider -Name NuGet -ForceBootstrap -IncludeDependencies
    }
    
    @("Microsoft.Graph.Authentication", 
    "Microsoft.Graph.Groups") | Foreach-Object {
        if (!(Get-Module -ListAvailable -Name $_)) {
            Write-Host -ForegroundColor DarkGray "Installing module $_"
            Install-Module -Name $_ -Scope CurrentUser -Force -WarningAction SilentlyContinue
        }
        Import-Module -Name $_ -Force
    }

    $Scopes = @(
        "Group.ReadWrite.All" # Required for adding the device to a group
        "Device.Read.All" # Required for getting the device's serial number and hash
        "DeviceManagementServiceConfig.ReadWrite.All" # Required for importing devices
    )
    Select-MgProfile -Name beta
    Connect-MgGraph -Scopes $Scopes

    try {
        try {
            $Serial = (Get-CimInstance Win32_BIOS -ErrorAction Stop).SerialNumber 
            if (Get-IsAutopilotRegistered -SerialNumber $Serial) {
                Write-Host -ForegroundColor Green "This device is already registered with Autopilot."
                return
            }
            $Hash = (Get-CimInstance -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'" -ErrorAction Stop) `
                | Select-Object -ExpandProperty DeviceHardwareData 
            $base64 = [System.Convert]::FromBase64String($hash)
        }
        catch [Microsoft.Management.Infrastructure.CimException] {
            Throw "Not able to retrieve Hardware Hash from this device. (Error Message: $($_.Exception.Message))"
        }
        catch {
            Throw "Encountered an unhandled error while getting the device's serial number and/or hash. (Error Message: $($_.Exception.Message))"
        }
        
        if ( !$Hash -or !$Serial ) {
            Throw "Unable to get the device's serial number and/or hash. (Error Message: $($_.Exception.Message))"
        }
    
        # Required Scope DeviceManagementServiceConfig.ReadWrite.All
        
        $Import = New-ImportedAutopilotMgDevice -SerialNumber $Serial -ProductKey $Serial -HardwareIdentifier $base64 -ErrorAction Stop

        # This loop will wait up to 5 minutes for the import to complete.
        Write-Host "Importing device..."
        $Count = 0
        while ( $Import.State.DeviceImportStatus -ne "complete" ) 
        {
            $Count++
            if($Count -gt 75) {
                throw "Importing the device is taking longer than usual. Check the device in Autopilot/Intune manually."
            }
            if ($Count%5 -eq 0) {
                Write-Host -ForegroundColor DarkGray "Waiting for import to finish...($($Import.State.DeviceImportStatus))"
            }
            
            $Import = Get-ImportedAutopilotMgDevice -ImportedWindowsAutopilotDeviceIdentityId $Import.Id

            if ($Import.State.DeviceImportStatus -eq "error") {
                throw "Encountered an error while importing the device. (deviceErrorCode: $($Import.State.DeviceErrorCode), deviceErrorName: $($Import.State.DeviceErrorName))"
            }
            Start-Sleep -Seconds 4
        }

        # The import's state property will hold the device registration id. Sometimes a small wait is needed before it's available.
        Start-Sleep -Seconds 5
        
        $AutopilotDevice = Get-AutopilotMgDevice -DeviceRegistrationId $Import.State.deviceRegistrationId
        
        # Continue to wait for the device to be available if necessary.
        $Count = 0
        while (!$AutopilotDevice)
        {
            $Count++
            Start-Sleep -Seconds 5
            $AutopilotDevice = Get-AutopilotMgDevice -DeviceRegistrationId $Import.State.deviceRegistrationId
            if($Count -gt 4) {
                throw "The import may have completed, however I was unable to find the device registered in Autopilot. Check the device in Autopilot/Intune manually and add it to a group."
            }
        }

        # Cleanup the import by removing it after we have the Autopilot Device Identity
        if ($AutopilotDevice)
        {
            Write-Host -ForegroundColor DarkGray "Cleaning up import..."
            Remove-ImportedAutopilotMgDevice -ImportedWindowsAutopilotDeviceIdentityId $Import.Id
        }

        # Add to group
        try {
            #Add-DeviceToMgGroup -GroupName $GroupName -AzureADDeviceId $AutopilotDevice.AzureActiveDirectoryDeviceId
            $AzureObject = Get-AzureAdMgDeviceByAzureAdDeviceId -AzureAdDeviceId $AutopilotDevice.AzureActiveDirectoryDeviceId -ErrorAction Stop
            Add-MgDeviceToAzureADGroup -DeviceId $AzureObject.id -GroupId $GroupId -ErrorAction Stop
            Write-Host -ForegroundColor Green "Device added to group ($($Script:GroupForDevice.DisplayName))."
        }
        catch {
            Write-Error "Encountered an error while adding the device to the group. You may need to manually do this step in Azure. (Error Message: $($_.Exception.Message))"        
        }
    }
    catch {
        Write-Error "Encountered an error while importing the device. (Error Message: $($_.Exception.Message))"
    }

    if ($WaitForProfile)
    {
        try {
            Wait-AutopilotProfileAssignment -Id $AutopilotDevice.Id -ErrorAction Stop
        }
        catch {
            Write-Error "Encountered an error while waiting for the Autopilot profile to be assigned. You may want to verify it's assignment before moving on. (Error Message: $($_.Exception.Message))"
        }
    }
}
