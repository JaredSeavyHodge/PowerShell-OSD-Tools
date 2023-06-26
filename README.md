# PowerShell OSD Tools with WPF GUI
### Uses Microsoft.Graph.Authentication module to register devices with Windows Autopilot

I created this tool primarily for single device deployment during the Windows Out of Box Experience. It does not rely on the Microsoft.Graph.Intune module, or the script created by Microsoft (Michael Niehaus) Get-WindowsAutopilotInfo.  Microsoft.Graph.Authentication is the only dependent module, which contains the cmdlet Invoke-MgGraphRequest to accomplish the import. The functions handling this can be found in the GraphHelpers.ps1 file.

The logic used is heavily inspired by Michael Niehaus' script (Get-WindowsAutopilotInfo), however is designed to use the latest Graph module and is only to be used on the local device it's executed from.

The entry cmdlet 'Start-OSDPhase' contains some code borrowed from David Segura who is a developer of OSD Cloud.  If you haven't heard of him, check him out.  I'm using his method of detecting the current 'phase' of the computer (i.e. OOBE, Windows, WinPE).  This is here for future development, however can be used to execute any chain of processes you'd like.

This app is still in development, subject to change, and I am not responsible for any unintended consequence.  With that said, this tool has been working as intended in my environment. This was also created quickly and likely has notable room for refactoring and improvements.

## Features
-  Register device in Windows Autopilot and add to Azure group.
-  Update Windows
-  Update Drivers
-  Install Print Management
-  Open Edge browser
-  Open Windows settings
-  Install RSAT

![app (Small)](https://github.com/JaredSeavyHodge/PowerShell-OSD-Tools/assets/17116881/103ada8f-5f39-4375-9e10-721c0a4a42fc)

## Configuration
There is a config folder containing a config.json file to customize the title and logo of the app.  The 'GroupPrefix' setting is meant to filter the searched Azure groups to only display groups beginning with the prefix.  For example, if technicians should only be adding the device to device groups that begin with 'Intune Devices - ', then it can be added here.

## Temporary import for use
The Import-TempModule.ps1 script will download the module folder from Github, extract it, import the module, and run the entry cmdlet Start-OSDPhase. This isn't necessary, but is useful if it lives in GitHub. The script can be called with a bat/ps1 file using iex(iwr "https://<url>". The benefit here, is the script can be updated on GitHub without needing to update the tool in the technicians possession. If this if forked, obviously the paths will change and need to be updated.
