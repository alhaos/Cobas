Set-StrictMode -Version 'Latest'

class Cobas {
    
    [string]$DirecoryInput
    [string]$DirecoryArch
    [string]$DirecoryOutput
    [hashtable]$TestNameDict
    [CobasFile[]]$Files

}

class CobasFile {
    [string]$Filename
    [string]$OutFilename
    [CobasResult[]]$Results
}

class CobasResult {
    [string]$Accession
    [string]$TestName
    [string]$TestResult

    Clear() {
        $this.Accession = ""
        $this.TestName = ""
        $this.TestResult = ""
    }
}

enum ReadState {
    Start
    MSH
    PID
    SAC
    ORC
    OBR
    OBX
    TCD
    SkipResult
}

$Cobas = [Cobas]::new()
function Initialize-Cobas {
    param (
        [hashtable]$Conf
    )

    #Write-Debug ($Conf | ConvertTo-Json)

    $Cobas.DirecoryInput = $conf.Directories.Input
    $Cobas.DirecoryArch = $conf.Directories.Arch
    $Cobas.DirecoryOutput = $conf.Directories.Output
    $Cobas.TestNameDict = $conf.TestNameDict
}
function Import-CobasFiles {
    
    Write-LogInfo "Import-CobasFiles {"
    
    :file foreach ($file in Get-ChildItem -File $Cobas.DirecoryInput) {
    
        $readState = [ReadState]::Start
        $bufferFile = [CobasFile]::new()
        $bufferResult = [CobasResult]::new()
        Write-LogInfo "`tFound file $($file.name) {"
    
        foreach ($line in Get-Content $file) {
            $sectionName = $line.Substring(0, 3)
            switch ($readState) {
                ([ReadState]::Start) {
                    if ($sectionName -eq "MSH") {
                        $readState = [ReadState]::MSH
                        break
                    }
                    else {
                        Write-LogError "Unexpected section instead MSH in $line at $file"
                        $bufferFile.Filename = $file.FullName                          
                        $Cobas.Files += , $bufferFile
                        continue file
                    }
                }
                ([ReadState]::MSH) {
                    if ($sectionName -eq "PID") {
                        $readState = [ReadState]::PID
                        break
                    }
                    else {
                        Write-LogError "Unexpected section instead PID in $line at $file"
                        $bufferFile.Filename = $file.FullName                          
                        $Cobas.Files += , $bufferFile
                        continue file
                    }
                }
                ([ReadState]::PID) {
                    if ($sectionName -eq "SAC") {
                        $readState = [ReadState]::SAC
                        break
                    }
                    else {
                        Write-LogError "Unexpected section instead SAC in $line at $file"
                        $bufferFile.Filename = $file.FullName                          
                        $Cobas.Files += , $bufferFile
                        continue file
                    }
                }
                ([ReadState]::SAC) {
                    if ($sectionName -eq "ORC") {
                        $readState = [ReadState]::ORC
                        break
                    }
                    else {
                        Write-LogError "Unexpected section instead ORC in $line at $file"
                        $bufferFile.Filename = $file.FullName                          
                        $Cobas.Files += , $bufferFile
                        continue file
                    }
                }
                ([ReadState]::ORC) {
                    if ($sectionName -eq "OBR") {
                        $Accession = $line.Split("|")[2]
                        if ($Accession -match "^\d{10}$") {
                            $bufferResult.Accession = $Accession
                        }
                        Else {
                            $bufferResult.Clear()
                            [ReadState]::SkipResult
                            break
                        }
                        $readState = [ReadState]::OBR
                        break
                    } 
                    else {
                        Write-LogError "Unexpected section instead OBR in $line at $file"
                        $bufferFile.Filename = $file.FullName                          
                        $Cobas.Files += , $bufferFile
                        continue file
                    }
                }
                ([ReadState]::OBR) {
                    if ( $sectionName -eq "OBX") {
                        $testName, $testResult = $line.Split("|")[3, 5]
                        $bufferResult.TestName = $Cobas.TestNameDict.Keys -contains $testName ? $Cobas.TestNameDict.$testName : $testName
                        $bufferResult.TestResult = $testResult
                        $bufferFile.Results += , $bufferResult
                        $readState = [ReadState]::OBX
                        break
                    }
                    else {
                        Write-LogError "Unexpected section instead OBX in $line at $file"
                        $bufferFile.Filename = $file.FullName                          
                        $Cobas.Files += , $bufferFile
                        continue file
                    }
                }
                { [ReadState]::OBX } {
                    switch ($sectionName) {
                        "OBX" {
                            $testName, $testResult = $line.Split("|")[3, 5]
                            $bufferResult.TestName = $Cobas.TestNameDict.Keys -contains $testName ? $Cobas.TestNameDict.$testName : $testName
                            $bufferResult.TestResult = $testResult
                            $bufferFile.Results += , $bufferResult
                        }
                        "ORC" {
                            $readState = [ReadState]::ORC
                        }
                        "TCD" {
                            $bufferFile.Filename = $file.FullName
                            $bufferFile.OutFilename = Join-Path $Cobas.DirecoryOutput $file.Name
                            $Cobas.Files += , $bufferFile
                            continue file
                        }
                        Default {
                            Write-LogError "Unexpected section instead OBX, OBC, TCD in $line at $file"
                            $bufferFile.Filename = $file.FullName                          
                            $Cobas.Files += , $bufferFile
                            continue file
                        }
                    }
                }
            }
        }
        Write-LogInfo "}"
    }
    Write-LogInfo "}"
}

function Show-Cobas {
    write-host ($Cobas | ConvertTo-Json -Depth 5)   
}
function Export-CobasFiles {
    foreach ($cobasFile in $Cobas.Files) {
        if ($cobasFile.Results) {
            Write-LogInfo "export file $($cobasFile.OutFilename)"
            (($cobasFile.Results | ConvertTo-Csv -UseQuotes AsNeeded) -join ([environment]::NewLine)) | Set-Content $cobasFile.OutFilename
        }
        else {
            Write-LogInfo "empty file $($cobasFile.OutFilename) skipped"
        }
    }
}
function Start-ArchiveCobasFiles {
    foreach ($cobasFile in $Cobas.Files) {
        Write-LogInfo "arhive file $($Cobas.DirecoryArch)"
        Move-Item $cobasFile.Filename $Cobas.DirecoryArch
    }
}