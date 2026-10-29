param(
 [ValidateSet('import','unit','regression','av','capture','record','audit')][string]$Mode='unit',
 [ValidateSet('1280x720','1920x1080')][string]$Resolution='1280x720'
)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$env:APPDATA=Join-Path $root '.local_test\v14_profile\Roaming'
$env:LOCALAPPDATA=Join-Path $root '.local_test\v14_profile\Local'
$env:WORDROGUE_TEST_PROFILE='1'
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,(Join-Path $root '.local_test\v14') | Out-Null
$engine='D:\godot\Godot_v4.7.2-stable_win64_console.exe'
switch($Mode){
 'import' { & $engine --headless --path $root --editor --import }
 'unit' { & $engine --headless --path $root --script res://tests/v14_models.gd }
 'regression' {
   & $engine --headless --path $root --script res://tests/spells.gd
   if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}
   & $engine --headless --path $root --script res://tests/smoke.gd
   if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}
   & $engine --headless --path $root --script res://tests/menu_quit.gd
 }
 'av' { & $engine --headless --path $root --script res://tests/v14_av.gd }
 'capture' { & $engine --path $root --resolution $Resolution --script res://tests/v14_av.gd }
 'record' { & $engine --path $root --resolution 1280x720 --write-movie (Join-Path $root '.local_test\v14\exploration_combat.ogv') --fixed-fps 30 --script res://tests/v14_av.gd -- --video }
 'audit' {
   foreach($file in @('project.godot','data\words.json','scripts\word_bank.gd','scripts\save_data.gd','assets\characters\word_mage.png','assets\enemies\ink_wraith.png','assets\enemies\marginalia.png','assets\enemies\librarian.png','assets\backgrounds\library_battle.png','assets\audio\bgm\normal_battle.ogg','assets\audio\bgm\boss_battle.ogg')){
     $before=(Get-FileHash -LiteralPath (Join-Path $root "backups\v13_before_v14_20261009_144914\$file")).Hash
     $after=(Get-FileHash -LiteralPath (Join-Path $root $file)).Hash
     Write-Output "$file : Unchanged=$($before -eq $after)"
     if($before -ne $after){throw "Protected file changed: $file"}
   }
   exit 0
 }
}
exit $LASTEXITCODE
