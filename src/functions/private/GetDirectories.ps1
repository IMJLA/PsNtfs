function GetDirectories {

    param (

        [Parameter(Mandatory)]
        [string]$TargetPath,

        [string]$SearchPattern = '*',

        [System.IO.SearchOption]$SearchOption = [System.IO.SearchOption]::AllDirectories,

        # Hashtable of warning messages to avoid writing duplicate warnings when recursive calls error while retrying a folder
        [System.Collections.Specialized.OrderedDictionary]$WarningCache = [ordered]@{},

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    # Try to run the command as instructed
    Write-LogMsg -Text "[System.IO.Directory]::GetDirectories('$TargetPath','$SearchPattern',[System.IO.SearchOption]::$SearchOption)" -Cache $Cache

    try {

        $result = [System.IO.Directory]::GetDirectories($TargetPath, $SearchPattern, $SearchOption)
        return $result

    }
    catch {

        $WarningCache[$_.Exception.Message.Replace('Exception calling "GetDirectories" with "3" argument(s): ', '').Replace('"', '')] = $null

    }

    # Sometimes access is denied to a single buried subdirectory, so we will try searching the top directory only and then recursing through results one at a time
    Write-LogMsg -Text "[System.IO.Directory]::GetDirectories('$TargetPath','$SearchPattern',[System.IO.SearchOption]::TopDirectoryOnly)" -Cache $Cache

    try {

        $result = [System.IO.Directory]::GetDirectories($TargetPath, $SearchPattern, [System.IO.SearchOption]::TopDirectoryOnly)

    }
    catch {

        $ThisWarning = $_.Exception.Message.Replace('Exception calling "GetDirectories" with "3" argument(s): ', '').Replace('"', '')
        $WarningCache[$ThisWarning] = $null

        # If this was not a recursive call to GetDirectories, write the warnings
        if (-not $PSBoundParameters.ContainsKey('WarningCache')) {

            $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat

            ForEach ($Warning in $WarningCache.Keys) {

                Write-LogMsg -Text $ThisWarning -Cache $Cache

            }
        }

        return

    }

    $GetSubfolderParams = @{
        Cache         = $Cache
        SearchOption  = $SearchOption
        SearchPattern = $SearchPattern
        WarningCache  = $WarningCache
    }

    ForEach ($Child in $result) {

        $Child
        Write-LogMsg -Text "[System.IO.Directory]::GetDirectories('$Child','$SearchPattern',[System.IO.SearchOption]::$SearchOption)" -Cache $Cache
        GetDirectories -TargetPath $Child @GetSubfolderParams

    }

    # If this was not a recursive call to GetDirectories, write the warnings
    if (-not $PSBoundParameters.ContainsKey('WarningCache')) {

        if ($WarningCache.Keys.Count -ge 1) {

            $StartingLogType = $Cache.Value['LogType'].Value
            $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat
            Write-LogMsg -Text "$($WarningCache.Keys.Count) errors while getting directories of '$TargetPath'.  See verbose log for details." -Cache $Cache
            $Cache.Value['LogType'].Value = 'Verbose' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat

            ForEach ($Warning in $WarningCache.Keys) {

                Write-LogMsg -Text $Warning -Cache $Cache

            }

            $Cache.Value['LogType'].Value = $StartingLogType

        }

    }

}
