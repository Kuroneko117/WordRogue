$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$downloadRoot = Join-Path $projectRoot '.local_test\audio_sources'
New-Item -ItemType Directory -Force -Path $downloadRoot | Out-Null
$downloads = @{
    'rpg.zip' = 'https://kenney.nl/media/pages/assets/rpg-audio/8e99002d76-1677590336/kenney_rpg-audio.zip'
    'interface.zip' = 'https://kenney.nl/media/pages/assets/interface-sounds/fa43c1dd4d-1677589452/kenney_interface-sounds.zip'
    'jingles.zip' = 'https://kenney.nl/media/pages/assets/music-jingles/f37e530b9e-1677590399/kenney_music-jingles.zip'
    'normal_battle.ogg' = 'https://opengameart.org/sites/default/files/whispers_in_the_fog.ogg'
    'boss_battle.ogg' = 'https://opengameart.org/sites/default/files/dark_place.ogg'
}
for($index=1; $index -le 7; $index++) {
    $downloads["magical_$index.ogg"] = "https://opengameart.org/sites/default/files/magical_$index.ogg"
}
foreach($name in $downloads.Keys) {
    $target = Join-Path $downloadRoot $name
    if(-not (Test-Path -LiteralPath $target)) {
        Invoke-WebRequest -UseBasicParsing -Uri $downloads[$name] -OutFile $target
    }
    Write-Output "$name : $((Get-Item -LiteralPath $target).Length) bytes"
}
foreach($package in @('rpg','interface','jingles')) {
    $target = Join-Path $downloadRoot $package
    if(-not (Test-Path -LiteralPath $target)) {
        Expand-Archive -LiteralPath (Join-Path $downloadRoot "$package.zip") -DestinationPath $target
    }
}
Get-ChildItem -LiteralPath $downloadRoot -Recurse -File | Where-Object Extension -In '.ogg','.wav','.txt' | Select-Object FullName,Length
