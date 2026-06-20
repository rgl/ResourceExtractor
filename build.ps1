param(
    [Parameter(Mandatory=$true)]
    [string]$stage
)

Set-StrictMode -Version Latest
$FormatEnumerationLimit = -1
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
trap {
    "ERROR: $_" | Write-Host
    ($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1' | Write-Host
    ($_.Exception.ToString() -split '\r?\n') -replace '^(.*)$','ERROR EXCEPTION: $1' | Write-Host
    Exit 1
}

$version = if ($env:GITHUB_REF -like "refs/tags/v*") {
    $env:GITHUB_REF -replace "refs/tags/v", ""
} elseif ($env:GITHUB_SHA) {
    "0.0.0-$($env:GITHUB_SHA.Substring(0, 7))"
} else {
    "0.0.0-dev"
}

function exec([ScriptBlock]$externalCommand, [string]$stderrPrefix='', [int[]]$successExitCodes=@(0)) {
    $eap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        &$externalCommand 2>&1 | ForEach-Object {
            if ($_ -is [System.Management.Automation.ErrorRecord]) {
                "$stderrPrefix$_"
            } else {
                "$_"
            }
        }
        if ($LASTEXITCODE -notin $successExitCodes) {
            throw "$externalCommand failed with exit code $LASTEXITCODE"
        }
    } finally {
        $ErrorActionPreference = $eap
    }
}

function Invoke-StageDependencies {
    exec {
        dotnet restore
    }
    Write-Host "Installing libz..."
    $archiveUrl = "https://github.com/MiloszKrajewski/LibZ/releases/download/1.2.0.0/libz-1.2.0.0-tool.zip"
    $archivePath = Split-Path -Leaf $archiveUrl
    (New-Object System.Net.WebClient).DownloadFile($archiveUrl, $archivePath)
    Expand-Archive $archivePath .
    Remove-Item $archivePath
}

function Invoke-StageBuild {
    exec {
        dotnet build --no-restore --configuration Release --property:Version=$version
    }
    $rootPath = "$PWD"
    Push-Location bin/Release/*
    exec {
        &"$rootPath\libz.exe" inject-dll --assembly ResourceExtractor.exe --include *.dll --move
    }
    Compress-Archive `
        -CompressionLevel Optimal `
        -Path ResourceExtractor.exe `
        -DestinationPath "$rootPath\ResourceExtractor.zip"
    Pop-Location
}

Invoke-Expression "Invoke-Stage$([System.Globalization.CultureInfo]::InvariantCulture.TextInfo.ToTitleCase($stage))"
