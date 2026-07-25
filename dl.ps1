$AssetsRoot = "C:\FoundryVTT\Data\assets\ZZZZZFull"
$FolderMap = @{
    'm' = 'Music'
    's' = 'Misc Sound Effects'
}

function Invoke-Download {
    param([string]$Letter, [string]$Url)

    $key = $Letter.ToLower()
    if (-not $FolderMap.ContainsKey($key)) {
        Write-Warning "Unknown prefix '$Letter'. Skipping: $Url"
        return
    }

    $destDir = Join-Path $AssetsRoot $FolderMap[$key]
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    Write-Host "[$key] Downloading: $Url"

    $template = Join-Path $destDir "%(title)s.%(ext)s"
    $result = yt-dlp -x --audio-format mp3 --audio-quality 0 --no-playlist --restrict-filenames -o "$template" --print "after_move:filepath" $Url

    $savedPath = $result | Select-Object -Last 1
    if ($savedPath -and (Test-Path $savedPath)) {
        Write-Host "  Saved: $savedPath"
    }
}

$pairs = @()

if ($args.Count -ge 2 -and $args[0] -eq '-File') {
    $queueFile = $args[1]
    Get-Content $queueFile | Where-Object { $_.Trim() -ne "" } | ForEach-Object {
        $parts = $_.Trim() -split '\s+', 2
        if ($parts.Count -eq 2) { $pairs += , @($parts[0], $parts[1]) }
    }
}
elseif ($args.Count -ge 2) {
    for ($i = 0; $i -lt $args.Count - 1; $i += 2) {
        $pairs += , @($args[$i], $args[$i + 1])
    }
}

if ($pairs.Count -eq 0) {
    Write-Host "No downloads queued. Usage: dl.ps1 m <url> [s <url> ...]  OR  dl.ps1 -File queue.txt"
    exit
}

foreach ($pair in $pairs) {
    Invoke-Download -Letter $pair[0] -Url $pair[1]
}
