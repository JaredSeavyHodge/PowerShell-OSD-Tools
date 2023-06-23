try
{
    Import-Module "Microsoft.Graph.Authentication" -ErrorAction Stop
}
catch 
{ 
    Install-Module "Microsoft.Graph.Authentication" -Scope CurrentUser -Force -WarningAction SilentlyContinue 
}

function Sync-Autopilot
{
    <#
        .SYNOPSIS
            Syncs Windows Autopilot devices from the Microsoft Graph API.
        .DESCRIPTION
            Syncs Windows Autopilot devices from the Microsoft Graph API.
        .EXAMPLE
            Sync-Autopilot
        .NOTES
            Equivalent Graph SDK Command: Sync-MgDeviceManagementWindowsAutopilotSetting
            URI: https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotSettings/sync
            Method: POST
            Scope: {DeviceManagementServiceConfig.ReadWrite.All}
    #>

    [CmdletBinding()]
    param (

    )

    try {
        $Splat = @{
            Method = "POST"
            Uri = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotSettings/sync"
            ErrorAction = "Stop"
        }
        Invoke-MgGraphRequest @Splat
    }
    catch {
        throw $_
    }
}

function Get-AzureMgDevice
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$DeviceId
    )

    $Splat = @{
        Method = "GET"
        Uri = "https://graph.microsoft.com/beta/devices/$DeviceId"
        ErrorAction = "Stop"
    }
    $Device = Invoke-MgGraphRequest @Splat | Get-MgGraphAllPages -ToPSCustomObject

    if($Device -gt 1)
    {
        throw "(Get-AzureMgDevice) More than one device was found."
    }
}

function Add-DeviceToMgGroup
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $GroupName,
        [Parameter(Mandatory)]
        [string]
        $AzureADDeviceId
    )

    # Add to group
    $Group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ErrorAction Stop
    if(!$Group) {
        throw "Unable to find the group '$GroupName'."
    }

    try {
        New-MgGroupMember -GroupId $Group.Id -DirectoryObjectId $AzureADDeviceId -ErrorAction Stop
        Write-Host "Added device to group $($Group.DisplayName)"
    }
    catch {
        Throw $_
    }
}

function Get-AutopilotMgDevice
{
    <#
    .SYNOPSIS
        Gets a Windows Autopilot device from the Microsoft Graph API.
    .DESCRIPTION
        Gets a Windows Autopilot device from the Microsoft Graph API.
    .PARAMETER SerialNumber
        The serial number of the device to get. This will request all devices and filter on the client. This takes longer.
    .PARAMETER DeviceRegistrationId
        The device registration id of the device to get. This is a supported parameter in the Microsoft Graph API and is faster.
    .EXAMPLE
        Get-AutopilotMgDevice -SerialNumber "1234567890"
    .EXAMPLE
        Get-AutopilotMgDevice -DeviceRegistrationId '61d193a4-0241-4445-8f36-b6fc9ac1b248'
    .NOTES
        Equivalent Graph SDK Command: Get-MgDeviceManagementWindowAutopilotDeviceIdentity
        URI: https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities/{windowsAutopilotDeviceIdentity-id}
        Method: GET
        OutputType  : IMicrosoftGraphWindowsAutopilotDeviceIdentity
        Scope: {DeviceManagementServiceConfig.Read.All, DeviceManagementServiceConfig.ReadWrite.All}
    #>

    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'BySerialNumber')]
        [string]$SerialNumber,
        [Parameter(ParameterSetName = 'ByDeviceRegistrationId')]
        [string]$DeviceRegistrationId
    )

    try {
        $Splat = @{
            Method = "GET"
            Uri = "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities/$($DeviceRegistrationId)"
            ErrorAction = "Stop"
        }
        
        $response = Invoke-MgGraphRequest @Splat | Get-MgGraphAllPages -ToPSCustomObject
        
        if($SerialNumber)
        {
            $response = $response | Where-Object { $_.SerialNumber -eq $SerialNumber }
        }

        if ($response.Count -gt 1)
        {
            throw "(Get-AutopilotMgDevice) More than one device was found."
        }

        return $response
    }
    catch {
        throw $_
    }
}

function Get-AzureAdMgDeviceByAzureAdDeviceId
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $AzureADDeviceId
    )

    try {
        $Splat = @{
            Method = "GET"
            Uri = "https://graph.microsoft.com/beta/devices?`$filter=deviceId eq '$AzureADDeviceId'"
            ErrorAction = "Stop"
        }
        $response = Invoke-MgGraphRequest @Splat | Get-MgGraphAllPages -ToPSCustomObject
        
        if ($response.Count -gt 1)
        {
            throw "(Get-AzureAdMgDeviceByAzureAdDeviceId) More than one device was found."
        }

        return $response
    }
    catch {
        throw $_
    }
}

function Get-ImportedAutopilotMgDevice
{
    <#
    .SYNOPSIS
        Gets an imported Windows Autopilot device from the Microsoft Graph API.
    .DESCRIPTION
        Gets an imported Windows Autopilot device from the Microsoft Graph API.
    .PARAMETER SerialNumber
        The serial number of the device to get. This will request all devices and filter on the client. This takes longer.
    .EXAMPLE
        Get-ImportedAutopilotMgDevice -ImportedWindowsAutopilotDeviceIdentityId "c32e93cf-120b-4e41-83bc-7be08fdfe93d"
    .NOTES
        Equivalent Graph SDK Command: Get-MgDeviceManagementImportedWindowsAutopilotDeviceIdentity
        URI: https://graph.microsoft.com/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities/{importedWindowsAutopilotDeviceIdentity-id}
        Method: GET
        OutputType  : IMicrosoftGraphImportedWindowsAutopilotDeviceIdentity
        Scope: {DeviceManagementServiceConfig.Read.All, DeviceManagementServiceConfig.ReadWrite.All}

        Access the State.deviceImportStatus property to get the status of the import.
        Access the State.deviceRegistrationId property to get the device registration id. This ID can be used to search autopilot devices for this device after the import completes.
    #>

    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'ByImportedWindowsAutopilotDeviceIdentityId')]
        [string]$ImportedWindowsAutopilotDeviceIdentityId,
        [Parameter(ParameterSetName = 'BySerialNumber')]
        [string]$SerialNumber
        )
    try {
        $Splat = @{
            Method = "GET"
            Uri = "https://graph.microsoft.com/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities/$($ImportedWindowsAutopilotDeviceIdentityId)"
            ErrorAction = "Stop"
        }

        $response = Invoke-MgGraphRequest @Splat | Get-MgGraphAllPages -ToPSCustomObject

        if ($SerialNumber) {
            $response = $response | Where-Object { $_.SerialNumber -eq $SerialNumber }
        }

        if ($response.Count -gt 1)
        {
            throw "(Get-ImportedAutopilotMgDevice) More than one device was found."
        }

        return $response
    }
    catch {
        throw $_
    }
}

function New-ImportedAutopilotMgDevice
{
    <#
    .SYNOPSIS
        Imports a Windows Autopilot device using the Microsoft Graph API.
    .DESCRIPTION
        Imports a Windows Autopilot device using the Microsoft Graph API.
    .PARAMETER HardwareIdentifier
        The base64 hardware identifier (HASH) of the device to import.
    .PARAMETER ProductKey
        The product key of the device to import.
    .PARAMETER SerialNumber
        The serial number of the device to import.
    .EXAMPLE
        New-ImportedAutopilotMgDevice -HardwareIdentifier "BASE64HASH" -ProductKey "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX" -SerialNumber "1234567890"
    .NOTES
        Equivalent Graph SDK Command: New-MgDeviceManagementImportedWindowAutopilotDeviceIdentity
        Method: POST
        URI: https://graph.microsoft.com/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities
        OutputType  : IMicrosoftGraphImportedWindowsAutopilotDeviceIdentity
        Scope: {DeviceManagementServiceConfig.ReadWrite.All}

        The hardware hash can be obtained with the following:
            $Hash = (Get-CimInstance -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'" -ErrorAction Stop) `
                | Select-Object -ExpandProperty DeviceHardwareData 
            $base64 = [System.Convert]::FromBase64String($hash)
    #>
    [CmdletBinding()]
    param (
        $HardwareIdentifier,
        $ProductKey,
        $SerialNumber
    )

    $body = @{
        hardwareIdentifier = $HardwareIdentifier
        productKey = $ProductKey
        serialNumber = $SerialNumber
    }

    try {
        $Splat = @{
            Method = "POST"
            Uri = "https://graph.microsoft.com/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities"
            ErrorAction = "Stop"
            Body = $body
        }
        Invoke-MgGraphRequest @Splat
    }
    catch {
        throw $_
    }
}

function Remove-ImportedAutopilotMgDevice
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ImportedWindowsAutopilotDeviceIdentityId
    )

    try {
        if(!$ImportedWindowsAutopilotDeviceIdentityId)
        {
            throw "(Remove-ImportedAutopilotMgDevice) ImportedWindowsAutopilotDeviceIdentityId is required"
        }

        $Splat = @{
            Method = "DELETE"
            Uri = "https://graph.microsoft.com/beta/deviceManagement/importedWindowsAutopilotDeviceIdentities/$($ImportedWindowsAutopilotDeviceIdentityId)"
            ErrorAction = "Stop"
        }

        Invoke-MgGraphRequest @Splat

        return $response
    }
    catch {
        throw $_
    }
}

function Get-AzureADGroupByPrompt {
     <#
        .SYNOPSIS
            Gets an Azure AD group by prompting the user to select a group.
        .DESCRIPTION
            Gets an Azure AD group by prompting the user to select a group with a prefix.
        .PARAMETER Prefix
            The prefix to filter the groups on.
        .EXAMPLE
            Get-AzureADGroupByPrompt -Prefix "ENDPOINT Devices"
        .NOTES
            Equivalent Graph SDK Command: Get-MgGroup
            URI: https://graph.microsoft.com/beta/groups
            Method: GET
            OutputType  : IMicrosoftGraphGroup
            Scope: {Group.Read.All, Group.ReadWrite.All}

            The groupTypes property is used to filter out dynamic groups.
    #>

    [CmdletBinding()]
    param (
        [string]$Prefix
    )
    
    try
    {
        $Uri = "https://graph.microsoft.com/beta/groups"
        if ($Prefix) {
            $Uri += "?`$filter=startswith(displayName,'$($Prefix)')"
        }

        $Splat = @{
            Method = "GET"
            Uri = $Uri
            ErrorAction = "Stop"
        }
    
        $Groups = Invoke-MgGraphRequest @Splat | `
            Get-MgGraphAllPages -ToPSCustomObject | `
            Where-Object { if($_.groupTypes.count -eq 0){$_}} # Filter out dynamic groups
            
        $Group = $Groups | Select DisplayName, Description, Id | Out-GridView -Title "Select a group" -OutputMode Single
        
        if ($Group) {
            return $Group
        }
    }
    catch {
        throw $_
    }
}

function Add-MgDeviceToAzureADGroup {
    <#
        .SYNOPSIS
            Adds a device to an Azure AD group.
        .DESCRIPTION
            Adds a device to an Azure AD group.
        .PARAMETER DeviceId
            The device id of the device to add to the group.
        .PARAMETER GroupId
            The group id of the group to add the device to.
        .EXAMPLE
            Add-MgDeviceToAzureADGroup -DeviceId "12345678-1234-1234-1234-123456789012" -GroupId "12345678-1234-1234-1234-123456789012"
        .NOTES
            Equivalent Graph SDK Command: Add-MgGroupMember
            Method: POST
            URI: https://graph.microsoft.com/beta/groups/{id}/members/$ref
            OutputType  : IMicrosoftGraphDirectoryObject
            Scope: {Group.ReadWrite.All}
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$DeviceId,
        [Parameter(Mandatory)]
        [string]$GroupId
    )
    
    try
    {
        $Splat = @{
            Method = "POST"
            Uri = "https://graph.microsoft.com/beta/groups/$GroupId/members/`$ref"
            ErrorAction = "Stop"
            Body = @{
                "@odata.id" = "https://graph.microsoft.com/beta/devices/$($DeviceId)"
            }
        }
    
        $response = Invoke-MgGraphRequest @Splat
    
        return $response
    }
    catch {
        throw $_
    }
}

function Get-MgGraphAllPages {
    <#
    .SYNOPSIS
        Gets all pages of a Microsoft Graph API response.
    .DESCRIPTION
        Gets all pages of a Microsoft Graph API response.
    .PARAMETER NextLink
        The next link to get the next page of results.
    .PARAMETER SearchResult
        The search result to get the next page of results.
    .PARAMETER ToPSCustomObject
        Converts the results to a PSCustomObject.
    .EXAMPLE
        $response = Invoke-MgGraphRequest @Splat | Get-MgGraphAllPages -ToPSCustomObject
    .NOTES
        This is a slightly modified funtion from the deprecated Microsoft.Graph.Intune module.
        Modified by David Richmond (https://powercel.hashnode.dev/get-mggraphallpages-the-mggraph-missing-command)
    #>

    [CmdletBinding(
        ConfirmImpact = 'Medium',
        DefaultParameterSetName = 'SearchResult'
    )]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'NextLink', ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('@odata.nextLink')]
        [string]$NextLink
        ,
        [Parameter(Mandatory = $true, ParameterSetName = 'SearchResult', ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [PSObject]$SearchResult
        ,
        [Parameter(Mandatory = $false)]
        [switch]$ToPSCustomObject
    )

    begin {}

    process {
        if ($PSCmdlet.ParameterSetName -eq 'SearchResult') {
            # Set the current page to the search result provided
            $page = $SearchResult

            # Extract the NextLink
            $currentNextLink = $page.'@odata.nextLink'

            # We know this is a wrapper object if it has an "@odata.context" property
            #if (Get-Member -InputObject $page -Name '@odata.context' -Membertype Properties) {
            # MgGraph update - MgGraph returns hashtables, and almost always includes .context
            # instead, let's check for nextlinks specifically as a hashtable key
            if ($page.ContainsKey('@odata.count')) {
                Write-Verbose "First page value count: $($Page.'@odata.count')"    
            }

            if ($page.ContainsKey('@odata.nextLink') -or $page.ContainsKey('value')) {
                $values = $page.value
            } else { # this will probably never fire anymore, but maybe.
                $values = $page
            }

            # Output the values
            # Default returned objects are hashtables, so this makes for easy pscustomobject conversion on demand
            if ($values) {
                if ($ToPSCustomObject) {
                    $values | ForEach-Object {[pscustomobject]$_}   
                } else {
                    $values | Write-Output
                }
            }
        }

        while (-Not ([string]::IsNullOrWhiteSpace($currentNextLink)))
        {
            # Make the call to get the next page
            try {
                $page = Invoke-MgGraphRequest -Uri $currentNextLink -Method GET
            } catch {
                throw $_
            }

            # Extract the NextLink
            $currentNextLink = $page.'@odata.nextLink'

            # Output the items in the page
            $values = $page.value

            if ($page.ContainsKey('@odata.count')) {
                Write-Verbose "Current page value count: $($Page.'@odata.count')"    
            }

            # Default returned objects are hashtables, so this makes for easy pscustomobject conversion on demand
            if ($ToPSCustomObject) {
                $values | ForEach-Object {[pscustomobject]$_}   
            } else {
                $values | Write-Output
            }
        }
    }

    end {}
}
