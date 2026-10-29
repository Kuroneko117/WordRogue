$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$folder=Join-Path $root '.local_test\v13_audio_sources'
New-Item -ItemType Directory -Force -Path $folder | Out-Null
$links=@{
 'rpg'='https://opengameart.org/sites/default/files/80-CC0-RPG-SFX_0.zip'
 'swishes'='https://opengameart.org/sites/default/files/swishes.zip'
}
foreach($name in $links.Keys){
 $zip=Join-Path $folder "$name.zip"
 if(-not(Test-Path -LiteralPath $zip)){Invoke-WebRequest -UseBasicParsing -Uri $links[$name] -OutFile $zip}
 $destination=Join-Path $folder $name
 if(-not(Test-Path -LiteralPath $destination)){Expand-Archive -LiteralPath $zip -DestinationPath $destination}
}
Get-ChildItem -LiteralPath $folder -Recurse -File | Select-Object FullName,Length | Format-Table -AutoSize | Out-String | Write-Output
