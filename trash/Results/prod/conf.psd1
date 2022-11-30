@{
	Name       = "Cobas-Results"
	tmp_       = @{
		SourcePath  = "./paths/source"
		Wildcard    = "*.txt"
		QArchPath   = "./paths/QC"
		ErrArchPath = "./paths/errArch"
		ArchPath    = "./paths/arch"
		Numbering   = "./resources/arc_count.txt"
		OutPath     = "./paths/out"
		OutFileMask = "r_Cobas_{0:yyyyMMddhhmmss}.csv"
	}
	NLogConfig = @{
		LogDirectory      = ".\logs"
		LogFilenameFormat = '${shortdate}.log'
	}
}