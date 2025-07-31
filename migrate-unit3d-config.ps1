# Script de Migración de Configuraciones UNIT3D
# Autor: GitHub Copilot
# Fecha: $(Get-Date)
# Descripción: Migra configuraciones personalizadas entre versiones de UNIT3D

param(
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,
    
    [Parameter(Mandatory=$true)]
    [string]$TargetPath,
    
    [switch]$DryRun = $false
)

Write-Host "=== MIGRACIÓN DE CONFIGURACIONES UNIT3D ===" -ForegroundColor Cyan
Write-Host "Origen: $SourcePath" -ForegroundColor Yellow
Write-Host "Destino: $TargetPath" -ForegroundColor Yellow
Write-Host "Modo de prueba: $DryRun" -ForegroundColor Yellow
Write-Host ""

# Archivos críticos de configuración a comparar
$criticalConfigs = @(
    'app.php', 'unit3d.php', 'filesystems.php', 
    'torrent.php', 'other.php', 'auth.php'
)

# Función para comparar archivos
function Compare-ConfigFiles {
    param($file1, $file2)
    
    if ((Test-Path $file1) -and (Test-Path $file2)) {
        $hash1 = (Get-FileHash $file1).Hash
        $hash2 = (Get-FileHash $file2).Hash
        return $hash1 -ne $hash2
    }
    return $false
}

# Función para mostrar diferencias
function Show-Differences {
    param($file1, $file2, $configName)
    
    Write-Host "Diferencias en $configName:" -ForegroundColor Yellow
    $diff = Compare-Object (Get-Content $file1) (Get-Content $file2) -IncludeEqual | 
            Where-Object {$_.SideIndicator -ne "=="}
    
    if ($diff.Count -gt 0) {
        Write-Host "  - Líneas diferentes: $($diff.Count)" -ForegroundColor Red
        $diff | Select-Object -First 5 | ForEach-Object {
            $indicator = if ($_.SideIndicator -eq "<=") { "ORIGEN" } else { "DESTINO" }
            Write-Host "    [$indicator] $($_.InputObject)" -ForegroundColor White
        }
        if ($diff.Count -gt 5) {
            Write-Host "    ... y $($diff.Count - 5) diferencias más" -ForegroundColor Gray
        }
    } else {
        Write-Host "  - Archivos idénticos" -ForegroundColor Green
    }
    Write-Host ""
}

# Ejemplo de uso:
# .\migrate-unit3d-config.ps1 -SourcePath "D:\path\to\UNIT3D-9.0.8" -TargetPath "D:\path\to\UNIT3D-9.1.5" -DryRun
