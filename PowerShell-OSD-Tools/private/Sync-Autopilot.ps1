function Sync-Autopilot
{
    [CmdletBinding()]
    param (

    )

    try
    {
        Import-Module "Microsoft.Graph.Authentication" -ErrorAction Stop
    }
    catch 
    { 
        Install-Module "Microsoft.Graph.Authentication" -Scope CurrentUser -Force -WarningAction SilentlyContinue 
    }

    try {
        $graphApiVersion = "beta"
        $Resource = "deviceManagement/windowsAutopilotSettings/sync"
        $uri = "https://graph.microsoft.com/$graphApiVersion/$Resource"
        Invoke-MgGraphRequest -Method POST -Uri $uri -ErrorAction Stop
    }
    catch {
        throw $_
    }
}