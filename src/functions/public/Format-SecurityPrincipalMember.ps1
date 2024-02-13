function Format-SecurityPrincipalMember {

    param (
        [object[]]$InputObject,
        [string]$IdentityReference,
        [object[]]$Access
    )

    ForEach ($ThisObject in $InputObject) {

        if ($ThisObject.sAmAccountName) {
            $AccountName = $ThisObject.sAmAccountName
        }
        else {
            $AccountName = $ThisObject.Name
        }

        # Include specific desired properties
        $OutputProperties = @{
            AccountName                     = "$($ThisObject.Domain.Netbios)\$AccountName"
            Access                          = $Access
            ParentIdentityReferenceResolved = $IdentityReference
        }

        # Include any existing properties
        $InputProperties = (Get-Member -InputObject $ThisObject -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

        ForEach ($ThisProperty in $InputProperties) {
            $OutputProperties[$ThisProperty] = $ThisObject.$ThisProperty
        }

        [PSCustomObject]$OutputProperties

    }

}