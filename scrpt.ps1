$DebugPreference = 'Continue'
$ErrorActionPreference = "Stop"

$conf = Import-PowerShellDataFile .\conf.psd1
Import-Module .\modules\GitsLogger\GitsLogger.psm1 -Force

Import-Module .\modules\Cobas\Cobas.psm1 -Force
Initialize-Cobas $conf.Cobas

Write-LogInfo ("Script {0} start" -f $conf.Name)

Import-CobasFiles
Show-Cobas
Export-CobasFiles
Start-ArchiveCobasFiles

Write-LogInfo ("Script {0} finish" -f $conf.Name)


