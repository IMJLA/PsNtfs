function Format-SecurityPrincipalMember {

    param (
        [object[]]$InputObject,
        [string]$IdentityReference,
        [object[]]$Access
    )

    ForEach ($ThisObject in $InputObject) {

        # Include specific desired properties
        $OutputProperties = @{
            AccountName                     = "$($ThisObject.Domain.Netbios)\$AccountName"
            Access                          = $Access
            ParentIdentityReferenceResolved = $IdentityReference
        }

        if ($ThisObject.DirectoryEntry) {

            $InputProperties = (Get-Member -InputObject $ThisObject.DirectoryEntry -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

            ForEach ($ThisProperty in $InputProperties) {
                $OutputProperties[$ThisProperty] = $ThisObject.DirectoryEntry.$ThisProperty
            }

        }

        if ($ThisObject.sAmAccountName) {
            $OutputProperties['AccountName'] = $ThisObject.sAmAccountName
        }
        else {
            $OutputProperties['AccountName'] = $ThisObject.Name
        }

        # Include any existing properties
        $InputProperties = (Get-Member -InputObject $ThisObject -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

        ForEach ($ThisProperty in $InputProperties) {
            $OutputProperties[$ThisProperty] = $ThisObject.$ThisProperty
        }

        [PSCustomObject]$OutputProperties

    }

}