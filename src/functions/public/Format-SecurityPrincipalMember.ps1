function Format-SecurityPrincipalMember {

    param (
        [object[]]$ResolvedID,
        [string]$ParentIdentityReference,
        [object[]]$Access,
        [hashtable]$PrincipalsByResolvedID = ([hashtable]::Synchronized(@{}))
    )

    ForEach ($ID in $ResolvedID) {

        $Principal = $PrincipalsByResolvedID[$ID]

        # Include specific desired properties
        $OutputProperties = @{
            Access                          = $Access
            ParentIdentityReferenceResolved = $ParentIdentityReference
        }

        if ($Principal.DirectoryEntry) {

            $InputProperties = (Get-Member -InputObject $Principal.DirectoryEntry -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

            ForEach ($ThisProperty in $InputProperties) {
                $OutputProperties[$ThisProperty] = $Principal.DirectoryEntry.$ThisProperty
            }

        }

        # Include any existing properties
        $InputProperties = (Get-Member -InputObject $Principal -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

        ForEach ($ThisProperty in $InputProperties) {
            $OutputProperties[$ThisProperty] = $Principal.$ThisProperty
        }

        [PSCustomObject]$OutputProperties

    }

}