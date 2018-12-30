$isWin64 = [System.Environment]::Is64BitOperatingSystem

$curlUrl = "https://curl.haxx.se/windows/dl-7.62.0_1/curl-7.62.0_1-win32-mingw.zip"
if ($isWin64) {
    $curlUrl = "https://curl.haxx.se/windows/dl-7.62.0_1/curl-7.62.0_1-win64-mingw.zip"
}
$agReleasesUrl = "https://api.github.com/repos/k-takata/the_silver_searcher-win32/releases"
$gvimReleasesUrl = "https://api.github.com/repos/vim/vim-win32-installer/releases"

$binDir = $env:USERPROFILE + "\.bin"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (!(Test-Path -Path $binDir)) {
    Write-Output ("Create directory " + $binDir)
    New-Item -Path $binDir -ItemType Directory
}

if (!(Test-Path -Path ($binDir + "\curl.exe"))) {
    $output = $env:TEMP + "\curl.zip"
    $extraDir = $env:TEMP + "\curl"

    Write-Output "Download curl ..."
    $startTime = Get-Date
    Invoke-WebRequest -Uri $curlUrl -OutFile $output
    Write-Output "Time taken: $((Get-Date).Subtract($startTime).Seconds) second(s)"

    Write-Output "expand curl.zip ..."
    Expand-Archive $output -DestinationPath $extraDir -Force

    Write-Output "copy curl.exe to ~/.bin"
    Copy-Item -Path ($extraDir + "\*\bin\*") -Destination $binDir
    Write-Output "install curl success"

} else {
    Write-Output "curl is already installed"
}

if (!(Test-Path -Path ($binDir + "\ag.exe"))) {
    $output = $env:TEMP + "\ag.zip"
    $extraDir = $env:TEMP + "\ag"

    Write-Output "Download ag ..."
    $j = Invoke-WebRequest -Uri $agReleasesUrl | ConvertFrom-Json

    $re = [regex]"x86"
    if ($isWin64) {
        $re = [regex]"x64"
    }

    $url = ""
    if ($j[0].assets[0].name -match $re) {
        $url = $j[0].assets[0].browser_download_url
    } else {
        $url = $j[0].assets[1].browser_download_url
    }

    Invoke-WebRequest -Uri $url -OutFile $output

    Write-Output "expand ag.zip ..."
    Expand-Archive $output -DestinationPath $extraDir -Force

    Write-Output "copy ag.exe to ~/.bin"
    Copy-Item -Path ($extraDir + "\ag.exe") -Destination $binDir
    Write-Output "install ag success"

} else {
    Write-Output "ag is already installed"
}

$vimDir = $env:APPDATA + "\vim"
if (!(Test-Path -Path $vimDir)) {
    $output = $env:TEMP + "\vim.zip"
    $extraDir = $env:TEMP + "\vim"

    Write-Output "Download vim ..."
    $j = Invoke-WebRequest -Uri $gvimReleasesUrl | ConvertFrom-Json

    $re = [regex]"_x86.zip$"
    if ($isWin64) {
        $re = [regex]"_x64.zip$"
    }

    $url = ""
    foreach ($asset in $j[0].assets) {
        if ($asset.name -match $re) {
            $url = $asset.browser_download_url
            break
        }
    }

    Invoke-WebRequest -Uri $url -OutFile $output

    Write-Output "expand vim.zip ..."
    Expand-Archive -Path $output -DestinationPath $extraDir -Force

    Write-Output "install vim to " + $vimDir
    Move-Item -Path ($extraDir + "\vim") -Destination $env:APPDATA

    Write-Output "install vim success"
}


$vimfilesDir = $env:USERPROFILE + "\vimfiles"
$dotvimDir = $env:USERPROFILE + "\.vim"
if (!(Test-Path -Path $vimfilesDir)) {
    if (!(Test-Path -Path $dotvimDir)) {
        New-Item -Path $dotvimDir -ItemType Directory
    }

    $cmd = "mklink /d " + $vimfilesDir + " " + $dotvimDir
    $args = "/c `"" + $cmd + "`""
    Start-Process -FilePath "cmd.exe" -Verb runas -ArgumentList $args
}

Invoke-Item -Path $vimDir

Read-Host | Out-Null
Exit
