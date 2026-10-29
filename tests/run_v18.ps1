param([ValidateSet('import','av','smoke')][string]$Mode='av')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$env:APPDATA=Join-Path $root '.local_test\v18_profile\Roaming'
$env:LOCALAPPDATA=Join-Path $root '.local_test\v18_profile\Local'
$env:WORDROGUE_TEST_PROFILE='1'
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,(Join-Path $root '.local_test\v18') | Out-Null
$arguments=@('--path',$root)
switch($Mode) {
 'import' {$arguments += @('--headless','--editor','--import')}
 'av' {$arguments += @('--disable-vsync','--max-fps','120','--resolution','1280x720','--script','res://tests/v18_av.gd')}
 'smoke' {$arguments += @('--headless','--script','res://tests/smoke.gd')}
}
$log=Join-Path $root ('.local_test\v18\'+$Mode+'.log')
$ErrorActionPreference='Continue'
& 'D:\godot\Godot_v4.7.2-stable_win64_console.exe' @arguments 2>&1 | Tee-Object -FilePath $log | Write-Output
$code=$LASTEXITCODE
$ErrorActionPreference='Stop'
if($code -ne 0 -or (Get-Content -LiteralPath $log -Raw) -match 'SCRIPT ERROR|ERROR:'){throw "V18 failed: $Mode ($code)"}
