function Format-FolderPermission {

    Param (

        # Expects ACEs grouped using Group-Object
        $UserPermission,

        # Ignore these FileSystemRights
        [string[]]$FileSystemRightsToIgnore = @('Synchronize'),

        <#
        Hostname of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE
        #>
        [string]$ThisHostName = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Dictionary of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages

    )

    begin {
        $i = 0

        $LogParams = @{
            ThisHostname = $ThisHostname
            Type         = 'Verbose'
            LogMsgCache  = $LogMsgCache
            WhoAmI       = $WhoAmI
        }

        $Activity = "Format-FolderPermission -FileSystemRightsToIgnore @('$($FileSystemRightsToIgnore -join "','")')"

    }
    process {

        $Count = ($UserPermission | Measure-Object).Count

        ForEach ($ThisUser in $UserPermission) {

            #Calculate the completion percentage, and format it to show 0 decimal places
            $i++
            $NewPercentComplete = $i / $Count * 100

            #Update the log with the current status
            [string]$statusMsg = "$([int]$NewPercentComplete)% ($($Count - $i) of $Count remain) Formatting user permission $i of $Count`: $($ThisUser.Name)"
            Write-LogMsg @LogParams -Text $statusMsg

            # Update the progress bar if at least 1% has completed since last loop iteration
            if (($NewPercentComplete - $OldPercentComplete) -ge 1) {
                $OldPercentComplete = $NewPercentComplete
                $Progress = @{
                    Activity         = $Activity
                    CurrentOperation = $statusMsg
                    PercentComplete  = $NewPercentComplete
                    Status           = $statusMsg
                }
                Write-Progress -Activity @Progress
            }
            if ($ThisUser.Group.DirectoryEntry.Properties) {
                if (
                    (
                        $ThisUser.Group.DirectoryEntry |
                        ForEach-Object {
                            if ($null -ne $_) {
                                $_.GetType().FullName 2>$null
                            }
                        }
                    ) -contains 'System.Management.Automation.PSCustomObject'
                ) {
                    $Names = $ThisUser.Group.DirectoryEntry.Properties.Name
                    $Depts = $ThisUser.Group.DirectoryEntry.Properties.Department
                    $Titles = $ThisUser.Group.DirectoryEntry.Properties.Title
                }
                else {
                    $Names = $ThisUser.Group.DirectoryEntry |
                    ForEach-Object {
                        if ($_.Properties) {
                            $_.Properties['name']
                        }
                    }

                    $Depts = $ThisUser.Group.DirectoryEntry |
                    ForEach-Object {
                        if ($_.Properties) {
                            $_.Properties['department']
                        }
                    }

                    $Titles = $ThisUser.Group.DirectoryEntry |
                    ForEach-Object {
                        if ($_.Properties) {
                            $_.Properties['title']
                        }
                    }

                    if ($ThisUser.Group.DirectoryEntry.Properties['objectclass'] -contains 'group' -or
                        "$($ThisUser.Group.DirectoryEntry.Properties['groupType'])" -ne ''
                    ) {
                        $SchemaClassName = 'group'
                    }
                    else {
                        $SchemaClassName = 'user'
                    }
                }
                $Name = @($Names)[0]
                $Dept = @($Depts)[0]
                $Title = @($Titles)[0]
            }
            else {
                $Name = @($ThisUser.Group.name)[0]
                $Dept = @($ThisUser.Group.department)[0]
                $Title = @($ThisUser.Group.title)[0]

                if ($ThisUser.Group.Properties) {
                    if (
                        $ThisUser.Group.Properties['objectclass'] -contains 'group' -or
                        "$($ThisUser.Group.Properties['groupType'])" -ne ''
                    ) {
                        $SchemaClassName = 'group'
                    }
                    else {
                        $SchemaClassName = 'user'
                    }
                }
                else {
                    if ($ThisUser.Group.DirectoryEntry.SchemaClassName) {
                        $SchemaClassName = @($ThisUser.Group.DirectoryEntry.SchemaClassName)[0]
                    }
                    else {
                        $SchemaClassName = @($ThisUser.Group.SchemaClassName)[0]
                    }
                }
            }
            if ("$Name" -eq '') {
                $Name = $ThisUser.Name
            }

            ForEach ($ThisACE in $ThisUser.Group) {

                switch ($ThisACE.ACEInheritanceFlags) {
                    'ContainerInherit, ObjectInherit' { $Scope = 'this folder, subfolders, and files' }
                    'ContainerInherit' { $Scope = 'this folder and subfolders' }
                    'ObjectInherit' { $Scope = 'this folder and files, but not subfolders' }
                    default { $Scope = 'this folder but not subfolders' }
                }

                if ($null -eq $ThisUser.Group.IdentityReference) {
                    $IdentityReference = $null
                }
                else {
                    $IdentityReference = $ThisACE.ACEIdentityReferenceResolved
                }

                $FileSystemRights = $ThisACE.ACEFileSystemRights
                ForEach ($Ignore in $FileSystemRightsToIgnore) {
                    $FileSystemRights = $FileSystemRights -replace ", $Ignore\Z", '' -replace "$Ignore,", ''
                }

                [pscustomobject]@{
                    Folder                   = $ThisACE.ACESourceAccessList.Path
                    FolderInheritanceEnabled = !($ThisACE.ACESourceAccessList.AreAccessRulesProtected)
                    Access                   = "$($ThisACE.ACEAccessControlType) $FileSystemRights $Scope"
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
        Write-Progress -Activity $Activity
    }

}
