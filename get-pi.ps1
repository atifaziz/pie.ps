$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Stop'

try
{
    if (Test-Path -PathType Leaf pi.ps1)
    {
        Write-Output 'Pi is already installed. Run "pi update" to get the latest version.'
    }
    else
    {
        Invoke-WebRequest https://raw.githubusercontent.com/atifaziz/pi.ps1/master/pi.ps1 `
            -OutFile pi.ps1

        try
        {
            ./pi.ps1 -FinishSelfInstall
            Write-Output 'Pi is installed successfully.'
        }
        catch
        {
            Remove-Item ./pi.ps1
            throw
        }
    }
}
finally
{
    $ErrorActionPreference = $oldErrorActionPreference
}
