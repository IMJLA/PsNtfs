function Format-FolderPermission {

    Param (

        # Expects ACEs grouped using Group-Object
        $UserPermission,

        # Ignore these FileSystemRights
        [string[]]$FileSystemRightsToIgnore = @('Synchronize')

    )

    begin {
        $i = 0
    }
    process {

        ForEach ($ThisUser in $UserPermission) {

            $i++
            #Calculate the completion percentage, and format it to show 0 decimal places
            $percentage = "{0:N0}" -f (($i / ($UserPermission.Count)) * 100)

            #Display the progress bar
            $status = ("$(Get-Date -Format s)`t$(hostname)`tFormat-FolderPermission`tStatus: " + $percentage + "% - Processing user permission $i of " + $UserPermission.Count + ": " + $ThisUser.Name)
            Write-Verbose $status
            Write-Progress -Activity ("Total Users: " + $UserPermission.Count) -Status $status -PercentComplete $percentage

            if ($ThisUser.Group.DirectoryEntry.Properties) {
                $Name = $ThisUser.Group.DirectoryEntry.Properties['name'] | Sort-Object -Unique
                $Dept = $ThisUser.Group.DirectoryEntry.Properties['department'] | Sort-Object -Unique
                $Title = $ThisUser.Group.DirectoryEntry.Properties['title'] | Sort-Object -Unique
            } else {
                $Name = $ThisUser.Group.name | Sort-Object -Unique
                $Dept = $ThisUser.Group.department | Sort-Object -Unique
                $Title = $ThisUser.Group.title | Sort-Object -Unique
            }
            if ("$Name" -eq '') {
                $Name = $ThisUser.Name
            }
            if ($ThisUser.Group.DirectoryEntry.Properties) {
                if ($ThisUser.Group.DirectoryEntry.Properties['objectclass'] -contains 'group' -or
                    "$($ThisUser.Group.DirectoryEntry.Properties['groupType'])" -ne ''
                ) {
                    $SchemaClassName = 'group'
                } else {
                    $SchemaClassName = 'user'
                }
            } else {
                if ($ThisUser.Group.Properties) {
                    if (
                        $ThisUser.Group.Properties['objectclass'] -contains 'group' -or
                        "$($ThisUser.Group.Properties['groupType'])" -ne ''
                    ) {
                        $SchemaClassName = 'group'
                    } else {
                        $SchemaClassName = 'user'
                    }
                } else {
                    if ($ThisUser.Group.DirectoryEntry.SchemaClassName) {
                        $SchemaClassName = $ThisUser.Group.DirectoryEntry.SchemaClassName |
                        Select-Object -First 1
                    } else {
                        $SchemaClassName = $ThisUser.Group.SchemaClassName |
                        Select-Object -First 1
                    }
                }
            }

            ForEach ($ThisACE in $ThisUser.Group.NtfsAccessControlEntries) {

                switch ($ThisACE.InheritanceFlags) {
                    'ContainerInherit, ObjectInherit' { $Scope = 'this folder, subfolders, and files' }
                    'ContainerInherit' { $Scope = 'this folder and subfolders' }
                    'ObjectInherit' { $Scope = 'this folder and files, but not subfolders' }
                    default { $Scope = 'this folder but not subfolders' }
                }

                if ($null -eq $ThisUser.Group.IdentityReference) {
                    $IdentityReference = $null
                } else {
                    $IdentityReference = $ThisACE.IdentityReferenceResolved
                }

                $FileSystemRights = $ThisACE.FileSystemRights
                ForEach ($Ignore in $FileSystemRightsToIgnore) {
                    $FileSystemRights = $FileSystemRights -replace ", $Ignore\Z", '' -replace "$Ignore,", ''
                }

                [pscustomobject]@{
                    Folder                   = $ThisACE.SourceAccessList.Path
                    FolderInheritanceEnabled = !($ThisACE.SourceAccessList.AreAccessRulesProtected)
                    Access                   = "$($ThisACE.AccessControlType) $FileSystemRights $Scope"
                    Account                  = $ThisUser.Name
                    Name                     = $Name
                    Department               = $Dept
                    Title                    = $Title
                    IdentityReference        = $IdentityReference
                    AccessControlEntry       = $ThisACE
                    SchemaClassName          = $SchemaClassName
                }

            }

        }

    }

    end {
        Write-Progress -Activity ("Total User Permissions: " + $UserPermission.Count) -Completed
    }

}
