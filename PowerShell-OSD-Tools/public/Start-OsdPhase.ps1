function Start-OsdPhase {
    <#
        .SYNOPSIS
        This script is designed to be run from WinPE, Audit Mode, or OOBE utilizing David Sefura's Window's phase logic.  It will determine the Windows phase and run the appropriate functions.
    #>

    $Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OSDCloud.log"
    $null = Start-Transcript -Path (Join-Path "$env:SystemRoot\Temp" $Transcript) -ErrorAction Ignore

    # Get NuGet and modules
    $provider = Get-PackageProvider NuGet -ErrorAction Ignore
    if (-not $provider) {
        Write-Host "Installing provider NuGet"
        Find-PackageProvider -Name NuGet -ForceBootstrap -IncludeDependencies
    }

    @("Microsoft.Graph.Authentication") | Foreach-Object {
        if (!(Get-Module -ListAvailable -Name $_)) {
            Write-Host -ForegroundColor DarkGray "Installing module $_"
            Install-Module -Name $_ -Scope CurrentUser -Force -WarningAction SilentlyContinue
        }
        Import-Module -Name $_ -Force
    }   

    $Scopes = @(
        "Group.ReadWrite.All"
        "Device.Read.All"
        "DeviceManagementServiceConfig.ReadWrite.All" # Required import the device into Windows Autopilot
    )
    

    # Determine the Windows environment
    if ($env:SystemDrive -eq 'X:') {$WindowsPhase = 'WinPE'}
    else {
        $ImageState = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Setup\State' -ErrorAction Ignore).ImageState
        if ($env:UserName -eq 'defaultuser0') {$WindowsPhase = 'OOBE'}
        elseif ($ImageState -eq 'IMAGE_STATE_SPECIALIZE_RESEAL_TO_OOBE') {$WindowsPhase = 'Specialize'}
        elseif ($ImageState -eq 'IMAGE_STATE_SPECIALIZE_RESEAL_TO_AUDIT') {$WindowsPhase = 'AuditMode'}
        else {$WindowsPhase = 'Windows'}
    }

    Write-Host -ForegroundColor DarkGray "Phase: $WindowsPhase"

    switch ($WindowsPhase) {
        'WinPE'
        {
            $null = Stop-Transcript -ErrorAction Ignore
        }

        'Specialize'
        {
            $null = Stop-Transcript -ErrorAction Ignore
        }

        'AuditMode'
        {
            $null = Stop-Transcript -ErrorAction Ignore
        }

        'OOBE'
        {
            try {
                Select-MgProfile -Name beta
                Connect-MgGraph -Scopes $Scopes
            }
            catch {
                Write-Host -ForegroundColor Magenta "Error during AzureAD authentication."
            }
            Invoke-Gui
            $null = Stop-Transcript -ErrorAction Ignore
        }

        'Windows'
        {
            try {
                Select-MgProfile -Name beta
                Connect-MgGraph -Scopes $Scopes
            }
            catch {
                Write-Host -ForegroundColor Magenta "Error during AzureAD authentication."
            }
            Invoke-Gui
            $null = Stop-Transcript -ErrorAction Ignore
        }

        Default {Write-Host -ForegroundColor Red "Windows phase not detected"}
    }
}