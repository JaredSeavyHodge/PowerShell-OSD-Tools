<#
.SYNOPSIS
Upgrades the Windows edition to support AutoPilot.

.DESCRIPTION
The `Update-WindowsEdition` function upgrades the Windows edition to support AutoPilot. AutoPilot is a collection of technologies used to set up and pre-configure new devices, getting them ready for productive use. This function checks the current Windows edition and upgrades it to the specified edition (Enterprise, Professional, or Education) if necessary. After the upgrade, the computer will reboot and you must run this script again.

.PARAMETER To
Specifies the edition to upgrade to. The default value is "Education". Valid values are "Enterprise", "Professional", and "Education".

.EXAMPLE
Update-WindowsEdition -To Enterprise
Upgrades the Windows edition to Enterprise.

.NOTES
Author: GitHub Copilot
#>
<#
.SYNOPSIS
Upgrades the Windows edition to support AutoPilot.

.DESCRIPTION


.PARAMETER None


.EXAMPLE
Update-WindowsEdition

.NOTES
Author: GitHub Copilot
#>

Function Update-WindowsEdition {
    [cmdletbinding()]
    Param (
        [ValidateSet("Enterprise", "Professional", "Education")]
        $To = "Education"
    )

    try {

        $KMSKeys = @{
            "Enterprise" = "NPPR9-FWDCX-D2C8J-H872K-2YT43"
            "Professional" = "VK7JG-NPHTM-C97JM-9MPGT-3V66T"
            "Education" = "NW6C2-QMPVW-D7KKK-3GKT6-VCFB2"
        }

        $Edition = Get-WindowsEdition -online

        if ($Edition.Edition -eq "Core" -OR $Edition.Edition -eq "Home") {
            Write-Warning "AutoPilot is not supported on Home/Core`n
            The Windows edition must be upgraded to support AutoPilot. `
            Once the upgrade is complete, reboot before enrolling into AutoPilot."
            
            $DoUpgrade = Read-Host -Prompt "Do you want to upgrade the Windows edition to $To now? (Y/N)"
            if( $DoUpgrade.ToLower() -eq "y" ) {
                $Proc = Start-Process changepk.exe -ArgumentList "/ProductKey $($KMSKeys.$To)" -PassThru
                $Proc | Wait-Process -Timeout 90 -ErrorAction SilentlyContinue -ErrorVariable $TimedOut
                $Proc | Stop-Process

                throw $TimedOut
            }
            else {
                $errormessage = "The Windows edition must be upgraded from Home to support AutoPilot."
                $errortitle = "Windows Edition Upgrade Required"
                
                [System.Windows.MessageBox]::Show($errormessage, $errortitle, "OK", "Error")
            }
        }
    }
    catch {
        Write-Error "An error occurred while attempting upgrade from Home/Core edition: $_"
        Exit 1
    }
}