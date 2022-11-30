<#
.SYNOPSIS
    A short one-line action-based description, e.g. 'Tests if a function is valid'
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>

using assembly .\resources\NLog\NLog.dll
using module .\resources\NLog\NLog.psm1
using module .\resources\tmp_\tmp_.psm1

Set-StrictMode -Version "Latest"
$ErrorActionPreference = 'Stop'
$DebugPreference = 'Continue'
$Conf = Import-PowerShellDataFile .\conf.psd1

$logger = [NLogBuilder]::GetLogger($Conf.NLogConfig)

$logger.Info("Start {0}", $Conf.Name)
try {
    $tmp_ = [tmp_]::new($conf.tmp_, $logger)
    $tmp_.LoadFiles()
    $tmp_.LoadResults()
    $tmp_.ReportResults()
}
catch {

    throw $_
    
}
finally {
    [System.IO.file]::WriteAllText($Conf.tmp_.Numbering,  $tmp_.Numbering)
    $logger.Info("End {0}", $Conf.Name)    
}







