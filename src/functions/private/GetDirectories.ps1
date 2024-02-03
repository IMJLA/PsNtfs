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
        [hashtable]$LogMsgCache = $Global:LogMessages,

        [int]$ProgressParentId,

        # List of currently active progress bar IDs to avoid conflicts.
        [hashtable]$ActiveProgressIdList = ([hashtable]::Synchronized())
    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $CurrentOperation = "[System.IO.Directory]::GetDirectories('$TargetPath','$SearchPattern',[System.IO.SearchOption]::$SearchOption)"
    $ProgressParams = @{
        Activity = 'GetDirectories'
    }
    if ($PSBoundParameters.ContainsKey('ProgressParentId')) {
        $ActiveProgressIdList[$ProgressParentId] = $true
        $ProgressParams['ParentId'] = $ProgressParentId
    }
    do {
        $ProgressId = [System.Random]::new().Next(0, [int]::MaxValue)
    } until (-not $ActiveProgressIdList.ContainsKey($ProgressId))
    $ActiveProgressIdList[$ProgressId] = $true
    do {
        $ProgressChildId = [System.Random]::new().Next(0, [int]::MaxValue)
    } until (-not $ActiveProgressIdList.ContainsKey($ProgressId))
    $ActiveProgressIdList[$ProgressChildId] = $true
    $ProgressParams['Id'] = $ProgressId
    Write-Progress @ProgressParams -Status '0% (step 1 of 3)' -CurrentOperation $CurrentOperation -PercentComplete 0
    Start-Sleep -Seconds 1

    # Try to run the command as instructed
    Write-LogMsg @LogParams -Text $CurrentOperation
    try {
        $result = [System.IO.Directory]::GetDirectories($TargetPath, $SearchPattern, $SearchOption)
        return $result
    }
    catch {
        Write-LogMsg @LogParams -Type Warning -Text $_.Exception.Message.Replace('Exception calling "GetDirectories" with "3" argument(s): ', '').Replace('"', '')
    }

    $CurrentOperation = "[System.IO.Directory]::GetDirectories('$TargetPath','$SearchPattern',[System.IO.SearchOption]::TopDirectoryOnly)"
    Write-Progress @ProgressParams -Status '33% (step 2 of 3)' -CurrentOperation $CurrentOperation -PercentComplete 33
    Start-Sleep -Seconds 1

    # Sometimes access is denied to a single buried subdirectory, so we will try searching the top directory only and then recursing through results one at a time
    Write-LogMsg @LogParams -Text "[System.IO.Directory]::GetDirectories('$TargetPath','$SearchPattern',[System.IO.SearchOption]::TopDirectoryOnly)"
    try {
        $result = [System.IO.Directory]::GetDirectories($TargetPath, $SearchPattern, [System.IO.SearchOption]::TopDirectoryOnly)
    }
    catch {
        Write-LogMsg @LogParams -Type Warning -Text $_.Exception.Message.Replace('Exception calling "GetDirectories" with "3" argument(s): ', '').Replace('"', '')
        return
    }

    $CurrentOperation = "[System.IO.Directory]::GetDirectories('$TargetPath','$SearchPattern',[System.IO.SearchOption]::TopDirectoryOnly)"
    Write-Progress @ProgressParams -Status '66% (step 3 of 3)' -CurrentOperation 'Recursing through children' -PercentComplete 66
    Start-Sleep -Seconds 1

    $GetSubfolderParams = @{
        LogMsgCache          = $LogMsgCache
        ThisHostname         = $ThisHostname
        DebugOutputStream    = $DebugOutputStream
        WhoAmI               = $WhoAmI
        ProgressParentId     = $ProgressId
        SearchOption         = $SearchOption
        SearchPattern        = $SearchPattern
        ActiveProgressIdList = $ActiveProgressIdList
    }

    $Count = $result.Count
    [int]$ProgressInterval = [math]::max(($Count / 100), 1)
    $ProgressCounter = 0
    $i = 0
    ForEach ($Child in $result) {
        $ProgressCounter++
        $CurrentOperation = "GetDirectories -TargetPath '$Child' -SearchPattern '$SearchPattern' -SearchOption '$SearchOption'"
        if ($ProgressCounter -eq $ProgressInterval) {
            [int]$PercentComplete = $i / $Count * 100
            Write-Progress -Activity 'GetDirectories recursion' -Status "$PercentComplete% (child $i of $Count)" -CurrentOperation $CurrentOperation -PercentComplete $PercentComplete -ParentId $ProgressId -Id $ProgressChildId
            Start-Sleep -Seconds 1
            $ProgressCounter = 0
        }
        $i++
        Write-LogMsg @LogParams -Text $CurrentOperation
        GetDirectories -TargetPath $Child @GetSubfolderParams
    }

    Write-Progress -Activity 'GetDirectories recursion' -Completed -Id $ProgressChildId
    $ActiveProgressIdList.Remove($ProgressChildId)
    Write-Progress -Activity 'GetDirectories' -Completed -Id $ProgressId
    $ActiveProgressIdList.Remove($ProgressId)
    Start-Sleep -Seconds 1

}
