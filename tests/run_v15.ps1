param(
 [ValidateSet('import','unit','regression','av','capture','record','audit')][string]$Mode='unit',
 [ValidateSet('1280x720','1920x1080')][string]$Resolution='1280x720'
)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$env:APPDATA=Join-Path $root '.local_test\v15_profile\Roaming'
$env:LOCALAPPDATA=Join-Path $root '.local_test\v15_profile\Local'
$env:WORDROGUE_TEST_PROFILE='1'
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,(Join-Path $root '.local_test\v15') | Out-Null
$engine='D:\godot\Godot_v4.7.2-stable_win64_console.exe'
function Run-Godot([string[]]$arguments,[string]$label) {
 $log=Join-Path $root ('.local_test\v15\'+$label+'.log')
 & $engine @arguments 2>&1 | Tee-Object -FilePath $log | Write-Output
 $code=$LASTEXITCODE
 if($code -ne 0){throw "Godot failed ($code): $label"}
 $output=Get-Content -LiteralPath $log -Raw
 if($output -match 'SCRIPT ERROR|ERROR:'){throw "Godot reported runtime errors: $label"}
}
switch($Mode){
 'import' { Run-Godot @('--headless','--path',$root,'--editor','--import') 'import' }
 'unit' { Run-Godot @('--headless','--path',$root,'--script','res://tests/v15_models.gd') 'models' }
 'regression' {
   Run-Godot @('--headless','--path',$root,'--script','res://tests/spells.gd') 'legacy_spells'
   Run-Godot @('--headless','--path',$root,'--script','res://tests/smoke.gd') 'legacy_smoke'
   Run-Godot @('--headless','--path',$root,'--script','res://tests/v14_models.gd') 'v14_models'
   Run-Godot @('--headless','--path',$root,'--script','res://tests/v14_av.gd') 'v14_av'
   Run-Godot @('--headless','--path',$root,'--script','res://tests/menu_quit.gd') 'menu_quit'
 }
 'av' { Run-Godot @('--headless','--path',$root,'--script','res://tests/v15_av.gd') 'headless' }
 'capture' { Run-Godot @('--path',$root,'--resolution',$Resolution,'--script','res://tests/v15_av.gd') ('graphics_'+$Resolution) }
 'record' { Run-Godot @('--path',$root,'--resolution','1280x720','--write-movie',(Join-Path $root '.local_test\v15\map_build_audio.ogv'),'--fixed-fps','30','--script','res://tests/v15_av.gd','--','--video') 'video' }
 'audit' {
   foreach($file in @('project.godot','data\words.json','scripts\word_bank.gd','scripts\save_data.gd','assets\characters\word_mage.png','assets\enemies\ink_wraith.png','assets\enemies\marginalia.png','assets\enemies\librarian.png','assets\backgrounds\library_battle.png','assets\audio\bgm\normal_battle.ogg','assets\audio\bgm\boss_battle.ogg')){
     $before=(Get-FileHash -LiteralPath (Join-Path $root "backups\v14_before_v15_20261009_171328\$file")).Hash
     $after=(Get-FileHash -LiteralPath (Join-Path $root $file)).Hash
     Write-Output "$file : Unchanged=$($before -eq $after)"
     if($before -ne $after){throw "Protected file changed: $file"}
   }
 }
}
