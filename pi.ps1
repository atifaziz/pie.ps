<#
MIT License

Copyright (c) 2019 Atif Aziz

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

[CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = 'Install')]
param(
    [Parameter(ParameterSetName = 'Install')]
    [string]$RequirementsFile = 'requirements.txt',
    [Parameter(ParameterSetName = 'Install')]
    [switch]$SkipProxyScripts,
    [Parameter(ParameterSetName = 'Install')]
    [Parameter(ParameterSetName = 'Uninstall')]
    [string]$BasePath = './.python',

    [Parameter(ParameterSetName = 'Uninstall', Mandatory = $true)]
    [switch]$Uninstall,

    [Parameter(ParameterSetName = 'List-Versions', Mandatory = $true)]
    [switch]$ListVersions,

    [Parameter(ParameterSetName = 'Finish-SelfInstall', Mandatory = $true)]
    [switch]$FinishSelfInstall)

$ErrorActionPreference = 'Stop'

function Remove-CommonLeadingWhiteSpace([string]$s) {
    [regex]::Replace($s, "(?m:^ {$(([regex]::Matches($s, '(?m:^ +)') | Select-Object -ExpandProperty Length | Measure-Object -Minimum).Minimum)})", '') -split '`r?`n'
}

$cachedVersions = $null

function Get-PythonVersions
{
    if (!$script:cachedVersions)
    {
        $script:cachedVersions =
            Invoke-RestMethod https://raw.githubusercontent.com/atifaziz/pi.ps1/master/pyver.csv |
                ConvertFrom-Csv |
                Select-Object @{ L = 'Version'      ; E = { $_.version        } },
                              @{ L = 'PrefixVersion'; E = { $_.version_prefix } },
                              @{ L = 'SuffixVersion'; E = { $_.version_suffix } },
                              @{ L = 'Architecture' ; E = { $_.architecture   } },
                              @{ L = 'Url'          ; E = { $_.url            } }
    }
    $script:cachedVersions
}

function Uninstall
{
    'python', 'pip' |
        % { "$_.cmd" } |
        ? { Test-Path -PathType Leaf $_ } |
        Remove-Item
    Remove-Item -Recurse -Force $basePath
}

function Install
{
    if (Test-Path -PathType Leaf pyver.txt) {
        $requiredVersion, $versoinDownloadUrl = (Get-Content pyver.txt -TotalCount 1) -split '@'
        Write-Verbose "Required Python version is $requiredVersion."
        if ($versoinDownloadUrl -and ($versoinDownloadUrl -notmatch '^https?://')) {
            throw "Invalid version download URL (must be a URI using the HTTP or HTTPS scheme): $versoinDownloadUrl"
        }
    }

    $python = Join-Path $basePath python.exe
    if (Test-Path -PathType Leaf $python)
    {
        $pythonVersionString = (& $python -V | Out-String).Trim()
        Write-Verbose $pythonVersionString
        $installedVersion = ($pythonVersionString -split ' ', 3)[1]
    }

    if ($installedVersion -and $requiredVersion -and ($installedVersion -ne $requiredVersion))
    {
        Write-Verbose "Installed version $installedVersion does not match required version $requiredVersion. Installed version will be removed."
        $uninstall = $true
    }

    if (!(Test-Path -PathType Container $basePath))
    {
        $zipPath = Join-Path $env:TEMP python.zip
        if ($versoinDownloadUrl)
        {
            $pythonDownloadUrl = $versoinDownloadUrl
        }
        else
        {
            $archs = @{ AMD64 = 'amd64'; x86 = 'win32' }
            $arch = $archs[$env:PROCESSOR_ARCHITECTURE]
            $pythonDownloadUrl = Get-PythonVersions |
                ? { ($_.Version -eq $requiredVersion) -and ($_.Architecture -eq $arch) } |
                Select-Object -ExpandProperty Url
            if (!$pythonDownloadUrl) {
                throw "Download URL for Python $requiredVersion ($arch) is unknown."
            }
        }
        Invoke-WebRequest $pythonDownloadUrl -OutFile $zipPath
        if ($uninstall) {
            Uninstall
        }
        Expand-Archive $zipPath -DestinationPath $basePath
        $installed = $true
    }

    if ($installed)
    {
        $pythonVersionString = (& $python -V | Out-String).Trim()
        Write-Verbose $pythonVersionString
        $installedVersion = ($pythonVersionString -split ' ', 3)[1]

        if ($installedVersion -and $requiredVersion -and ($installedVersion -ne $requiredVersion)) {
            throw "Downloaded version $installedVersion does not match required version $requiredVersion. Installation impossible."
        }
    }

    if (!$skipProxyScripts)
    {
        Set-Content python.cmd (Remove-CommonLeadingWhiteSpace '
            @echo off
            setlocal
            set PATH=%~dp0.python;%~dp0.python\Scripts;%PATH%
            python.exe %*
            ').TrimStart() `
            -Encoding ascii -NoNewline

        Set-Content pip.cmd '@call "%~dp0python" -m pip %*' `
            -Encoding ascii
    }

    $pthFile = Get-ChildItem (Join-Path $basePath *._pth)
    if (!(Get-Content $pthFile | ? { $_ -match '^ *import +site *$' })) {
        Add-Content $pthFile 'import site'
    }

    [string]$pipVersion = & $python -m pip --version
    if ($LASTEXITCODE)
    {
        Invoke-WebRequest https://bootstrap.pypa.io/get-pip.py `
            -OutFile (Join-Path $basePath get-pip.py)

        Push-Location $basePath
        try {
            .\python get-pip.py
        }
        finally {
            Pop-Location
        }

        if ($LASTEXITCODE) {
            throw "Installation of pip failed (exit code = $LASTEXITCODE)."
        }

    } else {

        Write-Verbose $pipVersion

    }

    if (Test-Path -PathType Leaf $requirementsFile)
    {
        & $python -m pip install -r $requirementsFile --no-warn-script-location
        if ($LASTEXITCODE) {
            throw "Installation of requirements failed (exit code = $LASTEXITCODE)."
        }
    }
}

function List-Versions {
    Get-PythonVersions | Select-Object -ExpandProperty Version -Unique
}

function Finish-SelfInstall {
    Write-Output 'Pi installed successfully.'
}

& $PSCmdlet.ParameterSetName
