@{
    ModuleVersion = '1.0.0'
    GUID = 'b174ac3b-394e-4498-bf09-7cb1d6c56de1'
    Author = 'Jared'
    CompanyName = 'Personal'
    Copyright = 'Open'
    Description = 'A PowerShell module for OSD'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Add-Capability',
        'Install-NetFx',
        'Install-Rsat',
        'Invoke-Gui',
        'Start-OsdPhase',
        'Update-Drivers',
        'Update-Windows'
        )
    RootModule = 'PowerShell-OSD-Tools.psm1'
}