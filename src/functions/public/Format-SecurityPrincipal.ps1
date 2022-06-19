function Format-SecurityPrincipal {

    # Format Security Principals (distinguish group members from users directly listed in the NTFS DACLs)
    # Filter out groups (their members have already been retrieved)

    param (

        # Security Principals received from Expand-IdentityReference in the PsAdsi module
        $SecurityPrincipal

    )

    #$i = 0
    #$TotalCount = ($SecurityPrincipal | Measure-Object).Count

    ForEach ($ThisPrincipal in $SecurityPrincipal) {

        #$i++
        #Calculate the completion percentage, and format it to show 0 decimal places.
        #if ($TotalCount -eq 0) {
        #    $percentage = '100'
        #}
        #else {
        #    $percentage = "{0:N0}" -f (($i/$TotalCount)*100)
        #}

        #Display the progress bar
        #$status = ("$(Get-Date -Format s)`t$(hostname)`tFormat-SecurityPrincipal`tStatus: " + $percentage + "% - Formatting security principal $i of " + $TotalCount + ": " + $_.Name)
        #Write-Host "HOST:    $status"
        #Write-Progress -Activity ("Total Security Principals: " + $TotalCount) -Status $status -PercentComplete $percentage

        if ($ThisPrincipal.Members) {
            #If it has members, it must be a group
            $ThisPrincipal.Members |
            # Because we have already recursively retrieved all group members, we now have all the users so we can filter out the groups from the group members.
            Where-Object -FilterScript {
                if ($_.DirectoryEntry.Properties) {
                    $_.DirectoryEntry.Properties['objectClass'] -notcontains 'group' -and
                    $null -eq $_.DirectoryEntry.Properties['groupType'].Value
                } else {
                    $_.Properties['objectClass'] -notcontains 'group' -and
                    $null -eq $_.Properties['groupType'].Value
                }
            } |
            Select-Object -Property @{
                Label      = 'User'
                Expression = { "$($_.Domain.Netbios)\$($_.SamAccountName)" }
            },
            @{
                Label      = 'IdentityReference'
                Expression = { $ThisPrincipal.Group.IdentityReference | Sort-Object -Unique }
            },
            @{
                Label      = 'NtfsAccessControlEntries'
                Expression = { $ThisPrincipal.Group }
            },
            *
        } else {
            # This means it is either a user, or an empty group
            $ThisPrincipal |
            Select-Object -Property @{
                Label      = 'User'
                Expression = { $_.Name }
            },
            @{
                Label      = 'IdentityReference'
                Expression = { $null }
            },
            @{
                Label      = 'NtfsAccessControlEntries'
                Expression = { $_.Group }
            },
            *
        }

    }

    #Write-Progress -Activity ("Total Security Principals: " + $TotalCount) -Completed

}
