$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $ProjectRoot

function Resolve-Tool {
    param(
        [string]$ExeName,
        [string[]]$CandidatePaths
    )
    $cmd = Get-Command $ExeName -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }
    foreach ($pattern in $CandidatePaths) {
        $match = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($match) {
            return $match.FullName
        }
    }
    throw "Ferramenta obrigatória não encontrada: $ExeName"
}

function Invoke-GodotChecked {
    param(
        [string]$GodotExe,
        [string[]]$Arguments
    )
    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = & $GodotExe @Arguments 2>&1 | ForEach-Object { $_.ToString() }
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $prevPref

    $output | ForEach-Object { Write-Host $_ }

    if ($exitCode -ne 0) {
        exit $exitCode
    }
    $errorLines = $output | Where-Object { $_ -match "^(SCRIPT ERROR:|ERROR:)" }
    if ($errorLines) {
        Write-Error "Godot reportou erros de script/engine durante a verificação."
        exit 1
    }
}

$gdlint = Resolve-Tool -ExeName "gdlint" -CandidatePaths @(
    "$env:LOCALAPPDATA\Packages\PythonSoftwareFoundation.Python*\LocalCache\local-packages\Python*\Scripts\gdlint.exe",
    "$env:APPDATA\Python\Python*\Scripts\gdlint.exe"
)

$gdformat = Resolve-Tool -ExeName "gdformat" -CandidatePaths @(
    "$env:LOCALAPPDATA\Packages\PythonSoftwareFoundation.Python*\LocalCache\local-packages\Python*\Scripts\gdformat.exe",
    "$env:APPDATA\Python\Python*\Scripts\gdformat.exe"
)

$godotConsole = Resolve-Tool -ExeName "godot_console" -CandidatePaths @(
    "$env:LOCALAPPDATA\Microsoft\WinGet\Links\godot_console.exe",
    "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine*\Godot_*_console.exe"
)

$gdDirs = @("core", "games", "shared", "tests") | Where-Object { Test-Path $_ }

Write-Host "==> 1/4 Executando gdlint..." -ForegroundColor Cyan
& $gdlint @gdDirs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "==> 2/4 Executando gdformat --check..." -ForegroundColor Cyan
& $gdformat --check @gdDirs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "==> 3/4 Validando importação e scripts no Godot 4 (headless)..." -ForegroundColor Cyan
Invoke-GodotChecked -GodotExe $godotConsole -Arguments @("--headless", "--path", $ProjectRoot, "--import", "--quit")

Write-Host "==> 4/4 Executando suíte de testes CLI (headless)..." -ForegroundColor Cyan
Invoke-GodotChecked -GodotExe $godotConsole -Arguments @("--headless", "--path", $ProjectRoot, "--script", "res://tests/run_tests.gd")

Write-Host "Todos os checks passaram com sucesso!" -ForegroundColor Green
