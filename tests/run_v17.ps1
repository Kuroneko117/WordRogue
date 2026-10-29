param(
 [ValidateSet('import','av','capture','audit')][string]$Mode='av',
 [ValidateSet('1280x720','1920x1080')][string]$Resolution='1280x720'
)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$env:APPDATA=Join-Path $root '.local_test\v17_profile\Roaming'
$env:LOCALAPPDATA=Join-Path $root '.local_test\v17_profile\Local'
$env:WORDROGUE_TEST_PROFILE='1'
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,(Join-Path $root '.local_test\v17') | Out-Null
$engine='D:\godot\Godot_v4.7.2-stable_win64_console.exe'
if($Mode -eq 'audit') {
 $backup=Join-Path $root 'backups\v16_before_v17_20261009_223228'
 $paths=@('project.godot','scenes\main.tscn','data\words.json','data\cet4_core_1500.json','scripts\game_state.gd','scripts\word_bank.gd','scripts\save_data.gd','scripts\enemy_brain.gd','scripts\enemy_definitions.gd','scripts\difficulty_config.gd','scripts\momentum_controller.gd','scripts\event_session.gd','scripts\route_state.gd','scripts\reward_catalog.gd','scripts\review_session.gd','scripts\ui\pause_menu.gd')
 $paths += Get-ChildItem -LiteralPath (Join-Path $backup 'assets') -Recurse -File | Where-Object {$_.Extension -in @('.png','.ogg','.wav')} | ForEach-Object {$_.FullName.Substring($backup.Length+1)}
 foreach($path in $paths) {
   $old=(Get-FileHash -LiteralPath (Join-Path $backup $path)).Hash
   $new=(Get-FileHash -LiteralPath (Join-Path $root $path)).Hash
   if($old -ne $new){throw "Protected file changed: $path"}
 }
 Write-Output "V17 AUDIT PASS: $($paths.Count) protected files unchanged"
 exit
}
$arguments=@('--path',$root)
switch($Mode) {
 'import' {$arguments += @('--headless','--editor','--import')}
 'av' {$arguments += @('--headless','--script','res://tests/v17_presentation.gd')}
 'capture' {$arguments += @('--disable-vsync','--max-fps','120','--resolution',$Resolution,'--script','res://tests/v17_presentation.gd')}
}
$log=Join-Path $root ('.local_test\v17\'+$Mode+'_'+$Resolution+'.log')
$ErrorActionPreference='Continue'
& $engine @arguments 2>&1 | Tee-Object -FilePath $log | Write-Output
$code=$LASTEXITCODE
$ErrorActionPreference='Stop'
if($code -ne 0 -or (Get-Content -LiteralPath $log -Raw) -match 'SCRIPT ERROR|ERROR:'){throw "Godot failed: $Mode ($code)"}
