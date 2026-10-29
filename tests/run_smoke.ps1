param([string]$Godot = 'D:\godot\Godot_v4.7.2-stable_win64_console.exe')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$oldAppData = $env:APPDATA
$oldLocalAppData = $env:LOCALAPPDATA
$oldTestFlag = $env:WORDROGUE_TEST_PROFILE
try {
    $env:APPDATA = Join-Path $projectRoot '.local_test\automated\Roaming'
    $env:LOCALAPPDATA = Join-Path $projectRoot '.local_test\automated\Local'
    $env:WORDROGUE_TEST_PROFILE = '1'
    New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
    & $Godot --headless --path $projectRoot --script res://tests/smoke.gd
    $resultCode = $LASTEXITCODE
    if ($resultCode -eq 0) {
        & $Godot --headless --path $projectRoot --script res://tests/menu_quit.gd
        $resultCode = $LASTEXITCODE
    }
} finally {
    $env:APPDATA = $oldAppData
    $env:LOCALAPPDATA = $oldLocalAppData
    $env:WORDROGUE_TEST_PROFILE = $oldTestFlag
}
exit $resultCode
