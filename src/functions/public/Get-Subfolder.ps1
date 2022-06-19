function Get-Subfolder {

    # Use the fastest available method to enumerate subfolders

    [CmdletBinding()]
    param (

        # Parent folder whose subfolders to enumerate
        [string]$TargetPath,

        <#
            How many levels of recursive subfolder enumeration to perform
            Equivalent to the Depth parameter of Get-ChildItem
            Set to 0 to disable recursion
            Set to -1 (default) to recurse infinitely
        #>
        [int]$FolderRecursionDepth = -1
    )

    if ($FolderRecursionDepth -eq -1) {
        $DepthString = '∞'
    }
    else {
        $DepthString = $FolderRecursionDepth
    }
    Write-Progress -Activity ("Retrieving subfolders...") -Status ("Enumerating all subfolders of '$TargetPath' to a depth of $DepthString levels of recursion") -PercentComplete 50
    if($Host.Version.Major -gt 2){
        if ($FolderRecursionDepth -eq -1) {
                #Write-Debug "Get-ChildItem '$TargetPath' -Force -Name -Recurse -Attributes Directory"
                #Get-ChildItem $TargetPath -Force -Name -Recurse -Attributes Directory
                $SearchOption = [System.IO.SearchOption]::AllDirectories
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-Subfolder`t[System.IO.Directory]::GetDirectories('$TargetPath','*',[System.IO.SearchOption]::AllDirectories)"
                try {
                    [System.IO.Directory]::GetDirectories($TargetPath,'*',$SearchOption)
                }
                catch {
                    Write-Warning "$(Get-Date -Format s)`t$(hostname)`tGet-Subfolder`t$($_.Exception.Message)"
                }
        }
        else {
            Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-Subfolder`tGet-ChildItem '$TargetPath' -Force -Name -Recurse -Attributes Directory -Depth $FolderRecursionDepth"
            (Get-ChildItem $TargetPath -Force -Recurse -Attributes Directory -Depth $FolderRecursionDepth).FullName
        }
    }
    else{
        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-Subfolder`tGet-ChildItem '$TargetPath' -Recurse"
        Get-ChildItem $TargetPath -Recurse | Where-Object -FilterScript {$_.PSIsContainer} | ForEach-Object {$_.FullName}
    }
    Write-Progress -Activity ("Retrieving subfolders...") -Completed
}