function Format-SecurityPrincipal {

    # Format Security Principals (distinguish group members from principals directly listed in the NTFS DACLs)
    # The IdentityReference property will be null for any principals directly listed in the NTFS DACLs

    param (

        # Security Principals received from Expand-IdentityReference in the Adsi module
        [object[]]$SecurityPrincipal

    )


    # Get any existing properties for inclusion later
    $InputProperties = (Get-Member -InputObject $SecurityPrincipal[0] -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

    ForEach ($ThisPrincipal in $SecurityPrincipal) {

        # Format the security principal
        # Include specific desired properties
        $OutputProperties = @{
            User                     = Format-SecurityPrincipalUser -InputObject $ThisPrincipal
            IdentityReference        = $null
            NtfsAccessControlEntries = $ThisPrincipal.Group
            Name                     = Format-SecurityPrincipalName -InputObject $ThisPrincipal
        }

        # Include any existing properties found earlier
        ForEach ($ThisProperty in $InputProperties) {
            $OutputProperties[$ThisProperty] = $ThisPrincipal.$ThisProperty
        }

        # Output the object
        [PSCustomObject]$OutputProperties

        # Format and output its members if it is a group
        Format-SecurityPrincipalMember -InputObject $ThisPrincipal.Members

    }

}
