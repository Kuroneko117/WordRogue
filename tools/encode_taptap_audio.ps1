param([Parameter(Mandatory=$true)][string]$InputWav,[Parameter(Mandatory=$true)][string]$OutputM4a)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null=[Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime]
$null=[Windows.Storage.StorageFolder,Windows.Storage,ContentType=WindowsRuntime]
$null=[Windows.Media.Transcoding.MediaTranscoder,Windows.Media,ContentType=WindowsRuntime]
$null=[Windows.Media.MediaProperties.MediaEncodingProfile,Windows.Media,ContentType=WindowsRuntime]

function Await-Operation($Operation,[Type]$ResultType){
 $method=[System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {$_.Name -eq 'AsTask' -and $_.IsGenericMethodDefinition -and $_.GetGenericArguments().Length -eq 1 -and $_.GetParameters().Length -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'} | Select-Object -First 1
 $task=$method.MakeGenericMethod($ResultType).Invoke($null,@($Operation))
 return $task.GetAwaiter().GetResult()
}
function Await-Progress($Operation){
 $method=[System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {$_.Name -eq 'AsTask' -and $_.IsGenericMethodDefinition -and $_.GetGenericArguments().Length -eq 1 -and $_.GetParameters().Length -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncActionWithProgress`1'} | Select-Object -First 1
 $task=$method.MakeGenericMethod([double]).Invoke($null,@($Operation))
 $task.GetAwaiter().GetResult() | Out-Null
}
$inputFile=Await-Operation ([Windows.Storage.StorageFile]::GetFileFromPathAsync($InputWav)) ([Windows.Storage.StorageFile])
$folder=Await-Operation ([Windows.Storage.StorageFolder]::GetFolderFromPathAsync((Split-Path -Parent $OutputM4a))) ([Windows.Storage.StorageFolder])
$outputFile=Await-Operation ($folder.CreateFileAsync((Split-Path -Leaf $OutputM4a),[Windows.Storage.CreationCollisionOption]::ReplaceExisting)) ([Windows.Storage.StorageFile])
$profile=[Windows.Media.MediaProperties.MediaEncodingProfile]::CreateM4a([Windows.Media.MediaProperties.AudioEncodingQuality]::High)
$transcoder=New-Object Windows.Media.Transcoding.MediaTranscoder
$result=Await-Operation ($transcoder.PrepareFileTranscodeAsync($inputFile,$outputFile,$profile)) ([Windows.Media.Transcoding.PrepareTranscodeResult])
if(-not $result.CanTranscode){throw ('Windows audio transcode unavailable: '+$result.FailureReason)}
Await-Progress ($result.TranscodeAsync())
Write-Output ('Native Windows AAC ready: '+$OutputM4a)
