function Format-SecurityPrincipalMember {

    param ([object[]]$InputObject)

    ForEach ($ThisObject in $InputObject) {

        # Include specific desired properties
        $OutputProperties = @{
            User              = Format-SecurityPrincipalMemberUser -InputObject $ThisObject
            IdentityReference = @($ThisObject.Group.IdentityReferenceResolved)[0]
            ObjectType        = $ThisObject.SchemaClassName
        }

        # Include any existing properties
        $InputProperties = (Get-Member -InputObject $ThisObject -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

        ForEach ($ThisProperty in $InputProperties) {
            $OutputProperties[$ThisProperty] = $ThisObject.$ThisProperty
        }

        [PSCustomObject]$OutputProperties

    }

}