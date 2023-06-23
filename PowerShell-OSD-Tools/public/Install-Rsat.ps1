function Install-Rsat {
    <#
    .SYNOPSIS
    Installs the RSAT tools.

    .DESCRIPTION
    Installs the RSAT tools using the Windows capability system.

    .PARAMETER Basic
    If specified, installs a basic set of RSAT tools.

    .PARAMETER Full
    If specified, installs all RSAT tools.

    .PARAMETER Name
    The names of the specific RSAT tools to install.
    #>
    param (
        [Switch]$Basic,
        [Switch]$Full,
        [String[]]$Name
    )
    if ($Basic) {
        $Name = @('ActiveDirectory','BitLocker','GroupPolicy','RemoteDesktop','VolumeActivation')
    }
    elseif ($Full) {
        $Name = 'Rsat'
    }
    elseif (!$Name) {
        $Name = Get-WindowsCapability -Online -Name "*Rsat*" -ErrorAction SilentlyContinue | `
        Where-Object {$_.State -ne 'Installed'} | `
        Select-Object Name, DisplayName, Description | `
        Out-GridView -PassThru -Title 'Select one or more Rsat Capabilities to install' | `
        Select-Object -ExpandProperty Name
    }

    if ($Name) {
        foreach ($Item in $Name) {
            $WindowsCapability = Get-WindowsCapability -Online -Name "*$Item*" | Where-Object State -ne 'Installed'
            if ($WindowsCapability) {
                $WindowsCapability | Add-WindowsCapability -Online
            }
        }
    }
    else {
        Write-Warning 'No RSAT tools selected'
    }
}