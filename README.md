# PowerShell OSD Tools WPF App
### Uses Microsoft.Graph.Authentication module to register devices with Windows Autopilot

I created this tool primarily for single device deployment during the Windows Out of Box Experience. It does not rely on the deprecated module Microsoft.Graph.Intune, or the Get-WindowsAutopilotInfo script from the PSGallery.  Microsoft.Graph.Authentication is the only dependent module, which contains Invoke-MgGraphRequest to accomplish the import.

The logic used is heavily inspired by Michael Niehaus' script (Get-WindowsAutopilotInfo), however is designed to use the latest Graph module and is only to be used on the local device it's executed from.

The entry cmdlet 'Start-OSDPhase' contains some code borrowed from David Segura who is a developer of OSD Cloud.  If you haven't heard of him, check him out.  I'm using his method of detecting the current 'phase' of the computer (i.e. OOBE, Windows, WinPE).  This is here for future development, however can be used to execute any chain of processes you'd like.

Features:
-  Register device in Windows Autopilot and add to Azure group.
-  Update Windows
-  Update Drivers
-  Install Print Management
-  Open Edge browser
-  Open Windows settings
-  Install RSAT

![app (Small)](https://github.com/JaredSeavyHodge/PowerShell-OSD-Tools/assets/17116881/103ada8f-5f39-4375-9e10-721c0a4a42fc)

