param(
    [ValidateSet('prepare','import','smoke','artwork','av','capture','audit')][string]$Mode='av',
    [ValidateSet('1280x720','1920x1080')][string]$Resolution='1280x720'
)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$env:APPDATA=Join-Path $projectRoot '.local_test\v12_profile\Roaming'
$env:LOCALAPPDATA=Join-Path $projectRoot '.local_test\v12_profile\Local'
$env:WORDROGUE_TEST_PROFILE='1'
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA | Out-Null
$godotPath='D:\godot\Godot_v4.7.2-stable_win64_console.exe'
switch($Mode) {
    'prepare' { & $godotPath --headless --path $projectRoot --script res://tests/prepare_audio.gd }
    'import' { & $godotPath --headless --path $projectRoot --editor --import }
    'smoke' {
        & $godotPath --headless --path $projectRoot --script res://tests/smoke.gd
        if($LASTEXITCODE -ne 0){exit $LASTEXITCODE}
        & $godotPath --headless --path $projectRoot --script res://tests/menu_quit.gd
    }
    'av' { & $godotPath --headless --path $projectRoot --script res://tests/v12_final.gd }
    'artwork' { & $godotPath --headless --path $projectRoot --script res://tests/artwork.gd }
    'capture' { & $godotPath --path $projectRoot --resolution $Resolution --script res://tests/v12_final.gd }
    'audit' {
        foreach($file in @('data\words.json','scripts\game_state.gd','scripts\word_bank.gd','scripts\save_data.gd','assets\characters\word_mage.png','assets\enemies\ink_wraith.png','assets\enemies\marginalia.png','assets\enemies\librarian.png','assets\backgrounds\library_battle.png')) {
            $current=(Get-FileHash -LiteralPath (Join-Path $projectRoot $file)).Hash
            $original=(Get-FileHash -LiteralPath (Join-Path $projectRoot "backups\v12_stage1_before_final_20261009\$file")).Hash
            Write-Output "$file : Unchanged=$($current -eq $original)"
            if($current -ne $original){throw "Protected file changed: $file"}
        }
        Get-ChildItem -LiteralPath (Join-Path $projectRoot 'assets\audio') -Recurse -File | Where-Object Extension -In '.wav','.ogg','.json' | Select-Object FullName,Length | Format-Table -AutoSize | Out-String | Write-Output
        exit 0
    }
}
exit $LASTEXITCODE
