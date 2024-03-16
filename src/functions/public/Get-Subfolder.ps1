function Get-Subfolder {

    # Use the fastest available method to enumerate subfolders

    [CmdletBinding()]
    param (

        # Parent folder whose subfolders to enumerate
        [string]$TargetPath,

        <#
        How many levels of subfolder to enumerate
            Set to 0 to ignore all subfolders
            Set to -1 (default) to recurse infinitely
            Set to any whole number to enumerate that many levels
        #>
        [int]$RecurseDepth = -1,

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Debug',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$ThisHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        [hashtable]$Output = [hashtable]::Synchronized(@{})

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $GetSubfolderParams = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $ThisHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
    }

    if ($RecurseDepth -eq -1) {
        $DepthString = '∞'
    }
    else {
        $DepthString = $RecurseDepth
    }

    $Output[$TargetPath] = if ($Host.Version.Major -gt 2) {

        switch ($RecurseDepth) {
            -1 {
                GetDirectories -TargetPath $TargetPath -SearchOption ([System.IO.SearchOption]::AllDirectories) @GetSubfolderParams
            }
            0 {}
            1 {
                GetDirectories -TargetPath $TargetPath -SearchOption ([System.IO.SearchOption]::TopDirectoryOnly) @GetSubfolderParams
            }
            Default {
                $RecurseDepth = $RecurseDepth - 1
                Write-LogMsg @LogParams -Text "Get-ChildItem '$TargetPath' -Force -Name -Recurse -Attributes Directory -Depth $RecurseDepth"
                (Get-ChildItem $TargetPath -Force -Recurse -Attributes Directory -Depth $RecurseDepth).FullName
            }
        }

    }
    else {

        Write-LogMsg @LogParams -Text "Get-ChildItem '$TargetPath' -Recurse"
        Get-ChildItem $TargetPath -Recurse | Where-Object -FilterScript { $_.PSIsContainer } | ForEach-Object { $_.FullName }

    }

}
