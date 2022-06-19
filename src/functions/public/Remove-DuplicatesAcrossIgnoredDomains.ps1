function Remove-DuplicatesAcrossIgnoredDomains {

    param (

        [Parameter(ValueFromPipeline)]
        $UserPermission,

        [string[]]$DomainToIgnore

    )

    begin {
        $KnownUsers = [hashtable]::Synchronized(@{})
    }
    process {
        
        ForEach ($ThisUser in $UserPermission) {
            
            $ShortName = $ThisUser.Name
            ForEach ($IgnoreThisDomain in $DomainToIgnore) {
                $ShortName = $ShortName -replace $IgnoreThisDomain,''
            }

            if ($null -eq $KnownUsers[$ShortName]) {
                $KnownUsers[$ShortName] = [pscustomobject]@{
                    'Name' = $ShortName
                    'Group' = $ThisUser.Group
                }
            }
            else {
                $KnownUsers[$ShortName] = [pscustomobject]@{
                    'Name' = $ShortName
                    'Group' = $KnownUsers[$ShortName].Group + $ThisUser.Group
                }
            }
        }

    }
    end {
        $KnownUsers.Values | Sort-Object -Property Name
    }

}