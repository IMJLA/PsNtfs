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
        [hashtable]$LogBuffer = ([hashtable]::Synchronized(@{})),

        # Hashtable of warning messages to avoid writing duplicate warnings when recurisive calls error while retrying a folder
        [System.Collections.Specialized.OrderedDictionary]$WarningCache = [ordered]@{}

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        Buffer  = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    # Try to run the command as instructed
    Write-LogMsg @LogParams -Text "[System.IO.Directory]::GetDirectories('$TargetPath','$SearchPattern',[System.IO.SearchOption]::$SearchOption)"

    try {

        $result = [System.IO.Directory]::GetDirectories($TargetPath, $SearchPattern, $SearchOption)
        return $result

    }
    catch {

        $WarningCache[$_.Exception.Message.Replace('Exception calling "GetDirectories" with "3" argument(s): ', '').Replace('"', '')] = $null

    }

    # Sometimes access is denied to a single buried subdirectory, so we will try searching the top directory only and then recursing through results one at a time
    Write-LogMsg @LogParams -Text "[System.IO.Directory]::GetDirectories('$TargetPath','$SearchPattern',[System.IO.SearchOption]::TopDirectoryOnly)"

    try {

        $result = [System.IO.Directory]::GetDirectories($TargetPath, $SearchPattern, [System.IO.SearchOption]::TopDirectoryOnly)

    }
    catch {

        $WarningCache[$_.Exception.Message.Replace('Exception calling "GetDirectories" with "3" argument(s): ', '').Replace('"', '')] = $null

        # If this was not a recursive call to GetDirectories, write the warnings
        if (-not $PSBoundParameters.ContainsKey('WarningCache')) {

            $LogParams['Type'] = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat

            ForEach ($Warning in $WarningCache.Keys) {

                Write-LogMsg @LogParams -Text $_.Exception.Message.Replace('Exception calling "GetDirectories" with "3" argument(s): ', '').Replace('"', '')

            }
        }

        return

    }

    $GetSubfolderParams = @{
        LogBuffer       = $LogBuffer
        ThisHostname      = $ThisHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
        SearchOption      = $SearchOption
        SearchPattern     = $SearchPattern
        WarningCache      = $WarningCache
    }

    ForEach ($Child in $result) {

        Write-LogMsg @LogParams -Text "[System.IO.Directory]::GetDirectories('$Child','$SearchPattern',[System.IO.SearchOption]::$SearchOption)"
        GetDirectories -TargetPath $Child @GetSubfolderParams

    }

    # If this was not a recursive call to GetDirectories, write the warnings
    if (-not $PSBoundParameters.ContainsKey('WarningCache')) {

        if ($WarningCache.Keys.Count -ge 1) {

            $LogParams['Type'] = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat
            Write-LogMsg @LogParams -Text "$($WarningCache.Keys.Count) errors while getting directories of '$TargetPath'.  See verbose log for details."
            $LogParams['Type'] = 'Verbose' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat

            ForEach ($Warning in $WarningCache.Keys) {

                Write-LogMsg @LogParams -Text $Warning

            }

        }

    }

}
