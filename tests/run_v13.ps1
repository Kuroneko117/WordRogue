param(
 [ValidateSet('import','unit','smoke','av','capture','record','prepare','audit')][string]$Mode='unit',
 [ValidateSet('1280x720','1920x1080')][string]$Resolution='1280x720'
)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$env:APPDATA=Join-Path $root '.local_test\v13_profile\Roaming'
$env:LOCALAPPDATA=Join-Path $root '.local_test\v13_profile\Local'
$env:WORDROGUE_TEST_PROFILE='1'
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,(Join-Path $root '.local_test\v13_cn') | Out-Null
$engine='D:\godot\Godot_v4.7.2-stable_win64_console.exe'
switch($Mode){
 'import' { & $engine --headless --path $root --editor --import }
 'unit' { & $engine --headless --path $root --script res://tests/spells.gd }
 'prepare' { & $engine --headless --path $root --script res://tests/prepare_v13_audio.gd }
 'smoke' {
   & $engine --headless --path $root --script res://tests/smoke.gd
   if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}
   & $engine --headless --path $root --script res://tests/menu_quit.gd
 }
 'av' { & $engine --headless --path $root --script res://tests/v13_spells.gd }
 'capture' { & $engine --path $root --resolution $Resolution --script res://tests/v13_spells.gd }
 'record' { & $engine --path $root --resolution 1280x720 --write-movie (Join-Path $root '.local_test\v13_cn\spells_demo.ogv') --fixed-fps 30 --script res://tests/v13_spells.gd -- --video }
 'audit' {
   foreach($file in @('data\words.json','scripts\word_bank.gd','scripts\save_data.gd','assets\characters\word_mage.png','assets\enemies\ink_wraith.png','assets\enemies\marginalia.png','assets\enemies\librarian.png','assets\backgrounds\library_battle.png','assets\audio\bgm\normal_battle.ogg','assets\audio\bgm\boss_battle.ogg')){
     $before=(Get-FileHash -LiteralPath (Join-Path $root "backups\v12_before_v13_20261009\$file")).Hash
     $after=(Get-FileHash -LiteralPath (Join-Path $root $file)).Hash
     Write-Output "$file : Unchanged=$($before -eq $after)"
     if($before -ne $after){throw "Protected file changed: $file"}
   }
   $oldSfx=Join-Path $root 'backups\v12_before_v13_20261009\assets\audio\sfx'
   foreach($sample in Get-ChildItem -LiteralPath $oldSfx -File -Filter '*.wav'){
     $current=Join-Path $root ('assets\audio\sfx\'+$sample.Name)
     if((Get-FileHash -LiteralPath $sample.FullName).Hash -ne (Get-FileHash -LiteralPath $current).Hash){throw "Original audio overwritten: $($sample.Name)"}
   }
   Write-Output 'All original V1.2 SFX preserved.'
   exit 0
 }
}
exit $LASTEXITCODE
