param(
 [ValidateSet('import','data','unit','regression','av','capture','record','audit')][string]$Mode='unit',
 [ValidateSet('1280x720','1920x1080')][string]$Resolution='1280x720'
)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$env:APPDATA=Join-Path $root '.local_test\v16_profile\Roaming'
$env:LOCALAPPDATA=Join-Path $root '.local_test\v16_profile\Local'
$env:WORDROGUE_TEST_PROFILE='1'
$env:PYTHONIOENCODING='utf-8'
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,(Join-Path $root '.local_test\v16') | Out-Null
$engine='D:\godot\Godot_v4.7.2-stable_win64_console.exe'
function Run-Godot([string[]]$arguments,[string]$label) {
 $log=Join-Path $root ('.local_test\v16\'+$label+'.log')
 $previousPreference=$ErrorActionPreference
 try {
   $ErrorActionPreference='Continue'
   & $engine @arguments 2>&1 | Tee-Object -FilePath $log | Write-Output
   $resultCode=$LASTEXITCODE
 } finally { $ErrorActionPreference=$previousPreference }
 if($resultCode -ne 0){throw "Godot failed: $label ($resultCode)"}
 if((Get-Content -LiteralPath $log -Raw) -match 'SCRIPT ERROR|ERROR:'){throw "Godot runtime error: $label"}
}
switch($Mode){
 'import' { Run-Godot @('--headless','--path',$root,'--editor','--import') 'import' }
 'data' {
   & 'C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' (Join-Path $root 'tools\validate_cet4_core.py')
   if($LASTEXITCODE -ne 0){throw 'Word data validation failed'}
 }
 'unit' { Run-Godot @('--headless','--path',$root,'--script','res://tests/v16_models.gd') 'models' }
 'regression' {
   foreach($script in @('spells','smoke','artwork','v12_final','v13_spells','v14_models','v14_av','v15_models','v15_av','menu_quit')) {
     Run-Godot @('--headless','--path',$root,'--script',("res://tests/"+$script+'.gd')) $script
   }
 }
 'av' { Run-Godot @('--headless','--path',$root,'--script','res://tests/v16_av.gd') 'headless' }
 'capture' { Run-Godot @('--path',$root,'--disable-vsync','--max-fps','120','--resolution',$Resolution,'--script','res://tests/v16_av.gd') ('graphics_'+$Resolution) }
 'record' { Run-Godot @('--path',$root,'--disable-vsync','--resolution','1280x720','--write-movie',(Join-Path $root '.local_test\v16\ecosystem_events.ogv'),'--fixed-fps','30','--script','res://tests/v16_av.gd','--','--video') 'video' }
 'audit' {
   foreach($file in @('project.godot','scenes\main.tscn','data\words.json','scripts\save_data.gd','scripts\reward_catalog.gd','scripts\audio_bus.gd','assets\characters\word_mage.png','assets\enemies\ink_wraith.png','assets\enemies\marginalia.png','assets\enemies\librarian.png','assets\backgrounds\library_battle.png','assets\audio\bgm\normal_battle.ogg','assets\audio\bgm\boss_battle.ogg')) {
     $old=(Get-FileHash -LiteralPath (Join-Path $root "backups\v15_before_v16_20261009_191053\$file")).Hash
     $new=(Get-FileHash -LiteralPath (Join-Path $root $file)).Hash
     Write-Output "$file : Unchanged=$($old -eq $new)"
     if($old -ne $new){throw "Protected file changed: $file"}
   }
 }
}
