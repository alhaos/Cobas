using namespace NLog
using namespace System.IO

class tmp_ {
    
    [Logger]$Logger
    [hashtable]$Conf
    [Result[]]$Results
    [string[]]$Files
    [int]$Numbering

    tmp_ ([hashtable]$conf, [Logger]$logger) {
        
        $this.Conf = $conf

        $this.Logger = $logger
        $this.Logger.Info("tmp_ init parameters:")
        $this.Logger.Info("Source directory :{0}", $conf.SourcePath)
        $this.Logger.Info("Wildcard         :{0}", $conf.Wildcard)
        $this.Logger.Info("QArchPath        :{0}", $conf.QArchPath)
        $this.Logger.Info("ErrArchPath      :{0}", $conf.ErrArchPath)
        $this.Logger.Info("ArchPath         :{0}", $conf.ArchPath)

        $this.Numbering = [int]::Parse([file]::ReadAllText($this.Conf.Numbering))
    }

    LoadFiles() {
        $this.Files = [Directory]::GetFiles($this.Conf.SourcePath, $this.Conf.Wildcard)
        if ($this.Files.Count -eq 0) {
            $this.Logger.Info("No files found")
            exit 1
        }
        else {
            $this.Logger.Info("Found {0} files", $this.Files.Count)
        }
    }

    LoadResults() {
        
        :file foreach ($file in $this.Files) {
            
            $this.Logger.Info("Process file: {0}", $file)
            $parseState = [ParseFileState]::stateInit

            foreach ($line in [file]::ReadAllLines($file)) {
                
                switch ($parseState) {
                ([ParseFileState]::stateInit) {
                        if ($line.StartsWith("H")) {
                            $parseState = [ParseFileState]::stateHOpen
                            break
                        }
                        else {
                            $this.Logger.Info("Invalid file found [H] {0}", $file)
                            $this.ArchErrFile($file)
                            continue file
                        }
                    }
                ([ParseFileState]::stateHOpen) {
                        if ($line.StartsWith("P")) {
                            $parseState = [ParseFileState]::statePOpen
                            break
                        }
                        if ($line.StartsWith("Q")) {
                            $this.ArchQFile($file)
                            continue file
                        }
                        else {
                            $this.Logger.Info("Invalid file found [P] {0}", $file)
                            $this.ArchErrFile($file)
                            continue file
                        }
                    }
                ([ParseFileState]::statePOpen) {
                        if ($line.StartsWith("O")) {
                            $splitLine = $line.split("|")
                            $accession = ($splitLine[2].split("^")[0] -split "\s")[0]

                            if ($accession -match "\d{10}") {
                                $this.Results += , [Result]::new($accession)
                                $parseState = [ParseFileState]::stateOOpen
                                break
                            }
                            else {
                                $this.ArchQFile($file)
                                continue file
                            }
                        }
                        else {
                            $this.Logger.Info("Invalid file found [O] {0}", $file)
                            $this.ArchErrFile($file)
                            continue file
                        }
                    }
                ([ParseFileState]::stateOOpen) { 
                        if ($line.StartsWith("R")) {
                            $splitLine = $line.split("|")
                            $splitR2 = $splitLine[2].Split("^")
                            $this.Results[-1].AddTest($splitR2[3], $splitLine[3])
                            $parseState = [ParseFileState]::stateROpen
                            break
                        }
                        else {
                            $this.Logger.Info("Invalid file found [R] {0}", $file)
                            $this.ArchErrFile($file)
                            continue file
                        }
                    }
                ([ParseFileState]::stateROpen) {
                        if ($line.StartsWith("O")) {
                            $splitLine = $line.split("|")
                            $accession = ($splitLine[2].split("^")[0] -split "\s")[0]
                            if ($accession -match "\d{10}") {
                                $this.Results += , [Result]::new($accession)
                                $parseState = [ParseFileState]::stateOOpen
                                break
                            }
                            else {
                                $this.ArchQFile($file)
                                continue file
                            }
                        }
                    
                        elseif ($line.StartsWith("C")) {
                            $parseState = [ParseFileState]::stateCOpen
                            break
                        }
                        elseif ($line.StartsWith("L")) {
                            $this.ArchFile($file)
                            continue file
                        }
                        else {
                            $this.Logger.Info("Invalid file found [R] {0}", $file)
                            $this.ArchErrFile($file)
                            continue file
                        }
                    }
                ([ParseFileState]::stateCOpen) {
                        if ($line.StartsWith("O")) {
                            $splitLine = $line.split("|")
                            $accession = ($splitLine[2].split("^")[0] -split "\s")[0]
                            if ($accession -match "\d{10}") {
                                $this.Results += , [Result]::new($accession)
                                $parseState = [ParseFileState]::stateOOpen
                                break
                            }
                            else {
                                $this.ArchQFile($file)
                                continue file
                            }
                        }
                        elseif ($line.StartsWith("L")) {
                            $this.ArchFile($file)
                            continue file
                        }
                        else {
                            $this.Logger.Info("Invalid file found [R] {0}", $file)
                            continue file
                        }
                    }
                }
            }
        }
    }
    
    ReportResults () {
        $sb = [System.Text.StringBuilder]::new()
        $sb.AppendLine("Accession,TestName,TestResult")
        If($this.Results.Count -eq 0){return}
        foreach ($result in $this.Results ) {
            $sb.AppendFormat("{0},{1},{2}", $result.Accession, $result.TestName, $result.Result)
            $sb.AppendLine()
        }
        $outFileName = [path]::Join($this.Conf.OutPath, ($this.Conf.OutFileMask -f [datetime]::Now))
        $this.Logger.Info("out file name: {0}", $outFileName)
        [file]::WriteAllText($outFileName, $sb.ToString())
    }

    ArchQFile([string]$filename) {
        $this.Logger.Info("Q file found: {0}", $filename)
        $archFileName = [path]::Join($this.Conf.QArchPath, [path]::GetFileName($filename))
        [file]::Move($filename, $archFileName, $true)
    }

    ArchFile ([string]$filename) {
        $this.Logger.Info("file processed successfully: {0}", $filename)
        $archFileName = [path]::Join($this.Conf.ArchPath, ("{0:d4}_{1}" -f ++$this.Numbering, [path]::GetFileName($filename)))
        [file]::Move($filename, $archFileName, $true)
    }

    ArchErrFile ([string]$filename) {
        $archFileName = [path]::Join($this.Conf.ErrArchPath, [path]::GetFileName($filename))
        [file]::Move($filename, $archFileName, $true)
    }
}

enum ParseFileState {
    stateinit
    stateHOpen
    statePOpen 
    stateOOpen
    stateROpen
    stateCOpen
}

class Result {
    [string]$Accession
    [string]$TestName
    [string]$Result
    
    Result($Accession) {
        $this.Accession = $Accession
    }
    AddTest ([string]$TestName, [string]$Result) {
        $this.TestName = $TestName
        $this.Result = $Result
    }
}