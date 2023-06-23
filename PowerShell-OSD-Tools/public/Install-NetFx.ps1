function Install-NetFX {
    <#
    .SYNOPSIS
    Installs the .NET Framework.

    .DESCRIPTION
    Installs the .NET Framework using the Windows capability system.
    #>
    $WindowsCapability = Get-WindowsCapability -Online -Name "*NetFX*" | Where-Object State -ne 'Installed'
    if ($WindowsCapability) {
        $WindowsCapability | Add-WindowsCapability -Online
    }
}