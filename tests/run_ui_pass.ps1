param([switch]$Models)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$env:APPDATA=Join-Path $projectRoot '.local_test\ui_pass_profile\Roaming'
$env:LOCALAPPDATA=Join-Path $projectRoot '.local_test\ui_pass_profile\Local'
$env:WORDROGUE_TEST_PROFILE='1'
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,(Join-Path $projectRoot '.local_test\ui_pass') | Out-Null
$godotArgs=@('--path',$projectRoot)
if($Models){$godotArgs+=@('--headless','--script','res://tests/v19_models.gd')}
else{$godotArgs+=@('--disable-vsync','--max-fps','120','--resolution','1280x720','--script','res://tests/ui_visual_pass.gd')}
$log=Join-Path $projectRoot ('.local_test\ui_pass\'+$(if($Models){'models'}else{'ui_final'})+'.log')
& 'D:\godot\Godot_v4.7.2-stable_win64_console.exe' @godotArgs 2>&1 | Tee-Object -FilePath $log
$code=$LASTEXITCODE
if($code -ne 0 -or (Get-Content -LiteralPath $log -Raw) -match 'SCRIPT ERROR|ERROR:'){throw "UI pass gate failed: exit $code; see $log"}
