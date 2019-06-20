$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Stop'

try
{
    if (Test-Path -PathType Leaf pie.ps1)
    {
        Write-Output 'Pie is already installed. Run "./pie.ps1 -Update" to get the latest version.'
    }
    else
    {
        Invoke-WebRequest https://raw.githubusercontent.com/atifaziz/pie.ps/master/pie.ps1 `
            -OutFile pie.ps1

        try
        {
            ./pie.ps1 -FinishSelfInstall
        }
        catch
        {
            Remove-Item pie.ps1
            throw
        }
    }
}
finally
{
    $ErrorActionPreference = $oldErrorActionPreference
}
