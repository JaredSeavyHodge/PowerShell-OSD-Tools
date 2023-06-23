function Get-IsAutopilotRegistered
{
    [CmdLetBinding()]
    param
    (
        [Parameter()]
        [string]$SerialNumber
    )

    try {
        if(!$SerialNumber)
        {
            $SerialNumber = (Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop).SerialNumber 
        }

        
        if(Get-AutopilotMgDevice -SerialNumber $SerialNumber -ErrorAction Stop)
        {
            return $true
        }
        else {
            return $false
        }
    }
    catch {
        Throw $_
    }
}
