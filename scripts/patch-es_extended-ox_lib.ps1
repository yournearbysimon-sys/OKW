# Patches es_extended fxmanifest.lua so global `lib` (ox_lib) exists on the client.
#
# Windows (local / Windows VPS):
#   cd ...\OKW_Framework\scripts
#   .\patch-es_extended-ox_lib.ps1 -EsExtendedRoot "...\es_extended"
# If you see "not recognized", you are not in the scripts folder. Either cd there or:
#   & "C:\full\path\to\OKW_Framework\scripts\patch-es_extended-ox_lib.ps1" -EsExtendedRoot "..."
#
# Linux VPS: use patch-es_extended-ox_lib.py instead of PowerShell.
param(
    [string] $EsExtendedRoot = "",
    [string] $FxManifestPath = "",
    [switch] $WhatIf
)

$ErrorActionPreference = "Stop"

if ($FxManifestPath -eq "" -and $EsExtendedRoot -ne "") {
    $root = $EsExtendedRoot.TrimEnd('\', '/')
    if (-not (Test-Path -LiteralPath $root)) {
        Write-Host "[error] Folder not found: $root"
        Write-Host "Replace the path with your real es_extended folder (not C:\path\to\...)."
        exit 1
    }
    $FxManifestPath = Join-Path $root "fxmanifest.lua"
}

if ($FxManifestPath -eq "") {
    Write-Host "Usage (pick ONE switch; not both on the same line):"
    Write-Host '  .\patch-es_extended-ox_lib.ps1 -EsExtendedRoot "D:\FXServer\resources\[core]\es_extended"'
    Write-Host '  .\patch-es_extended-ox_lib.ps1 -FxManifestPath "D:\FXServer\resources\[core]\es_extended\fxmanifest.lua"'
    Write-Host ""
    Write-Host "On Windows VPS, if you do not know the path, run first:"
    Write-Host "  .\find-es_extended.ps1"
    Write-Host "or:"
    Write-Host '  .\find-es_extended.ps1 -SearchRoot ''D:\path\to\resources'''
    exit 1
}

if (-not (Test-Path -LiteralPath $FxManifestPath)) {
    Write-Host "[error] File not found: $FxManifestPath"
    if ($EsExtendedRoot -ne "" -and $FxManifestPath -like "*fxmanifest.lua") {
        Write-Host "Checked es_extended root: $($EsExtendedRoot.TrimEnd('\','/'))"
    }
    Write-Host "Use your real FXServer resources path, e.g. ...\resources\[core]\es_extended\fxmanifest.lua"
    exit 1
}

$raw = [IO.File]::ReadAllText($FxManifestPath)
$orig = $raw

if ($raw -match "@ox_lib/init\.lua") {
    Write-Host "[ok] Already contains @ox_lib/init.lua : $FxManifestPath"
    exit 0
}

$injectLine = "    '@ox_lib/init.lua',`n"
$newRaw = [regex]::Replace(
    $raw,
    '(shared_scripts\s*\{\s*\r?\n)',
    { param($m) $m.Groups[1].Value + $injectLine },
    1
)
if ($newRaw -eq $raw) {
    $newRaw = [regex]::Replace(
        $raw,
        '(shared_scripts\s*\{)',
        { param($m) $m.Groups[1].Value + "`n" + $injectLine.TrimEnd("`n") },
        1
    )
}
$raw = $newRaw

if ($raw -eq $orig) {
    Write-Host "[error] No usable shared_scripts block. Add @ox_lib/init.lua manually to shared_scripts."
    exit 2
}

if ($raw -notmatch "['`"]ox_lib['`"]") {
    $depBefore = $raw
    $raw = [regex]::Replace(
        $raw,
        '(dependencies\s*\{\s*\r?\n)',
        { param($m) $m.Groups[1].Value + "    'ox_lib',`n" },
        1
    )
    if ($raw -eq $depBefore) {
        $raw = [regex]::Replace(
            $raw,
            '(dependencies\s*\{)',
            { param($m) $m.Groups[1].Value + "`n    'ox_lib',`n" },
            1
        )
    }
    if ($raw -eq $depBefore) {
        $raw = $raw.TrimEnd() + "`n`ndependencies {`n    'ox_lib',`n}`n"
    }
}

if ($WhatIf) {
    Write-Host $raw
    exit 0
}

$bak = $FxManifestPath + ".bak-oxlib-" + (Get-Date -Format "yyyyMMdd-HHmmss")
Copy-Item -LiteralPath $FxManifestPath -Destination $bak
[IO.File]::WriteAllText($FxManifestPath, $raw, [Text.UTF8Encoding]::new($false))
Write-Host "[ok] Patched: $FxManifestPath"
Write-Host "[ok] Backup:  $bak"
Write-Host ""
Write-Host "In server.cfg start ox_lib BEFORE es_extended (see server-cfg-ox-order-snippet.txt)."
