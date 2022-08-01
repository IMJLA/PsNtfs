function Get-FolderTarget {

    param (
        [string[]]$FolderPath
    )

    process {
        foreach ($TargetPath in $FolderPath) {

            $RegEx = '^(?<DriveLetter>\w):'
            if ($TargetPath -match $RegEx) {
                # TODO: Resolve mapped network drives to their UNC path, currently this will incorrectly treat them as local paths
                $TargetPath -replace $RegEx, "\\$(hostname)\$($Matches.DriveLetter)$"
            } else {
                # Can't use [NetApi32Dll]::NetDfsGetInfo($TargetPath) because it doesn't work if the provided path is a subfolder of a DFS folder
                # Can't use [NetApi32Dll]::NetDfsGetClientInfo($TargetPath) because it does not return disabled folder targets
                # Instead need to use [NetApi32Dll]::NetDfsEnum($TargetPath) then Where-Object to filter results
                $AllDfs = Get-NetDfsEnum -Verbose -FolderPath $TargetPath

                $MatchingDfsEntryPaths = $AllDfs |
                Group-Object -Property DfsEntryPath |
                Where-Object -FilterScript {
                    $TargetPath -match [regex]::Escape($_.Name)
                }

                # Filter out the DFS Namespace
                # TODO: I know this is an inefficient n2 algorithm, but my brain is fried...plez...halp...leeloo dallas multipass
                $RemainingDfsEntryPaths = $MatchingDfsEntryPaths |
                Where-Object -FilterScript {
                    -not [bool]$(
                        ForEach ($ThisEntryPath in $MatchingDfsEntryPaths) {
                            if ($ThisEntryPath.Name -match "$([regex]::Escape("$($_.Name)")).+") { $true }
                        }
                    )
                } |
                Sort-Object -Property Name

                $RemainingDfsEntryPaths |
                Select-Object -Last 1 -ExpandProperty Group |
                ForEach-Object {
                    $_.FullOriginalQueryPath -replace [regex]::Escape($_.DfsEntryPath), $_.DfsTarget
                }
            }
        }
    }

}
