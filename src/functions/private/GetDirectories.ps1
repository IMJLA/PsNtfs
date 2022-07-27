function GetDirectories {
    param (
        [Parameter(Mandatory)]
        [string]$TargetPath,

        [string]$SearchPattern = '*',

        [System.IO.SearchOption]$SearchOption = [System.IO.SearchOption]::AllDirectories
    )
    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGetDirectories`t[System.IO.Directory]::GetDirectories('$TargetPath',$SearchPattern,[System.IO.SearchOption]::$SearchOption)"
    try {
        # SearchPattern is encased in double quotes because this returns an error in PS 5.1:
        # [System.IO.Directory]::GetDirectories('C:\Test',*,[System.IO.SearchOption]::AllDirectories)
        [System.IO.Directory]::GetDirectories($TargetPath, "$SearchPattern", $SearchOption)
    } catch {
        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tGetDirectories`t$($_.Exception.Message)"
    }
}
