param(
 [string]$Godot='D:\godot\Godot_v4.7.2-stable_win64_console.exe',
 [string]$Python='C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe',
 [string]$Stage=''
)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
if([string]::IsNullOrEmpty($Stage)){
 $Stage='.local_test\release\staging_'+(Get-Date -Format 'yyyyMMdd_HHmmss')
}
$stageRoot=Join-Path $projectRoot $Stage
if(-not(Test-Path -LiteralPath (Join-Path $stageRoot 'project.godot'))){
 & $Python (Join-Path $PSScriptRoot 'prepare_release.py') --stage $Stage
 if($LASTEXITCODE -ne 0){throw 'Release staging failed'}
}
$template=Join-Path $projectRoot '.local_test\release\cache\windows_release_x86_64.exe'
if(-not(Test-Path -LiteralPath $template)){throw 'Matching official release template missing; run fetch_release_assets.py first.'}
$outputRoot=Join-Path $projectRoot 'releases\windows'
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null
# Isolated profile: never run build validation against the real learning save.
$env:APPDATA=Join-Path $projectRoot '.local_test\release\build_profile'
$env:LOCALAPPDATA=Join-Path $projectRoot '.local_test\release\build_local'
& $Godot --headless --path $stageRoot --editor --import
if($LASTEXITCODE -ne 0){throw 'Godot import failed'}
& $Godot --headless --path $stageRoot --export-release 'Windows Release' (Join-Path $outputRoot 'WordRogue.exe')
if($LASTEXITCODE -ne 0){throw 'Windows export failed'}
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs\RELEASE_PLAY_README.md') -Destination (Join-Path $outputRoot 'README.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets\audio\licenses\V1.8_LICENSES.md') -Destination (Join-Path $outputRoot 'AUDIO_LICENSES.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets\fonts\OFL.txt') -Destination (Join-Path $outputRoot 'FONT_LICENSE.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets\licenses\LICENSE.txt') -Destination (Join-Path $outputRoot 'GODOT_LICENSE.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets\licenses\COPYRIGHT.txt') -Destination (Join-Path $outputRoot 'GODOT_THIRD_PARTY.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'data\licenses\ECDICT_LICENSE.txt') -Destination (Join-Path $outputRoot 'WORD_BANK_LICENSE.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'data\licenses\README.md') -Destination (Join-Path $outputRoot 'WORD_BANK_CREDITS.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs\ASSET_CREDITS.md') -Destination (Join-Path $outputRoot 'ASSET_CREDITS.md')
foreach($license in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'assets\fonts') -Filter '*_OFL.txt'){
 Copy-Item -LiteralPath $license.FullName -Destination (Join-Path $outputRoot $license.Name)
}
$zip=Join-Path $projectRoot 'releases\WordRogue-Windows.zip'
& $Python -c 'import pathlib,zipfile,sys; p=pathlib.Path(sys.argv[1]); z=zipfile.ZipFile(sys.argv[2],"w",zipfile.ZIP_DEFLATED,compresslevel=9); [z.write(f,f.name) for f in p.iterdir() if f.is_file()]; z.close()' $outputRoot $zip
if($LASTEXITCODE -ne 0){throw 'Release ZIP failed'}
Get-ChildItem -LiteralPath $outputRoot -File | Select-Object Name,Length
Get-Item -LiteralPath $zip | Select-Object Name,Length
