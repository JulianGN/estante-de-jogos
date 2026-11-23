param(
    [switch]$Install,
    [switch]$Release
)

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
        $match = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | Select-Object -First 1
        if ($match) {
            return $match.FullName
        }
    }
    throw "Ferramenta obrigatória não encontrada: $ExeName"
}

$godotConsole = Resolve-Tool -ExeName "godot_console" -CandidatePaths @(
    "$env:LOCALAPPDATA\Microsoft\WinGet\Links\godot_console.exe",
    "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine*\Godot_*_console.exe"
)

$androidSdk = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { "$env:LOCALAPPDATA\Android\Sdk" }
$aapt2 = Resolve-Tool -ExeName "aapt2" -CandidatePaths @(
    "$androidSdk\build-tools\*\aapt2.exe"
)
$adb = Resolve-Tool -ExeName "adb" -CandidatePaths @(
    "$androidSdk\platform-tools\adb.exe"
)

$buildsDir = Join-Path $ProjectRoot "builds\android"
New-Item -ItemType Directory -Force -Path $buildsDir | Out-Null

$apkName = if ($Release) { "estante-de-jogos-release.apk" } else { "estante-de-jogos-debug.apk" }
$apkPath = Join-Path $buildsDir $apkName
$exportFlag = if ($Release) { "--export-release" } else { "--export-debug" }

if (Test-Path $apkPath) {
    Remove-Item $apkPath -Force
}

Write-Host "==> 1/4 Atualizando recursos importados no Godot 4..." -ForegroundColor Cyan
& $godotConsole --headless --path $ProjectRoot --import --quit
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "==> 2/4 Exportando APK Android ($exportFlag)..." -ForegroundColor Cyan
$prevPref = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$exportOutput = & $godotConsole --headless --path $ProjectRoot $exportFlag "Android" $apkPath 2>&1 | ForEach-Object { $_.ToString() }
$exportExit = $LASTEXITCODE
$ErrorActionPreference = $prevPref
$exportOutput | ForEach-Object { Write-Host $_ }
if ($exportExit -ne 0) { exit $exportExit }

if (-not (Test-Path $apkPath) -or (Get-Item $apkPath).Length -le 0) {
    Write-Error "APK não foi gerado ou está vazio: $apkPath"
    exit 1
}

Write-Host "==> 3/4 Auditando APK com aapt2 (Mínima Permissão & Portrait)..." -ForegroundColor Cyan
$badging = & $aapt2 dump badging $apkPath
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$badging | Select-String -Pattern "^(package:|application-label:|native-code:)" | ForEach-Object { Write-Host $_.Line }

$permLines = & $aapt2 dump permissions $apkPath
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$permLines | ForEach-Object { Write-Host $_ }

$usesPerms = @()
foreach ($line in $permLines) {
    if ($line -match "uses-permission:\s*name='([^']+)'") {
        $usesPerms += $Matches[1]
    }
}

if ($Release) {
    if ($usesPerms.Count -gt 0) {
        Write-Error ("Violação do Princípio de Mínima Permissão em Release! Permissões encontradas: " + ($usesPerms -join ", "))
        exit 1
    }
    Write-Host "OK: 0 permissões no APK Release." -ForegroundColor Green
} else {
    $unexpected = $usesPerms | Where-Object { $_ -ne "android.permission.INTERNET" }
    if ($unexpected.Count -gt 0) {
        Write-Error ("Permissões inesperadas no APK Debug: " + ($unexpected -join ", "))
        exit 1
    }
    if ($usesPerms -contains "android.permission.INTERNET") {
        Write-Host "AVISO (esperado em Debug): template android_debug.apk do Godot injeta INTERNET para debugger remoto; em Release é 0 permissões." -ForegroundColor Yellow
    } else {
        Write-Host "OK: 0 permissões no APK Debug." -ForegroundColor Green
    }
}

$manifestTree = & $aapt2 dump xmltree $apkPath --file AndroidManifest.xml
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$portraitMatch = $manifestTree | Select-String -Pattern "screenOrientation.*=(?:0x)?1\b"
if (-not $portraitMatch) {
    Write-Error "screenOrientation Portrait (1) não encontrado no AndroidManifest.xml!"
    exit 1
}
Write-Host "OK: Orientação travada em Portrait (screenOrientation=1) confirmada." -ForegroundColor Green

$apkSizeMb = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
Write-Host "APK validado: $apkPath ($apkSizeMb MB)" -ForegroundColor Green

if ($Install) {
    Write-Host "==> 4/4 Instalando no dispositivo via adb..." -ForegroundColor Cyan
    $devicesOut = & $adb devices
    $online = $devicesOut | Select-String -Pattern "\tdevice$"
    if (-not $online) {
        Write-Warning "Nenhum dispositivo Android conectado com Depuração USB ativa."
        Write-Host "Conecte o aparelho via USB, ative a Depuração USB e execute: .\tools\build_android.ps1 -Install"
        exit 0
    }
    & $adb install -r $apkPath
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & $adb shell am start -n "com.juliangn.estantedejogos/com.godot.game.GodotApp"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    Write-Host "App instalado e iniciado no dispositivo!" -ForegroundColor Green
} else {
    Write-Host "==> 4/4 Instalação via adb omitida (use -Install para instalar no aparelho conectado)." -ForegroundColor DarkGray
}
