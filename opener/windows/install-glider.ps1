$isWin64 = [System.Environment]::Is64BitOperatingSystem

$gliderReleaseUrl = "https://api.github.com/repos/nadoo/glider/releases"

$binDir = $env:USERPROFILE + "\.bin"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (!(Test-Path -Path $binDir)) {
    Write-Output ("Create directory " + $binDir)
    New-Item -Path $binDir -ItemType Directory
}

if (!(Test-Path -Path ($binDir + "\glider.exe"))) {
    $output = $env:TEMP + "\glider.zip"
    $extraDir = $env:TEMP + "\glider"

    Write-Output "Download glider ..."
    $j = Invoke-WebRequest -Uri $gliderReleaseUrl | ConvertFrom-Json

    $re = [regex]"windows-386"
    if ($isWin64) {
        $re = [regex]"windows-amd64"
    }

    $url = ""
    foreach ($asset in $j[0].assets) {
        if ($asset.name -match $re) {
            $url = $asset.browser_download_url
            break
        }
    }

    Invoke-WebRequest -Uri $url -OutFile $output

    Write-Output "expand glider.zip ..."
    Expand-Archive $output -DestinationPath $extraDir -Force

    Write-Output "copy glider.exe to ~/.bin"
    Copy-Item -Path ($extraDir + "\glider.exe") -Destination $binDir
    Write-Output "install glider success"

} else {
    Write-Output "ag is already installed"
}

Invoke-Item -Path $binDir

Read-Host | Out-Null
Exit
