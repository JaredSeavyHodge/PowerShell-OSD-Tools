function Add-Capability {
    <#
    .SYNOPSIS
    Adds a Windows capability.

    .DESCRIPTION
    Adds a Windows capability. If no capability name is provided, out-gridview is used to select one or more capabilities.

    .PARAMETER Name
    The name of the Windows capability to add.
    #>
    param (
        [String[]]$Name
    )
    if (-not $Name) {
        $Name = Get-WindowsCapability -Online | Where-Object State -ne 'Installed' | Select-Object -ExpandProperty Name | Out-GridView -OutputMode Multiple -Title 'Select one or more Capabilities to install'
    }
    foreach ($Item in $Name) {
        $WindowsCapability = Get-WindowsCapability -Online -Name "*$Item*" | Where-Object State -ne 'Installed'
        if ($WindowsCapability) {
            $WindowsCapability | Add-WindowsCapability -Online
        }
    }
}