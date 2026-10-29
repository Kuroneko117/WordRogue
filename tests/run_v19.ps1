param([ValidateSet('import','models','relics','smoke','ui')][string]$Mode='ui')
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$env:APPDATA=Join-Path $projectRoot '.local_test\v19_profile\Roaming'
$env:LOCALAPPDATA=Join-Path $projectRoot '.local_test\v19_profile\Local'
$env:WORDROGUE_TEST_PROFILE='1'
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,(Join-Path $projectRoot '.local_test\v19') | Out-Null
$godotArgs=@('--path',$projectRoot)
switch($Mode) {
 'import' {$godotArgs += @('--headless','--editor','--import')}
 'models' {$godotArgs += @('--headless','--script','res://tests/v19_models.gd')}
 'relics' {$godotArgs += @('--headless','--script','res://tests/v19_relics.gd')}
 'smoke' {$godotArgs += @('--headless','--script','res://tests/smoke.gd')}
 'ui' {$godotArgs += @('--disable-vsync','--max-fps','120','--resolution','1280x720','--script','res://tests/v19_ui.gd')}
}
$testLog=Join-Path $projectRoot ('.local_test\v19\'+$Mode+'.log')
$ErrorActionPreference='Continue'
& 'D:\godot\Godot_v4.7.2-stable_win64_console.exe' @godotArgs 2>&1 | Tee-Object -FilePath $testLog | Write-Output
$exitCode=$LASTEXITCODE
$ErrorActionPreference='Stop'
if($exitCode -ne 0 -or (Get-Content -LiteralPath $testLog -Raw) -match 'SCRIPT ERROR|ERROR:'){throw "V19 failed: $Mode ($exitCode)"}
