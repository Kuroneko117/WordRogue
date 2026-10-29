$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$env:APPDATA=Join-Path $root '.local_test\v17_stage2_profile\Roaming'
$env:LOCALAPPDATA=Join-Path $root '.local_test\v17_stage2_profile\Local'
$env:WORDROGUE_TEST_PROFILE='1'
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,(Join-Path $root '.local_test\v17_stage2') | Out-Null
$log=Join-Path $root '.local_test\v17_stage2\graphics.log'
$ErrorActionPreference='Continue'
& 'D:\godot\Godot_v4.7.2-stable_win64_console.exe' --path $root --disable-vsync --max-fps 120 --resolution 1280x720 --script res://tests/v17_stage2.gd 2>&1 | Tee-Object -FilePath $log | Write-Output
$code=$LASTEXITCODE
$ErrorActionPreference='Stop'
if($code -ne 0 -or (Get-Content -LiteralPath $log -Raw) -match 'SCRIPT ERROR|ERROR:'){throw "Stage2 failed ($code)"}
