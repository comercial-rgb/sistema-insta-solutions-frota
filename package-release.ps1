param(
    [string]$ZipPath = ("release-{0}.zip" -f (Get-Date -Format "yyyyMMdd-HHmmss")),
    [string]$ManifestPath = "release-manifest.json",
    [string[]]$Exclude = @(
        ".git\\*",
        "tmp\\*",
        "log\\*",
        "storage\\*",
        "node_modules\\*",
        "vendor\\bundle\\*",
        "coverage\\*",
        "*.zip"
    )
)

$ErrorActionPreference = "Stop"

# 1) Generate manifest
& "$PSScriptRoot\generate-manifest.ps1" -OutputPath $ManifestPath -Exclude $Exclude

$manifestHash = (Get-FileHash -Algorithm SHA256 -Path $ManifestPath).Hash
$buildInfo = [ordered]@{
    buildId = ("{0}-{1}" -f (Get-Date -Format "yyyyMMdd-HHmmss"), $manifestHash.Substring(0, 12))
    generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    machine = $env:COMPUTERNAME
    user = $env:USERNAME
    manifestSha256 = $manifestHash
    git = $null
}

try {
    $isRepo = (git rev-parse --is-inside-work-tree 2>$null)
    if ($LASTEXITCODE -eq 0 -and $isRepo -eq "true") {
        $buildInfo.git = [ordered]@{
            branch = (git rev-parse --abbrev-ref HEAD 2>$null)
            commit = (git rev-parse HEAD 2>$null)
            remote = (git remote get-url origin 2>$null)
        }
    }
} catch {
    # ignore
}

# 2) Create a staging folder to zip
$staging = Join-Path $env:TEMP ("insta-release-{0}" -f ([guid]::NewGuid().ToString("n")))
New-Item -ItemType Directory -Path $staging | Out-Null

try {
    $root = (Resolve-Path ".\").Path
    $excludeRegex = ($Exclude | ForEach-Object {
            $pattern = [Regex]::Escape($_) -replace "\\\\\*", ".*" -replace "\\\*", ".*"
            "^" + ($pattern -replace "\\\\", "\\\\") + "$"
        }) -join "|"

    Get-ChildItem -Path $root -Recurse -File -Force |
        Where-Object {
            $rel = $_.FullName.Substring($root.Length).TrimStart('\','/') -replace '/', '\\'
            if ([string]::IsNullOrWhiteSpace($rel)) { return $false }
            if ($excludeRegex -and ($rel -match $excludeRegex)) { return $false }
            return $true
        } |
        ForEach-Object {
            $rel = $_.FullName.Substring($root.Length).TrimStart('\','/')
            $dest = Join-Path $staging $rel
            $destDir = Split-Path -Parent $dest
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
            Copy-Item -Path $_.FullName -Destination $dest -Force
        }

    # Ensure manifest is included
    Copy-Item -Path $ManifestPath -Destination (Join-Path $staging $ManifestPath) -Force

    # Add a tiny public build marker (can be checked via https://<host>/build.json)
    $publicDir = Join-Path $staging "public"
    if (-not (Test-Path $publicDir)) { New-Item -ItemType Directory -Path $publicDir -Force | Out-Null }
    $buildJsonPath = Join-Path $publicDir "build.json"
    ($buildInfo | ConvertTo-Json -Depth 5) | Set-Content -Path $buildJsonPath -Encoding UTF8

    if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
    Compress-Archive -Path (Join-Path $staging '*') -DestinationPath $ZipPath -Force

    $zipHash = (Get-FileHash -Algorithm SHA256 -Path $ZipPath).Hash
    Write-Host ("[OK] ZIP criado: {0}" -f (Resolve-Path $ZipPath).Path)
    Write-Host ("      SHA256: {0}" -f $zipHash)
} finally {
    try {
        if ($staging -and (Test-Path -LiteralPath $staging)) {
            Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
        }
    } catch {
        # ignore cleanup errors
    }
}
