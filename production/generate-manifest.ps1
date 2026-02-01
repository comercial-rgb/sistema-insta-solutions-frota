param(
    [string]$OutputPath = ("manifest-{0}-{1}.json" -f $env:COMPUTERNAME, (Get-Date -Format "yyyyMMdd-HHmmss")),
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

function Get-GitInfo {
    try {
        $isRepo = (git rev-parse --is-inside-work-tree 2>$null)
        if ($LASTEXITCODE -ne 0 -or $isRepo -ne "true") { return $null }

        $branch = (git rev-parse --abbrev-ref HEAD 2>$null)
        $commit = (git rev-parse HEAD 2>$null)
        $remote = (git remote get-url origin 2>$null)

        return [ordered]@{
            branch = $branch
            commit = $commit
            remote = $remote
        }
    } catch {
        return $null
    }
}

$root = (Resolve-Path ".").Path
$excludeRegex = ($Exclude | ForEach-Object {
        # convert simple wildcard-like patterns to regex
        $pattern = [Regex]::Escape($_) -replace "\\\\\*", ".*" -replace "\\\*", ".*"
        "^" + ($pattern -replace "\\\\", "\\\\") + "$"
    }) -join "|"

$files = Get-ChildItem -Path $root -Recurse -File -Force |
    Where-Object {
        $rel = $_.FullName.Substring($root.Length).TrimStart('\','/') -replace '/', '\\'
        if ([string]::IsNullOrWhiteSpace($rel)) { return $false }
        if ($excludeRegex -and ($rel -match $excludeRegex)) { return $false }
        return $true
    } |
    ForEach-Object {
        $rel = $_.FullName.Substring($root.Length).TrimStart('\','/') -replace '/', '\\'
        $hash = (Get-FileHash -Algorithm SHA256 -Path $_.FullName).Hash
        [ordered]@{
            path = $rel
            size = $_.Length
            sha256 = $hash
            lastWriteTimeUtc = $_.LastWriteTimeUtc.ToString("o")
        }
    } |
    Sort-Object path

$manifest = [ordered]@{
    generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    machine = $env:COMPUTERNAME
    user = $env:USERNAME
    root = $root
    git = (Get-GitInfo)
    exclude = $Exclude
    files = $files
}

$manifest | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host ("[OK] Manifest gerado: {0}" -f (Resolve-Path $OutputPath).Path)
Write-Host ("      Arquivos: {0}" -f $files.Count)
