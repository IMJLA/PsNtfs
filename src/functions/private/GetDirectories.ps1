function GetDirectories {
    param (
        [Parameter(Mandatory)]
        [string]$TargetPath,

        [string]$SearchPattern = '*',

        [System.IO.SearchOption]$SearchOption = [System.IO.SearchOption]::AllDirectories,

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Debug',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$ThisHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages
    )

    Write-Progress -Activity 'GetDirectories' -Status '0% Initializing...' -CurrentOperation $TargetPath -PercentComplete 0

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    # Try to run the command as instructed
    Write-LogMsg @LogParams -Text "[System.IO.Directory]::GetDirectories('$TargetPath','$SearchPattern',[System.IO.SearchOption]::$SearchOption)"
    try {
        $result = [System.IO.Directory]::GetDirectories($TargetPath, $SearchPattern, $SearchOption)
        return $result
    }
    catch {
        Write-LogMsg @LogParams -Type Warning -Text $_.Exception.Message.Replace('Exception calling "GetDirectories" with "3" argument(s): ', '').Replace('"', '')
    }

    # Sometimes access is denied to a single buried subdirectory, so we will try searching the top directory only and then recursing through results one at a time
    Write-LogMsg @LogParams -Text "[System.IO.Directory]::GetDirectories('$TargetPath','$SearchPattern',[System.IO.SearchOption]::TopDirectoryOnly)"
    try {
        $result = [System.IO.Directory]::GetDirectories($TargetPath, $SearchPattern, [System.IO.SearchOption]::TopDirectoryOnly)
    }
    catch {
        Write-LogMsg @LogParams -Type Warning -Text $_.Exception.Message.Replace('Exception calling "GetDirectories" with "3" argument(s): ', '').Replace('"', '')
        return
    }

    $GetSubfolderParams = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $ThisHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
    }

    ForEach ($Child in $result) {
        Write-LogMsg @LogParams -Text "GetDirectories -TargetPath '$Child' -SearchPattern '$SearchPattern' -SearchOption '$SearchOption'"
        GetDirectories -TargetPath $Child -SearchPattern $SearchPattern -SearchOption $SearchOption @GetSubfolderParams
    }

    Write-Progress -Activity 'GetDirectories' -Completed

}
