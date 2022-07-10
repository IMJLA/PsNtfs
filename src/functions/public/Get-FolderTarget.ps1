function Get-FolderTarget {

    param (
        [string[]]$FolderPath
    )

    process {
        foreach ($TargetPath in $FolderPath) {

            $RegEx = '^(?<DriveLetter>\w):'
            if ($TargetPath -match $RegEx) {
                $TargetPath -replace $RegEx, "\\$(hostname)\$($Matches.DriveLetter)$"
            } else {
                #$DFSDetails = [NetApi32Dll]::NetDfsGetInfo($TargetPath) # Can't use this because it doesn't work if the provided path is a subfolder of a DFS folder
                $AllDfs = Get-NetDfsEnum -Verbose -FolderPath $TargetPath
                $DfsDetails = $AllDfs |
                Group-Object -Property DfsEntryPath |
                Where-Object -FilterScript { "$TargetPath" -like "$($_.Name)\*" } |
                Sort-Object -Property Name
                $DfsNamespaceRoot = $DfsDetails |
                Select-Object -First 1
                $DfsDetails |
                Select-Object -Last 1 -ExpandProperty Group |
                ForEach-Object {
                    $_.FullOriginalQueryPath -replace [regex]::Escape($_.DfsEntryPath), $_.DfsTarget
                }
            }
        }
    }

}
