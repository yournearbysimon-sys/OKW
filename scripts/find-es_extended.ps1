# Finds es_extended\fxmanifest.lua on this Windows machine (e.g. FXServer VPS).
#
# Usage:
#   .\find-es_extended.ps1
#   .\find-es_extended.ps1 -SearchRoot 'D:\fivem\server-data\resources'
#
# Then run ONLY ONE of these (do not combine both switches):
#   .\patch-es_extended-ox_lib.ps1 -EsExtendedRoot 'PASTE_FOLDER_PATH_HERE'

param(
    [string] $SearchRoot = ""
)

function Find-EsExtendedManifest {
    param([Parameter(Mandatory)][string] $Root)

    if (-not (Test-Path -LiteralPath $Root)) {
        return $null
    }
    Get-ChildItem -LiteralPath $Root -Recurse -Filter "fxmanifest.lua" -ErrorAction SilentlyContinue |
        Where-Object { $_.Directory.Name -eq "es_extended" } |
        Select-Object -First 1
}

if ($SearchRoot -ne "") {
    $hit = Find-EsExtendedManifest -Root $SearchRoot
    if (-not $hit) {
        Write-Host "[error] No es_extended\fxmanifest.lua under: $SearchRoot"
        exit 1
    }
} else {
    $candidates = @(
        "C:\FXServer",
        "D:\FXServer",
        "E:\FXServer",
        (Join-Path $env:USERPROFILE "FXServer"),
        (Join-Path $env:USERPROFILE "Desktop\5STAR\server-data\resources"),
        "C:\fivem",
        "D:\fivem",
        "C:\server",
        "D:\server"
    ) | Select-Object -Unique

    $hit = $null
    foreach ($c in $candidates) {
        $hit = Find-EsExtendedManifest -Root $c
        if ($hit) { break }
    }
    if (-not $hit) {
        Write-Host "[error] es_extended not found under common folders:"
        Write-Host "  C:\FXServer, D:\FXServer, $($env:USERPROFILE)\FXServer, C:\fivem, D:\fivem, ..."
        Write-Host ""
        Write-Host "Open File Explorer, go to the folder that contains your ``resources`` folder,"
        Write-Host "then run (use YOUR path in single quotes):"
        Write-Host '  .\find-es_extended.ps1 -SearchRoot ''D:\full\path\to\resources'''
        exit 1
    }
}

$dir = $hit.Directory.FullName
Write-Host "[ok] Found:"
Write-Host "     $($hit.FullName)"
Write-Host ""
Write-Host "Patch (one line; use ONLY -EsExtendedRoot, not both switches):"
Write-Host "  .\patch-es_extended-ox_lib.ps1 -EsExtendedRoot `"$dir`""
