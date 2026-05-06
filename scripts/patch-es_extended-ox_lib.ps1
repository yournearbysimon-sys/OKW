# Patches es_extended fxmanifest.lua so global `lib` (ox_lib) exists on the client.
#
# Usage:
#   .\patch-es_extended-ox_lib.ps1 -EsExtendedRoot "C:\FXServer\...\resources\[core]\es_extended"
#   .\patch-es_extended-ox_lib.ps1 -FxManifestPath "C:\...\es_extended\fxmanifest.lua"

param(
    [string] $EsExtendedRoot = "",
    [string] $FxManifestPath = "",
    [switch] $WhatIf
)

$ErrorActionPreference = "Stop"

if ($FxManifestPath -eq "" -and $EsExtendedRoot -ne "") {
    $FxManifestPath = Join-Path $EsExtendedRoot.TrimEnd('\', '/') "fxmanifest.lua"
}

if ($FxManifestPath -eq "" -or -not (Test-Path -LiteralPath $FxManifestPath)) {
    Write-Host "Usage:"
    Write-Host '  .\patch-es_extended-ox_lib.ps1 -EsExtendedRoot "D:\FXServer\resources\[core]\es_extended"'
    Write-Host '  .\patch-es_extended-ox_lib.ps1 -FxManifestPath "D:\path\to\es_extended\fxmanifest.lua"'
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
