function Invoke-Gui
{
        <#
    .SYNOPSIS
        Starts the GUI for HCC OSD Toolkit
    .DESCRIPTION
        This GUI is used to provide a user-friendly interface the autopilot process and other OSD tasks.
    #>

    Begin
    {

        # Add presentation framework assemblies
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName Microsoft.VisualBasic

        # Configuration setup
        $ConfigPath = "$PSScriptRoot\..\config\"
        $ConfigJson = Get-Content -Path "$ConfigPath\config.json" | ConvertFrom-Json
        $TitleText = $ConfigJson.Title
        $GroupPrefix = $ConfigJson.GroupPrefix
        $LogoPath = Join-Path $ConfigPath $ConfigJson.Logo

        # Create Window
        [xml]$xaml = Get-Content "$PSScriptRoot\..\Private\wpfapp.xaml"
        $reader = (New-Object System.Xml.XmlNodeReader $xaml)
        $Window = [Windows.Markup.XamlReader]::Load($reader)
        $xaml.SelectNodes("//*[@Name]") | ForEach-Object {Set-Variable -Name ($_.Name) -Value $Window.FindName($_.Name) -Scope Script}
        
        if ($ConfigJson.Logo) {
            $LogoImage = $Window.FindName("LogoImage")
            $LogoImage.ImageSource = $LogoPath
        }
        $AppTitle.Text = $TitleText
        
        # Script variable
        $Script:GroupForDevice
    
        # Add Event Handlers
        $Title.Add_MouseDown({
            if ($_.ChangedButton -eq [System.Windows.Input.MouseButton]::Left) {
                $Window.DragMove()
            }
        })
        $CloseButton.Add_Click({
            $Window.Close()
        })
        $PrintManagementButton.Add_Click({Start-AutoProcess -PrintManagement})
        $RsatButton.Add_Click({Start-AutoProcess -RSAT})
        
        # Edge Button
        $contextMenu = New-Object System.Windows.Controls.ContextMenu
        $contextMenu.Items.Add((New-Object System.Windows.Controls.MenuItem -Property @{
            Header = "Google"; 
            Add_Click = {
                Start-AutoProcess -Google
            }})) | Out-Null
        $contextMenu.Items.Add((New-Object System.Windows.Controls.MenuItem -Property @{
            Header = "Intune"; 
            Add_Click = {
                Start-AutoProcess -Intune
            }})) | Out-Null
        $EdgeButton.ContextMenu = $contextMenu
        $EdgeButton.Add_Click({
            $EdgeButton.ContextMenu.IsOpen = $true
        })

        $SettingsButton.Add_Click({Start-AutoProcess -Settings})
        $UpdateWindowsButton.Add_Click({Start-AutoProcess -UpdateWindows})
        $UpdateDriversButton.Add_Click({Start-AutoProcess -UpdateDrivers})
        $RebootButton.Add_Click({Restart-Computer -Force})
        $RenameButton.Add_Click({
            $newName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter new computer name", "Rename Computer", $env:COMPUTERNAME)
            if($newName) {
                Rename-Computer -NewName $newName -Force
            }
        })
        $GroupButton.Add_Click({
            # $Group = Get-AzureADGroup -SearchString "ENDPOINT Devices" -All $true | Out-GridView -OutputMode Single -Title "Select the Group"
            # $Group = Get-MgGroup -Filter "startswith(displayName,'ENDPOINT Devices')" -All | Out-GridView -OutputMode Single -Title "Select the Group"
            
            if ($GroupPrefix) {
                $Script:GroupForDevice = Get-AzureADGroupByPrompt -Prefix "ENDPOINT Devices"
            }
            else {
                $Script:GroupForDevice = Get-AzureADGroupByPrompt
            }
            
            $GroupBox.Text = $Script:GroupForDevice.DisplayName
        })
        $EnrollButton.Add_Click({
            if ($computerBox.Text -eq "" -or $GroupBox.Text -eq "") {
                [System.Windows.MessageBox]::Show("Computer Name and Group Name cannot be empty", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
                return
            }
            if (!$Script:GroupForDevice) { 
                Write-Error "Group not selected"
                return
            }
            Start-AutoProcess -ComputerName $computerBox.Text `
                -GroupId $Script:GroupForDevice.Id `
                -UpdateWindows:$updateWindowsCheck.isChecked `
                -UpdateDrivers:$updateDriversCheck.isChecked `
                -RegisterAutopilot `
                -Reboot:$rebootCheck.isChecked `
                -PrintManagement:$printManagementCheck.isChecked

            if(Get-IsAutopilotRegistered -ErrorAction Stop)
            {
                $AutopilotRegisteredInfo.Text = $isRegistered
                $AutopilotSection.IsEnabled = $false
            }
        })
    }
    
    Process
    {
        $isRegistered = "Unknown"
        try {
            if(Get-IsAutopilotRegistered -ErrorAction Stop)
            {
                $isRegistered = $true
                $AutopilotSection.IsEnabled = $false
            }
            else {
                $isRegistered = $false
            }
        }
        catch [Microsoft.Management.Infrastructure.CimException] {
            Write-Host -ForegroundColor Magenta "Error when calling Get-CimInstance. Error Message: $($_.Exception.Message)"
        }
        catch {
            Write-Host -ForegroundColor Magenta "Unable to determine if device is registered. Error Message: $($_.Exception.Message)"
        }
        
        # Get the OS info
        $OSInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
        
        $ComputerNameLabel.Text = "Name:"
        $ComputerNameInfo.Text = $env:COMPUTERNAME

        $SerialLabel.Text = "Serial:"
        $SerialInfo.Text = (Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue| Select-Object -ExpandProperty SerialNumber)
        
        $OSLabel.Text = "OS:"
        $OS.Text = $OSInfo.Caption

        $VersionLabel.Text = "Version:"
        $VersionInfo.Text = (Get-ComputerInfo -Property WindowsVersion).WindowsVersion

        $BuildLabel.Text = "Build:"
        $BuildInfo.Text = $OSInfo.BuildNumber

        $AutopilotRegisteredLabel.Text = "Autopilot Registered:"
        $AutopilotRegisteredInfo.Text = $isRegistered

        $LastBootUpTimeLabel.Text = "Last Boot Up Time:"
        $LastBootUpTimeInfo.Text = $OSInfo.LastBootUpTime

        $InstallDateLabel.Text = "Install Date:"
        $InstallDateInfo.Text = $OSInfo.InstallDate
        
        # Show the window.
        $Window.ShowDialog() | Out-Null

    }
    End
    {
        $Window.Close()
    }
}