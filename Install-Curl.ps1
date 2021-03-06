#Requires -RunAsAdministrator
<#
.Synopsis
   Automatically install cURL in Windows
.DESCRIPTION
   A script that can either copy a local copy of cURL to either a specified directory or default install directory or download from a specified or pre-specified location. 
.EXAMPLE
   Install-Curl.ps1
.EXAMPLE
   Install-Curl.ps1 -installDirectory "C:\Temp" -Force32BitInstall -ForceDownload -32BitDownloadLocation "https://bintray.com/artifact/download/vszakats/generic/curl-7.50.0-win64-mingw.7z"
.INPUTS
   $installDirectory
   $Force32BitInstall
   $ForceDownload
   $32BitDownloadLocation
   $64BitDownloadLocation
.NOTES
   Running the script as is will copy curl.exe and ca-bundle.crt to their respective architecture and default install location and if it can't find those files, will download it from winamppugins.co.uk   
#>
[CmdletBinding()]
Param (
    [Parameter(Mandatory=$false)]
    [String]
    $installDirectory = $env:ProgramFiles,

    [Parameter(Mandatory=$false)]
    [Switch]
    $Force32BitInstall,

    [Parameter(Mandatory=$false)]
    [Switch]
    $ForceDownload,
    
    [Parameter(Mandatory=$false)]
    [String]
    $32BitDownloadLocation = "https://winampplugins.co.uk/curl/curl_7_53_0_openssl_nghttp2_x86.7z",

    [Parameter(Mandatory=$false)]
    [String]
    $64BitDownloadLocation = "https://winampplugins.co.uk/curl/curl_7_53_0_openssl_nghttp2_x64.7z"
)

Set-StrictMode -Version Latest

# Check for OS architecture
$osArch = (Get-WmiObject -Class Win32_ComputerSystem).SystemType
if ($osArch -match "x64" -and !$Force32BitInstall) { 
    $archChoice = 64
}

else {   
    $archChoice = 32
}
$downloadCurl = $false
# If  local files are not present or $ForceDownload parameter is set, download cURL
if ((!((Test-Path .\curl_x64.exe) -and (Test-Path .\curl_x86.exe) -and (Test-Path .\ca-bundle.crt))) -or ($ForceDownload)) {

    # Download 32-bit cURL
    if ($archChoice -eq 32) { 
        Invoke-WebRequest -Uri $32BitDownloadLocation -OutFile "$env:TEMP\curl.7z" -Verbose
        $downloadCurl = $true
    }

    # Download 64-bit cURL  
    else {        
        Invoke-WebRequest -Uri $64BitDownloadLocation -OutFile "$env:TEMP\curl.7z" -Verbose
        $downloadCurl = $true
    }

}

# In case of 32-bit installs on 64-bit machines
if ($Force32BitInstall -and $osArch -match "x64" -and $installDirectory -eq $env:ProgramFiles) { 
    $installDirectory = ${env:ProgramFiles(x86)}
}

# Create the folder
try {
    New-Item -Path "$installDirectory\cURL" -ItemType Directory -ErrorAction Stop -Verbose
}

catch [System.IO.IOException] {
    Write-Warning "cURL folder already exists. Will overwrite files."
}

# Unzip the files to the install directory
if ($downloadCurl) {
    & .\7za.exe e "$env:TEMP\curl.7z" -o"$installDirectory\cURL" -y
}

else {
    # Copy 32-bit cURL to install directory
    if ($archChoice -eq 32) {
        Copy-Item -Path .\curl_x86.exe -Destination $installDirectory\cURL\curl.exe -Verbose
        Copy-Item -Path .\ca-bundle.crt -Destination $installDirectory\cURL\ -Verbose
    }
    # Copy 64-bit cURL to install directory
    else {
        Copy-Item -Path .\curl_x64.exe -Destination $installDirectory\cURL\curl.exe -Verbose
        Copy-Item -Path .\ca-bundle.crt -Destination $installDirectory\cURL\ -Verbose
    }
}

# Old extraction code / alternative to 7-zip
<# Old extraction code
$shell = new-object -com shell.application
$zip = $shell.NameSpace("$env:TEMP\curl.zip")
foreach($item in $zip.items())
{
$shell.Namespace("$installDirectory\cURL").copyhere($item)
}
#>

# Add location to PATH variable

$pathKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
#$pathValue = Get-ItemPropertyValue -Path $pathKey -Name "Path"
$pathValue = $env:Path
if ($pathValue -notlike "*$installDirectory\cURL*") {
    $pathValue = "$pathValue;$installDirectory\cURL"
    Set-ItemProperty -Path $pathKey -Name "Path" -Value $pathValue -Verbose
}
else {
    Write-Warning "Already in System PATH"
}

# Clean up temp files
if ($downloadCurl) {
    Remove-Item -Path $env:TEMP\curl.7z -Force -Verbose
}