using namespace NLog
using namespace NLog.Config
using namespace Nlog.Targets
using namespace System.IO

class NLogBuilder {
    static [Logger] GetLogger ([hashtable]$conf) {
        $NLogConf = [LoggingConfiguration]::new()
        $fileTarget = [FileTarget]::new('logfile')
        $fileTarget.FileName = [Path]::Join([Path]::GetFullPath($conf.logDirectory), $conf.LogFilenameFormat)  
        $consoleTarget = [ConsoleTarget]::new("console")
        $NLogConf.AddRule([LogLevel]::Trace, [LogLevel]::Fatal, $fileTarget)
        $NLogConf.AddRule([LogLevel]::Trace, [LogLevel]::Fatal, $consoleTarget)
        [LogManager]::Configuration = $NLogConf
        $l = [LogManager]::GetLogger('logger')
        return [LogManager]::GetLogger('logger')
    }
}