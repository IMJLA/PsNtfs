function Format-SecurityPrincipal {

    # Format Security Principals (distinguish group members from principals directly listed in the NTFS DACLs)
    # The IdentityReference property will be null for any principals directly listed in the NTFS DACLs

    param (

        # Security Principals received from Expand-IdentityReference in the Adsi module
        [string]$ResolvedID,

        # Thread-safe hashtable to use for caching directory entries and avoiding duplicate directory queries
        [hashtable]$PrincipalsByResolvedID = ([hashtable]::Synchronized(@{}))

    )

    # Get the security principal from the cache
    $ThisPrincipal = $PrincipalsByResolvedID[$ResolvedID]

    # Exclude accounts whose classes were specified in the parameters
    if ($ExcludeClass.Count -gt 0) {
        if ($ClassExclusions[$ThisPrincipal.DirectoryEntry.SchemaClassName]) {
            continue
        }
    }

    $Access = $ACEsByGUID[$AceGUIDsByResolvedID[$ID]]

    # Format the security principal
    # Include specific desired properties
    $OutputProperties = @{
        Access = $Access
        #User = Format-SecurityPrincipalUser -InputObject $ThisPrincipal
        #Name = Format-SecurityPrincipalName -InputObject $ThisPrincipal
    }

    if ($ThisPrincipal.DirectoryEntry) {

        $InputProperties = (Get-Member -InputObject $ThisPrincipal.DirectoryEntry -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

        ForEach ($ThisProperty in $InputProperties) {
            $OutputProperties[$ThisProperty] = $ThisPrincipal.DirectoryEntry.$ThisProperty
        }

    }

    # Get any existing properties for inclusion later
    $InputProperties = (Get-Member -InputObject $ThisPrincipal -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

    # Include any existing properties found earlier
    ForEach ($ThisProperty in $InputProperties) {
        $OutputProperties[$ThisProperty] = $ThisPrincipal.$ThisProperty
    }
    $OutputProperties['ParentIdentityReference'] = $null

    # Output the security principal
    [PSCustomObject]$OutputProperties

    # Format and output any group members
    Format-SecurityPrincipalMember -InputObject $ThisPrincipal.Members -IdentityReference $ResolvedID -Access $Access

}
