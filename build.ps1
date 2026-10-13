param([switch]$Run, [switch]$Package)
$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$runtimeRoot = 'C:/ProgramData/GameMakerStudio2-LTS2026/Cache/runtimes'
$runtime = Get-ChildItem -LiteralPath $runtimeRoot -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $runtime) { throw 'Install the Windows runtime in GameMaker first.' }
$igor = Join-Path $runtime.FullName 'bin/igor/windows/x64/Igor.exe'
$profileRoot = Join-Path $env:APPDATA 'GameMakerStudio2-LTS2026'
$licensedProfile = Get-ChildItem -LiteralPath $profileRoot -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'licence.plist') } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$userDir = if ($licensedProfile) {$licensedProfile.FullName} else {Join-Path $profileRoot 'unknownUser_unknownUserID'}
$command = if ($Package) {'PackageZip'} elseif ($Run) {'Run'} else {'Compile'}
New-Item -ItemType Directory -Force -Path "$projectRoot/build/package" | Out-Null
& $igor "/rp=$($runtime.FullName)" "/uf=$userDir" "/project=$projectRoot/DeadFrequency.yyp" "/cache=$projectRoot/.cache" "/temp=$projectRoot/.temp" "/of=$projectRoot/build/package/DeadFrequency" "/tf=$projectRoot/build/DeadFrequency-Windows.zip" -- Windows $command
if ($LASTEXITCODE -ne 0) { throw "GameMaker exited with $LASTEXITCODE" }
if ($Package) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead("$projectRoot/build/DeadFrequency-Windows.zip")
    try { if (-not ($archive.Entries | Where-Object FullName -Match '\.exe$')) {throw 'Archive has no executable.'} }
    finally {$archive.Dispose()}
}
