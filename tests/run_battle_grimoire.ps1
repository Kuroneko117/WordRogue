param([switch]$Pilot)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$env:APPDATA=Join-Path $projectRoot '.local_test\grimoire_profile\Roaming'
$env:LOCALAPPDATA=Join-Path $projectRoot '.local_test\grimoire_profile\Local'
$env:WORDROGUE_TEST_PROFILE='1'
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,(Join-Path $projectRoot '.local_test\battle_grimoire') | Out-Null
$godotArgs=@('--path',$projectRoot,'--disable-vsync','--max-fps','120','--resolution','1280x720','--script','res://tests/battle_grimoire_capture.gd')
if($Pilot){$godotArgs+=@('--','--pilot')}
$log=Join-Path $projectRoot ('.local_test\battle_grimoire\'+$(if($Pilot){'pilot'}else{'final'})+'.log')
& 'D:\godot\Godot_v4.7.2-stable_win64_console.exe' @godotArgs *> $log
$result=$LASTEXITCODE
Get-Content -LiteralPath $log -Tail 12
if($result -ne 0 -or (Get-Content -LiteralPath $log -Raw) -match 'SCRIPT ERROR|ERROR:'){throw "Battle UI gate failed: $result; $log"}
