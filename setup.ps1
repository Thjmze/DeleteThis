<#
.SYNOPSIS
    One-time setup: installs yt-dlp and ffmpeg as standalone binaries
    (no winget / no admin rights needed), for use over a plain SSH session.
#>

$ToolsDir = Join-Path $env:USERPROFILE "bin"

if (-not (Test-Path $ToolsDir)) {
    New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
}

Write-Host "Installing to: $ToolsDir"

# --- yt-dlp ---
$ytdlpExe = Join-Path $ToolsDir "yt-dlp.exe"
Write-Host "Downloading yt-dlp..."
Invoke-WebRequest -Uri "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" -OutFile $ytdlpExe
Write-Host "  -> $ytdlpExe"

# --- ffmpeg (static build, no installer) ---
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ffmpegZip = Join-Path $env:TEMP "ffmpeg.zip"
$ffmpegExtract = Join-Path $env:TEMP "ffmpeg-extract"
Write-Host "Downloading ffmpeg (this is ~100MB, may take a minute)..."
Invoke-WebRequest -Uri "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" -OutFile $ffmpegZip -UseBasicParsing

if (Test-Path $ffmpegExtract) { Remove-Item $ffmpegExtract -Recurse -Force }
Expand-Archive -Path $ffmpegZip -DestinationPath $ffmpegExtract -Force

$ffmpegBinSrc = Get-ChildItem $ffmpegExtract -Recurse -Filter "ffmpeg.exe" | Select-Object -First 1 | Split-Path -Parent
Copy-Item (Join-Path $ffmpegBinSrc "ffmpeg.exe") $ToolsDir -Force
Copy-Item (Join-Path $ffmpegBinSrc "ffprobe.exe") $ToolsDir -Force
Write-Host "  -> $ToolsDir\ffmpeg.exe"

Remove-Item $ffmpegZip -Force
Remove-Item $ffmpegExtract -Recurse -Force

# --- Add to User PATH if not already present ---
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($currentPath -notlike "*$ToolsDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$ToolsDir", "User")
    Write-Host ""
    Write-Host "Added $ToolsDir to your User PATH. Start a NEW session for it to take effect."
}
else {
    Write-Host ""
    Write-Host "$ToolsDir already on PATH."
}

Write-Host ""
Write-Host "Done. Verify with:"
Write-Host "  yt-dlp --version"
Write-Host "  ffmpeg -version"
