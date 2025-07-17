# Migration AppBar PowerShell Script - Version Corrigee
# Usage: .\migrate-appbar.ps1

param(
    [switch]$DryRun,
    [switch]$Restore,
    [string]$ProjectPath = "."
)

$ErrorActionPreference = "Stop"

Write-Host "Migration AppBar Kipik" -ForegroundColor Green
Write-Host "Dossier projet: $ProjectPath" -ForegroundColor Cyan

# Trouve tous les fichiers Dart
$dartFiles = Get-ChildItem -Path "$ProjectPath\lib" -Recurse -Filter "*.dart" | Where-Object {
    $_.DirectoryName -notmatch "generated"
}

Write-Host "Fichiers Dart trouves: $($dartFiles.Count)" -ForegroundColor Yellow

$filesToMigrate = @()
$backupFolder = "$ProjectPath\.appbar-backups"

# Analyser les fichiers
foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    
    $hasOldAppBar = $false
    $appBarsFound = @()
    
    # Detecter les anciens AppBars
    if ($content -match "CustomAppBarParticulier") {
        $hasOldAppBar = $true
        $appBarsFound += "CustomAppBarParticulier"
    }
    
    if ($content -match "CustomAppBarKipik") {
        $hasOldAppBar = $true
        $appBarsFound += "CustomAppBarKipik"
    }
    
    if ($content -match "GptAppBar") {
        $hasOldAppBar = $true
        $appBarsFound += "GptAppBar"
    }
    
    if ($hasOldAppBar) {
        $filesToMigrate += @{
            File = $file
            AppBars = $appBarsFound
        }
        Write-Host "Fichier: $($file.Name) - AppBars: $($appBarsFound -join ', ')" -ForegroundColor White
    }
}

if ($filesToMigrate.Count -eq 0) {
    Write-Host "Aucun AppBar a migrer trouve!" -ForegroundColor Green
    exit 0
}

Write-Host "Fichiers necessitant une migration: $($filesToMigrate.Count)" -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "MODE DRY-RUN - Aucun fichier ne sera modifie" -ForegroundColor Magenta
    foreach ($item in $filesToMigrate) {
        Write-Host "  $($item.File.Name)" -ForegroundColor Gray
    }
    exit 0
}

if ($Restore) {
    Write-Host "Restauration des backups..." -ForegroundColor Blue
    
    if (Test-Path $backupFolder) {
        $backupFiles = Get-ChildItem $backupFolder -Filter "*.backup"
        
        foreach ($backup in $backupFiles) {
            $originalFile = $backup.Name -replace "\.backup$", ""
            $originalPath = Get-ChildItem -Path "$ProjectPath\lib" -Recurse -Filter $originalFile | Select-Object -First 1
            
            if ($originalPath) {
                Copy-Item $backup.FullName $originalPath.FullName -Force
                Write-Host "Restaure: $($originalPath.Name)" -ForegroundColor Green
            }
        }
        
        Remove-Item $backupFolder -Recurse -Force
        Write-Host "Restauration terminee!" -ForegroundColor Green
    } else {
        Write-Host "Aucun backup trouve" -ForegroundColor Red
    }
    exit 0
}

# Confirmation
$response = Read-Host "Migrer $($filesToMigrate.Count) fichiers ? (y/N)"
if ($response -ne "y") {
    Write-Host "Migration annulee" -ForegroundColor Red
    exit 0
}

# Creer dossier backup
if (!(Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder | Out-Null
}

Write-Host "Debut de la migration..." -ForegroundColor Green

$successCount = 0

foreach ($item in $filesToMigrate) {
    $file = $item.File
    $appBars = $item.AppBars
    
    try {
        # Backup
        $backupPath = Join-Path $backupFolder "$($file.Name).backup"
        Copy-Item $file.FullName $backupPath -Force
        
        # Lire contenu
        $content = Get-Content $file.FullName -Raw -Encoding UTF8
        $originalContent = $content
        
        # === MIGRATIONS ===
        
        # 1. Remplacer les imports
        $importPattern1 = "import.*custom_app_bar_particulier.*\.dart';"
        $importReplacement = "import '../../widgets/common/app_bars/universal_app_bar_kipik.dart';"
        $content = $content -replace $importPattern1, $importReplacement
        
        $importPattern2 = "import.*custom_app_bar_kipik.*\.dart';"
        $content = $content -replace $importPattern2, $importReplacement
        
        $importPattern3 = "import.*gpt_app_bar.*\.dart';"
        $content = $content -replace $importPattern3, $importReplacement
        
        # 2. CustomAppBarParticulier
        if ($appBars -contains "CustomAppBarParticulier") {
            $content = $content -replace "CustomAppBarParticulier\(", "UniversalAppBarKipik.particulier("
            $content = $content -replace "showBurger:", "showDrawer:"
            $content = $content -replace "onBackButtonPressed:", "onBackPressed:"
            $content = $content -replace "redirectToHome:\s*[^,\)]+,?\s*", ""
        }
        
        # 3. CustomAppBarKipik
        if ($appBars -contains "CustomAppBarKipik") {
            # Detecter useProStyle
            if ($content -match "useProStyle:\s*true") {
                $content = $content -replace "CustomAppBarKipik\(", "UniversalAppBarKipik.pro("
                $content = $content -replace "useProStyle:\s*true,?\s*", "showUserAvatar: true,"
            } else {
                $content = $content -replace "CustomAppBarKipik\(", "UniversalAppBarKipik.particulier("
                $content = $content -replace "useProStyle:\s*false,?\s*", ""
            }
            $content = $content -replace "showBurger:", "showDrawer:"
        }
        
        # 4. GptAppBar
        if ($appBars -contains "GptAppBar") {
            $content = $content -replace "GptAppBar\(", "UniversalAppBarKipik.particulier("
            $content = $content -replace "showMenu:", "showDrawer:"
        }
        
        # Sauvegarder si changements
        if ($content -ne $originalContent) {
            $content | Set-Content $file.FullName -Encoding UTF8
            Write-Host "Migre: $($file.Name)" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "Aucun changement: $($file.Name)" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "Erreur $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "Migration terminee!" -ForegroundColor Green
Write-Host "Fichiers migres: $successCount/$($filesToMigrate.Count)" -ForegroundColor Cyan
Write-Host "Backups sauves dans: $backupFolder" -ForegroundColor Yellow

Write-Host "Prochaines etapes:" -ForegroundColor Magenta
Write-Host "  1. Tester votre application" -ForegroundColor White
Write-Host "  2. git add . && git commit -m 'Migration AppBar'" -ForegroundColor White
Write-Host "  3. Si probleme: .\migrate-appbar.ps1 -Restore" -ForegroundColor White