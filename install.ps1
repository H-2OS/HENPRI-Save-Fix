<#
  HENPRI Save Fix - Based on NUKITASHI Save Fix , adapted for HENPRI 
  Requires: Windows PowerShell 3.0+ (built into Windows 8+)
#>

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ErrorActionPreference = "Stop"

Write-Host " HENPRI Save Fix Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1. Find game directory
# ============================================================
$gameDir = $null

# Strategy A: script is placed inside the game directory
if (Test-Path "$scriptDir\HENPRI.exe") {
    $gameDir = Resolve-Path "$scriptDir"
}
if (-not $gameDir -and (Test-Path "$scriptDir\..\HENPRI.exe")) {
    $gameDir = Resolve-Path "$scriptDir\.."
}

# Strategy B: search common Steam library paths
if (-not $gameDir) {
    $steamApps = @()
    foreach ($base in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, "C:\", "D:\", "E:\")) {
        if ($base) {
            foreach ($pattern in @(
                "$base\Steam\steamapps\common",
                "$base\Program Files (x86)\Steam\steamapps\common",
                "$base\SteamLibrary\steamapps\common",
                "$base\DeskApps\STEAM\steamapps\common"
            )) {
                foreach ($folder in @("HENPRI")) {
                    $test = "$pattern\$folder"
                    if (Test-Path "$test\HENPRI.exe") {
                        $steamApps += $test
                    }
                }
            }
        }
    }
    $steamApps = $steamApps | Select-Object -Unique

    if ($steamApps.Count -eq 1) {
        $gameDir = $steamApps[0]
    } elseif ($steamApps.Count -gt 1) {
        Write-Host "Found multiple installations:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $steamApps.Count; $i++) {
            Write-Host "  [$($i+1)] $($steamApps[$i])"
        }
        $choice = Read-Host "Select number (1-$($steamApps.Count))"
        $idx = [int]$choice - 1
        if ($idx -ge 0 -and $idx -lt $steamApps.Count) {
            $gameDir = $steamApps[$idx]
        }
    }
}

# Strategy C: manual input
if (-not $gameDir) {
    Write-Host "Game directory not auto-detected." -ForegroundColor Yellow
    Write-Host "Enter the full path to the game folder (e.g. D:\Steam\steamapps\common\HENPRI)"
    $gameDir = Read-Host "Path"
}

# Validate
if (-not $gameDir) {
    Write-Host "ERROR: No game directory provided." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}
# Validation with retry fallback
$retryCount = 0
$maxRetries = 3
while (-not (Test-Path "$gameDir\savedata\saveg.dat")) {
    Write-Host "WARNING: savedata\saveg.dat not found in:" -ForegroundColor Yellow
    Write-Host "  $gameDir" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This means HENPRI.exe was found, but the savedata folder" -ForegroundColor Gray
    Write-Host "is missing or this is not the actual game directory." -ForegroundColor Gray
    Write-Host ""
    Write-Host "Enter the correct game folder path" -ForegroundColor Cyan
    Write-Host "(the folder that contains both HENPRI.exe and savedata\):" -ForegroundColor Cyan
    $gameDir = Read-Host "Path"
    if (-not $gameDir) {
        Write-Host "ERROR: No path provided." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    if (-not (Test-Path "$gameDir\HENPRI.exe")) {
        Write-Host "WARNING: HENPRI.exe not found in that path either." -ForegroundColor Yellow
    }
    $retryCount++
    if ($retryCount -ge $maxRetries) {
        Write-Host "ERROR: Could not find valid game directory after $maxRetries attempts." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host "Game: $gameDir" -ForegroundColor Green
Write-Host ""
$savedir = "$gameDir\savedata"
$advDir = "$gameDir\system\adv"
$uiDir = "$gameDir\system\ui"
$favoDir = "$gameDir\favodata"

# ============================================================
# 2. Backup existing patches (if any)
# ============================================================
Write-Host ""
Write-Host "[1/7] Backing up existing files..." -ForegroundColor Cyan
$backupDir = "$gameDir\system\backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$hasBackup = $false

if (Test-Path "$advDir\fileio.lua") {
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
    Copy-Item "$advDir\fileio.lua" "$backupDir\fileio.lua" -Force
    Write-Host "  Backed up: system/adv/fileio.lua" -ForegroundColor Gray
    $hasBackup = $true
}
if (Test-Path "$advDir\fsave.lua") {
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
    Copy-Item "$advDir\fsave.lua" "$backupDir\fsave.lua" -Force
    Write-Host "  Backed up: system/adv/fsave.lua" -ForegroundColor Gray
    $hasBackup = $true
}
if (Test-Path "$uiDir\favo.lua") {
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
    Copy-Item "$uiDir\favo.lua" "$backupDir\favo.lua" -Force
    Write-Host "  Backed up: system/ui/favo.lua" -ForegroundColor Gray
    $hasBackup = $true
}
if (Test-Path "$gameDir\system\init.lua") {
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
    Copy-Item "$gameDir\system\init.lua" "$backupDir\init.lua" -Force
    Write-Host "  Backed up: system/init.lua" -ForegroundColor Gray
    $hasBackup = $true
}
if (-not $hasBackup) {
    Write-Host "  No existing patches to back up." -ForegroundColor Gray
}

# ============================================================
# 3. Build date table from PNG thumbnails
# ============================================================
Write-Host "[2/7] Reading save dates from thumbnails..." -ForegroundColor Cyan

$pngFiles = Get-ChildItem "$savedir\save[0-9][0-9][0-9][0-9].png" -ErrorAction SilentlyContinue | Sort-Object Name
$dateLines = @()
if ($pngFiles) {
    foreach ($png in $pngFiles) {
        $slot = [int]($png.BaseName.Substring(4, 4))
        $dt = $png.LastWriteTime
        $dateLines += "`t[$slot]`t= {$($dt.Year),$($dt.Month),$($dt.Day),$($dt.Hour),$($dt.Minute),$($dt.Second)},"
    }
    Write-Host "  Found $($pngFiles.Count) save thumbnails" -ForegroundColor Green
} else {
    Write-Host "  No thumbnails found, date table will be empty" -ForegroundColor Yellow
}
$dateTable = "_save_dates = {`r`n" + ($dateLines -join "`r`n") + "`r`n}"

# ============================================================
# 4. Create favodata directory
# ============================================================
Write-Host "[3/7] Creating favodata directory..." -ForegroundColor Cyan

if (-not (Test-Path $favoDir)) {
    New-Item -ItemType Directory -Path $favoDir -Force | Out-Null
    Write-Host "  Created: $favoDir" -ForegroundColor Green
} else {
    Write-Host "  Already exists: $favoDir" -ForegroundColor Gray
}

# ============================================================
# 5. Generate and deploy fileio.lua
# ============================================================
Write-Host "[4/7] Generating fileio.lua..." -ForegroundColor Cyan

$template = Get-Content "$scriptDir\fileio_template.lua" -Raw -Encoding UTF8
$fileio_lua = $template.Replace("-- DATE_TABLE_PLACEHOLDER --", $dateTable)

if (-not (Test-Path $advDir)) { New-Item -ItemType Directory -Path $advDir -Force | Out-Null }
[System.IO.File]::WriteAllText("$advDir\fileio.lua", $fileio_lua, [System.Text.UTF8Encoding]($false))
Write-Host "  Created: $advDir\fileio.lua ($($fileio_lua.Length) bytes)" -ForegroundColor Green

# ============================================================
# 6. Deploy fsave.lua
# ============================================================
Write-Host "[5/7] Deploying fsave.lua..." -ForegroundColor Cyan

$fsaveSrc = "$scriptDir\fsave.lua"
if (Test-Path $fsaveSrc) {
    Copy-Item $fsaveSrc "$advDir\fsave.lua" -Force
    Write-Host "  Created: $advDir\fsave.lua" -ForegroundColor Green
    } else {
    Write-Host "  ERROR: fsave.lua not found in package" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# ============================================================
# 7. Deploy favo.lua
# ============================================================
Write-Host "[6/7] Deploying favo.lua..." -ForegroundColor Cyan

$favoSrc = "$scriptDir\favo.lua"
if (Test-Path $favoSrc) {
    if (-not (Test-Path $uiDir)) { New-Item -ItemType Directory -Path $uiDir -Force | Out-Null }
    Copy-Item $favoSrc "$uiDir\favo.lua" -Force
    Write-Host "  Created: $uiDir\favo.lua" -ForegroundColor Green
} else {
    Write-Host "  ERROR: favo.lua not found in package" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# ============================================================
# 8. Deploy init.lua
# ============================================================
Write-Host "[7/7] Deploying init.lua..." -ForegroundColor Cyan

$initSrc = "$scriptDir\init.lua"
if (Test-Path $initSrc) {
    Copy-Item $initSrc "$gameDir\system\init.lua" -Force
    Write-Host "  Created: $gameDir\system\init.lua" -ForegroundColor Green
    Write-Host "    - Auto-export voice favorites to favodata/ on startup" -ForegroundColor Gray
} else {
    Write-Host "  ERROR: init.lua not found in package" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# ============================================================
# Done
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Installation complete! The fix is now active." -ForegroundColor Green