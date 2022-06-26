
function GetDirectories {
    param (
        [Parameter(Mandatory)]
        [string]$TargetPath,

        [string]$SearchPattern = '*',

        [System.IO.SearchOption]$SearchOption = [System.IO.SearchOption]::AllDirectories
    )
    Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGetDirectories`t[System.IO.Directory]::GetDirectories('$TargetPath',$SearchPattern,[System.IO.SearchOption]::$SearchOption)"
    try {
        [System.IO.Directory]::GetDirectories($TargetPath, $SearchPattern, $SearchOption)
    } catch {
        Write-Warning "$(Get-Date -Format s)`t$(hostname)`tGetDirectories`t$($_.Exception.Message)"
    }
}
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

            ForEach ($ThisACE in $ThisUser.Group.NtfsAccessControlEntries) {

                switch ($ThisACE.InheritanceFlags) {
                    'ContainerInherit, ObjectInherit' { $Scope = 'this folder, subfolders, and files' }
                    'ContainerInherit' { $Scope = 'this folder and subfolders' }
                    'ObjectInherit' { $Scope = 'this folder and files, but not subfolders' }
                    default { $Scope = 'this folder but not subfolders' }
                }

                if ($ThisUser.Group.DirectoryEntry.Properties) {
                    $Name = $ThisUser.Group.DirectoryEntry.Properties['name'] | Sort-Object -Unique
                    $Dept = $ThisUser.Group.DirectoryEntry.Properties['department'] | Sort-Object -Unique
                    $Title = $ThisUser.Group.DirectoryEntry.Properties['title'] | Sort-Object -Unique
                } else {
                    $Name = $ThisUser.Group.name | Sort-Object -Unique
                    $Dept = $ThisUser.Group.department | Sort-Object -Unique
                    $Title = $ThisUser.Group.title | Sort-Object -Unique
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
                    Folder                   = $ThisACE.Path
                    FolderInheritanceEnabled = !($ThisACE.AreAccessRulesProtected)
                    Access                   = "$($ThisACE.AccessControlType) $FileSystemRights $Scope"
                    Account                  = $ThisUser.Name
                    Name                     = $Name
                    Department               = $Dept
                    Title                    = $Title
                    IdentityReference        = $IdentityReference
                    AccessControlEntry       = $ThisACE
                    SchemaClassName          = $ThisUser.Group.SchemaClassName | Select -First 1
                }

            }

        }

    }

    end {
        Write-Progress -Activity ("Total User Permissions: " + $UserPermission.Count) -Completed
    }

}
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
function Get-FolderTarget {

    param (
        [string[]]$FolderPath
    )

    process {
        foreach ($TargetPath in $FolderPath) {
        
            $RegEx = '^(?<DriveLetter>\w):'
            if ($TargetPath -match $RegEx) {
                $TargetPath -replace $RegEx, "\\$(hostname)\$($Matches.DriveLetter)$"                
            }
            else {
                #$DFSDetails = [NetApi32Dll]::NetDfsGetInfo($TargetPath) # Can't use this because it doesn't work if the provided path is a subfolder of a DFS folder
                $AllDfs = Get-NetDfsEnum -Verbose -FolderPath $TargetPath
                $DfsDetails = $AllDfs |
                    Group-Object -Property DfsEntryPath |
                        Where-Object -FilterScript {"$TargetPath" -like "$($_.Name)\*"} |
                            Sort-Object -Property Name
                $DfsNamespaceRoot = $DfsDetails |
                    Select-Object -First 1
                $DfsDetails |
                    Select-Object -Last 1 -ExpandProperty Group |
                        ForEach-Object {
                            $_.FullOriginalQueryPath -replace [regex]::Escape($_.DfsEntryPath), $_.DfsTarget
                        }
            }
        }
    }

}
function Get-NtfsAccessRule {
    <#
    .INPUTS
    [System.String]$DirectoryPath
    .OUTPUTS
    [PSCustomObject]
    #>

    [CmdletBinding(
        SupportsShouldProcess = $false,
        ConfirmImpact = "Low"
    )]

    param(

        # Path to the directory whose permissions to get
        [Parameter(ValueFromPipeline)]
        [string[]]$DirectoryPath,

        # Include inherited Access Control Entries in the results
        [Switch]$IncludeInherited
    )

    begin {
        $Sections = [System.Security.AccessControl.AccessControlSections]::Access
        $IncludeExplicitRules = $true
        $AccountType = [System.Security.Principal.SecurityIdentifier]
    }

    process {

        ForEach ($CurrentPath in $DirectoryPath) {

            $DirectoryInfo = Get-Item -LiteralPath $CurrentPath -ErrorAction SilentlyContinue

            if ($DirectoryInfo) {

                # New method for modern versions of PowerShell
                $FileSecurity = [System.Security.AccessControl.DirectorySecurity]::new(
                    $DirectoryInfo,
                    $Sections
                )

                $FileSecurity.GetAccessRules($IncludeExplicitRules, $IncludeInherited, $AccountType) |
                ForEach-Object {
                    [pscustomobject]@{
                        Path                        = $CurrentPath
                        PathAreAccessRulesProtected = $FileSecurity.AreAccessRulesProtected
                        FileSystemRights            = $_.FileSystemRights
                        AccessControlType           = $_.AccessControlType
                        IdentityReference           = $_.IdentityReference
                        IsInherited                 = $_.IsInherited
                        InheritanceFlags            = $_.InheritanceFlags
                        PropagationFlags            = $_.PropagationFlags
                    }
                }

            }

        }

    }

}
function Get-Subfolder {

    # Use the fastest available method to enumerate subfolders

    [CmdletBinding()]
    param (

        # Parent folder whose subfolders to enumerate
        [string]$TargetPath,

        <#
        How many levels of subfolder to enumerate
            Set to 0 to ignore all subfolders
            Set to -1 (default) to recurse infinitely
            Set to any whole number to enumerate that many levels
        #>
        [int]$FolderRecursionDepth = -1
    )

    if ($FolderRecursionDepth -eq -1) {
        $DepthString = '∞'
    } else {
        $DepthString = $FolderRecursionDepth
    }
    Write-Progress -Activity ("Retrieving subfolders...") -Status ("Enumerating all subfolders of '$TargetPath' to a depth of $DepthString levels of recursion") -PercentComplete 50
    if ($Host.Version.Major -gt 2) {
        switch ($FolderRecursionDepth) {
            -1 {
                GetDirectories -TargetPath $TargetPath -SearchOption ([System.IO.SearchOption]::AllDirectories)
            }
            0 {}
            1 {
                GetDirectories -TargetPath $TargetPath -SearchOption ([System.IO.SearchOption]::TopDirectoryOnly)
            }
            Default {
                $FolderRecursionDepth = $FolderRecursionDepth - 1
                Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-Subfolder`tGet-ChildItem '$TargetPath' -Force -Name -Recurse -Attributes Directory -Depth $FolderRecursionDepth"
                (Get-ChildItem $TargetPath -Force -Recurse -Attributes Directory -Depth $FolderRecursionDepth).FullName
            }
        }
    } else {
        Write-Debug "  $(Get-Date -Format s)`t$(hostname)`tGet-Subfolder`tGet-ChildItem '$TargetPath' -Recurse"
        Get-ChildItem $TargetPath -Recurse | Where-Object -FilterScript { $_.PSIsContainer } | ForEach-Object { $_.FullName }
    }
    Write-Progress -Activity ("Retrieving subfolders...") -Completed
}
function New-NtfsAclIssueReport {

    param (

        $FolderPermissions,

        $UserPermissions,

        <#
        If specified, all groups that have NTFS access to the target folder/subfolders will be evaluated for compliance with this naming convention
        The naming format that will be used for the users is CONTOSO\User1 where CONTOSO is the NetBIOS name of the domain, and User1 is the samAccountName of the user
        By default, this is a scriptblock that always evaluates to $true so it doesn't evaluate any naming convention compliance
        #>
        [scriptblock]$GroupNamingConvention = { $true }
    )

    $IssuesDetected = $false

    # List of folders with broken inheritance (recommend moving to higher level to avoid breaking inheritance.  Deny entries are a less desirable alternative)
    $FoldersWithBrokenInheritance = $FolderPermissions |
    Select-Object -Skip 1 |
    Where-Object -FilterScript {
                ($_.Group.FolderInheritanceEnabled | Select-Object -First 1) -eq $false -and
                (($_.Name -replace ([regex]::Escape($TargetPath)), '' -split '\\') | Measure-Object).Count -ne 2
    }
    $Count = ($FoldersWithBrokenInheritance | Measure-Object).Count
    if ($Count -gt 0) {
        $IssuesDetected = $true
        $Txt = "folders with broken inheritance: $($FoldersWithBrokenInheritance.Name -join "`r`n")"
    } else {
        $Txt = 'OK'
    }
    Write-Verbose "$Count`:$Txt"

    # List of ACEs for groups that do not match the specified naming convention
    # Invert the naming convention scriptblock (because we actually want to identify groups that do NOT follow the convention)
    $ViolatesNamingConvention = [scriptblock]::Create("!($GroupNamingConvention)")
    $NonCompliantGroups = $SecurityPrincipals |
    Where-Object -FilterScript { $_.ObjectType -contains 'Group' } |
    Where-Object -FilterScript $ViolatesNamingConvention |
    Select-Object -ExpandProperty Group |
    ForEach-Object { "$($_.IdentityReference) on '$($_.Path)'" }

    $Count = ($NonCompliantGroups | Measure-Object).Count
    if ($Count -gt 0) {
        $IssuesDetected = $true
        $Txt = "groups that don't match naming convention: $($NonCompliantGroups -join "`r`n")"
    } else {
        $Txt = 'OK'
    }
    Write-Verbose "$Count`:$Txt"

    # ACEs for users (recommend replacing with group-based access on any folder that is not a home folder)
    $UserACEs = $UserPermissions.Group |
    Where-Object { $_.ObjectType -contains 'User' } |
    ForEach-Object { $_.NtfsAccessControlEntries } |
    ForEach-Object { "$($_.IdentityReference) on '$($_.Path)'" } |
    Sort-Object -Unique
    $Count = ($UserACEs | Measure-Object).Count
    if ($Count -gt 0) {
        $IssuesDetected = $true
        $Txt = "users with ACEs: $($UserACEs -join "`r`n")"
    } else {
        $Txt = 'OK'
    }
    Write-Verbose "$Count`:$Txt"

    # ACEs for unresolvable SIDs (recommend removing these ACEs)
    $SIDsToCleanup = $UserPermissions.Group.NtfsAccessControlEntries |
    Where-Object -FilterScript { $_.IdentityReference -match 'S-\d+-\d+-\d+-\d+-\d+\-\d+\-\d+' } |
    ForEach-Object { "$($_.IdentityReference) on '$($_.Path)'" } |
    Sort-Object -Unique
    $Count = ($SIDsToCleanup | Measure-Object).Count
    if ($Count -gt 0) {
        $IssuesDetected = $true
        $Txt = "ACEs for unresolvable SIDs: $($SIDsToCleanup -join "`r`n")"
    } else {
        $Txt = 'OK'
    }
    Write-Verbose "$Count`:$Txt"

    # CREATOR OWNER access (recommend replacing with group-based access, or with explicit user access for a home folder.)
    $FoldersWithCreatorOwner = ($UserPermissions | ? { $_.Name -match 'CREATOR OWNER' }).Group.NtfsAccessControlEntries.Path | Sort -Unique
    $Count = ($FoldersWithCreatorOwner | Measure-Object).Count
    if ($Count -gt 0) {
        $IssuesDetected = $true
        $Txt = "folders with 'CREATOR OWNER' ACEs: $($FoldersWithCreatorOwner -join "`r`n")"
    } else {
        $Txt = 'OK'
    }
    Write-Verbose "$Count`:$Txt"

    [PSCustomObject]@{
        IssueDetected                = $IssuesDetected
        FoldersWithBrokenInheritance = $FoldersWithBrokenInheritance
        NonCompliantGroups           = $NonCompliantGroups
        UserACEs                     = $UserACEs
        SIDsToCleanup                = $SIDsToCleanup
        FoldersWithCreatorOwner      = $FoldersWithCreatorOwner
    }
}
function Remove-DuplicatesAcrossIgnoredDomains {

    param (

        [Parameter(ValueFromPipeline)]
        $UserPermission,

        [string[]]$DomainToIgnore

    )

    begin {
        $KnownUsers = [hashtable]::Synchronized(@{})
    }
    process {
        
        ForEach ($ThisUser in $UserPermission) {
            
            $ShortName = $ThisUser.Name
            ForEach ($IgnoreThisDomain in $DomainToIgnore) {
                $ShortName = $ShortName -replace $IgnoreThisDomain,''
            }

            if ($null -eq $KnownUsers[$ShortName]) {
                $KnownUsers[$ShortName] = [pscustomobject]@{
                    'Name' = $ShortName
                    'Group' = $ThisUser.Group
                }
            }
            else {
                $KnownUsers[$ShortName] = [pscustomobject]@{
                    'Name' = $ShortName
                    'Group' = $KnownUsers[$ShortName].Group + $ThisUser.Group
                }
            }
        }

    }
    end {
        $KnownUsers.Values | Sort-Object -Property Name
    }

}
$ScriptFiles = Get-ChildItem -Path "$PSScriptRoot\*.ps1" -Recurse

# Dot source any functions
ForEach ($ThisScript in $ScriptFiles) {
    # Dot source the function
    . $($ThisScript.FullName)
}

# Add any custom C# classes as usable (exported) types
$CSharpFiles = Get-ChildItem -Path "$PSScriptRoot\*.cs"
ForEach ($ThisFile in $CSharpFiles) {
    Add-Type -Path $ThisFile.FullName -ErrorAction Stop
}

# Export any public functions
$PublicScriptFiles = $ScriptFiles | Where-Object -FilterScript {
    ($_.PSParentPath | Split-Path -Leaf) -eq 'public'
}
$publicFunctions = $PublicScriptFiles.BaseName

Export-ModuleMember -Function @('Format-FolderPermission','Format-SecurityPrincipal','Get-FolderTarget','Get-NtfsAccessRule','Get-Subfolder','New-NtfsAclIssueReport','Remove-DuplicatesAcrossIgnoredDomains')















