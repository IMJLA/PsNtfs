function Format-SecurityPrincipal {

    # Format Security Principals (distinguish group members from principals directly listed in the NTFS DACLs)
    # The IdentityReference property will be null for any principals directly listed in the NTFS DACLs

    param (

        # Security Principals received from Expand-IdentityReference in the Adsi module
        $SecurityPrincipal

    )

    ForEach ($ThisPrincipal in $SecurityPrincipal) {

        # Format and output the security principal
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

        # Format and output its members if it is a group
        $ThisPrincipal.Members |
        <#
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
        #>
        Select-Object -Property @{
            Label      = 'User'
            Expression = {
                if ($_.SamAccountName) {
                    $AccountName = $_.SamAccountName
                } else {
                    if ($_.Properties) {
                        if ($_.Properties['SamAccountName'].Value) {
                            $AccountName = $_.Properties['SamAccountName'].Value
                        } else {
                            $AccountName = $_.Properties['SamAccountName']
                        }
                    }
                }
                "$($_.Domain.Netbios)\$AccountName"
            }
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


    }

}
