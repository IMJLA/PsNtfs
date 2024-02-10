function Format-SecurityPrincipalMemberUser {
    param ([object]$InputObject)
    if ($InputObject.Properties) {
        $sAmAccountName = $InputObject.Properties['sAmAccountName']
        if ("$sAmAccountName" -eq '') {
            $sAmAccountName = $InputObject.Properties['Name']
        }
    }

    if ("$sAmAccountName" -eq '') {
        # This code should never execute
        # but if we are somehow not dealing with a DirectoryEntry,
        # it will not have sAmAcountName or Name properties
        # However it may have a direct Name attribute on the PSObject itself
        # We will attempt that as a last resort in hopes of avoiding a null Account name
        $sAmAccountName = $InputObject.Name
    }
    "$($InputObject.Domain.Netbios)\$sAmAccountName"
}