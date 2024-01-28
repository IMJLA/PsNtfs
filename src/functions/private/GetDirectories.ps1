function GetDirectories {
    param (
        [Parameter(Mandatory)]
        [string]$TargetPath,

        [string]$SearchPattern = '*',

        [System.IO.SearchOption]$SearchOption = [System.IO.SearchOption]::AllDirectories
    )

    # Try to run the command as instructed
    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGetDirectories`t[System.IO.Directory]::GetDirectories('$TargetPath','$SearchPattern',[System.IO.SearchOption]::$SearchOption)"
    try {
        $result = [System.IO.Directory]::GetDirectories($TargetPath, $SearchPattern, $SearchOption)
        return $result
    }
    catch {
        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tGetDirectories`t$($_.Exception.Message)"
    }

    # Sometimes access is denied to a single buried subdirectory, so we will try searching the top directory only and then recursing through results one at a time
    try {
        $result = [System.IO.Directory]::GetDirectories($TargetPath, $SearchPattern, [System.IO.SearchOption]::TopDirectoryOnly)
    }
    catch {
        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tGetDirectories`t$($_.Exception.Message)"
        return
    }
    ForEach ($Child in $result) {
        GetDirectories -TargetPath $Child -SearchPattern $SearchPattern -SearchOption $SearchOption
    }

}