
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
function Expand-AccountPermission {
    <#
        .SYNOPSIS
        Convert an object representing a security principal into a collection of objects respresenting the access control entries for that principal
        .DESCRIPTION
        Convert an object from Format-SecurityPrincipal (one object per principal, containing nested access entries) into flat objects (one per access entry per account)
        .INPUTS
        [pscustomobject]$AccountPermission
        .OUTPUTS
        [pscustomobject] One object per access control entry per account
        .EXAMPLE
        (Get-Acl).Access |
        Group-Object -Property IdentityReference |
        Expand-IdentityReference |
        Format-SecurityPrincipal |
        Expand-AccountPermission

        Incomplete example but it shows the chain of functions to generate the expected input for this
    #>
    param (
        # Object that was output from Format-SecurityPrincipal
        $AccountPermission
    )
    ForEach ($Account in $AccountPermission) {

        $PropertiesToExclude = @(
            'NativeObject',
            'NtfsAccessControlEntries',
            'Group'
        )
        $Props = @{}

        $AccountNoteProperties = $Account |
        Get-Member -MemberType Property, CodeProperty, ScriptProperty, NoteProperty |
        Where-Object -Property Name -NotIn $PropertiesToExclude

        ForEach ($ThisProperty in $AccountNoteProperties) {
            if ($null -eq $Props[$ThisProperty.Name]) {
                $Value = $Account.$($ThisProperty.Name)

                if ($null -ne $Value) {
                    # We wrap this in an expression and use output redirection to supress this error:
                    # The following exception occurred while retrieving member "GetType": "Not implemented"
                    [string]$Type = & { $Value.GetType().FullName } 2>$null
                } else {
                    [string]$Type = $null
                }

                switch ($Type) {
                    'System.DirectoryServices.PropertyCollection' {
                        ForEach ($ThisAccountProperty in $Account.Properties.Keys) {
                            $Props[$ThisAccountProperty] = ConvertFrom-PropertyValueCollectionToString -PropertyValueCollection $Account.Properties[$ThisAccountProperty]
                        }
                        $Props[$ThisProperty.Name] = "Converted to properties prefixed with AccountProperty"
                    }
                    'System.DirectoryServices.PropertyValueCollection' {
                        $Props[$ThisProperty.Name] = ConvertFrom-PropertyValueCollectionToString -PropertyValueCollection $Value
                    }
                    default {
                        <#
                            By default we will just let most types get cast as a string
                            Includes but not limited to:
                                $null (because GetType is not implemented)
                                System.String
                                System.Boolean
                                System.Byte[]
                        #>
                        $Props[$ThisProperty.Name] = "$Value"
                    }
                }
            }
        }

        ForEach ($ACE in $Account.NtfsAccessControlEntries) {

            $ACENoteProperties = $ACE |
            Get-Member -MemberType Property, CodeProperty, ScriptProperty, NoteProperty

            ForEach ($ThisProperty in $ACENoteProperties) {
                $Props["ACE$($ThisProperty.Name)"] = [string]$ACE.$($ThisProperty.Name)
            }

            [pscustomobject]$Props
        }
    }
}
function Expand-Acl {
    <#
        .SYNOPSIS
        Expand an Access Control List into its constituent Access Control Entries
        .DESCRIPTION
        Enumerate the members of the Access property of the $InputObject parameter (which is an AuthorizationRuleCollection or similar)
        Append the original ACL to each member as a SourceAccessList property
        Then return each member
        .INPUTS
        [PSObject]$InputObject
        Expected:
        [System.Security.AccessControl.DirectorySecurity]$InputObject from Get-Acl
        or
        [System.Security.AccessControl.FileSecurity]$InputObject from Get-Acl
        .OUTPUTS
        [PSCustomObject]
        .EXAMPLE
        Get-Acl |
        Expand-Acl

        Use Get-Acl from the Microsoft.PowerShell.Security module as the source of the access list
        This works in either Windows Powershell or in Powershell
        Get-Acl does not support long paths (>256 characters)
        That was why I originally used the .Net Framework method
    #>
    param (

        # Access Control List whose Access Control Entries to return
        # Expects [System.Security.AccessControl.FileSecurity] objects from Get-Acl or otherwise
        # Expects [System.Security.AccessControl.DirectorySecurity] objects from Get-Acl or otherwise
        # Accepts any [PSObject] as long as it has an 'Access' property that contains a collection
        [Parameter(
            ValueFromPipeline
        )]
        [PSObject]$InputObject

    )

    process {

        ForEach ($ThisInputObject in $InputObject) {

            $ObjectProperties = @{
                SourceAccessList = $ThisInputObject
            }
            $AllACEs = $ThisInputObject.Access
            $AceProperties = (Get-Member -InputObject $AllACEs[0] -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name
            ForEach ($ThisACE in $AllACEs) {
                ForEach ($ThisProperty in $AceProperties) {
                    $ObjectProperties["$Prefix$ThisProperty"] = $ThisACE.$ThisProperty
                }
                [PSCustomObject]$ObjectProperties
            }

        }

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
                    Folder                   = $ThisACE.SourceAccessList.Path
                    FolderInheritanceEnabled = !($ThisACE.SourceAccessList.AreAccessRulesProtected)
                    Access                   = "$($ThisACE.AccessControlType) $FileSystemRights $Scope"
                    Account                  = $ThisUser.Name
                    Name                     = $Name
                    Department               = $Dept
                    Title                    = $Title
                    IdentityReference        = $IdentityReference
                    AccessControlEntry       = $ThisACE
                    SchemaClassName          = $ThisUser.Group.SchemaClassName | Select-Object -First 1
                }

            }

        }

    }

    end {
        Write-Progress -Activity ("Total User Permissions: " + $UserPermission.Count) -Completed
    }

}
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


    }

}
function Get-FolderAce {
    <#
    .SYNOPSIS
    Alternative to Get-Acl designed to be as lightweight as possible
    .DESCRIPTION
    Returns an object for each access control entry instead of a single object for the ACL
    Excludes inherited permissions by default but allows them to be included with the -IncludeInherited switch parameter
    .INPUTS
    [System.String]$LiteralPath
    .OUTPUTS
    [PSCustomObject]
    .NOTES
    Currently only supports Directories but could easily be copied to support files, or Registry or AD providers
    #>

    [CmdletBinding(
        SupportsShouldProcess = $false,
        ConfirmImpact = "Low"
    )]

    param(

        # Path to the directory whose permissions to get
        [string]$LiteralPath,

        # Include inherited Access Control Entries in the results
        [Switch]$IncludeInherited,

        # Include all sections except Audit because it requires admin rights if run on the local system and we want to avoid that requirement
        [System.Security.AccessControl.AccessControlSections]$Sections = ([System.Security.AccessControl.AccessControlSections]::Access -bor
            [System.Security.AccessControl.AccessControlSections]::Owner -bor
            [System.Security.AccessControl.AccessControlSections]::Group),

        # Include non-inherited Access Control Entries in the results
        [bool]$IncludeExplicitRules = $true,

        # Type of IdentityReference to return in each ACE
        [System.Type]$AccountType = [System.Security.Principal.SecurityIdentifier]

    )

    $DirectorySecurity = & { [System.Security.AccessControl.DirectorySecurity]::new(
            $LiteralPath,
            $Sections
        ) } 2>$null

    if (-not $DirectorySecurity) {
        continue
    }

    $AclProperties = @{}
    $AclPropertyNames = (Get-Member -InputObject $DirectorySecurity -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name
    ForEach ($ThisProperty in $AclPropertyNames) {
        $AclProperties[$ThisProperty] = $DirectorySecurity.$ThisProperty
    }
    $AclProperties['Path'] = $LiteralPath
    $AccessRules = $DirectorySecurity.GetAccessRules($IncludeExplicitRules, $IncludeInherited, $AccountType)
    $ACEPropertyNames = (Get-Member -InputObject $AccessRules[0] -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name
    ForEach ($ThisAccessRule in $AccessRules) {
        $ACEProperties = @{
            SourceAccessList = [PSCustomObject]$AclProperties
        }
        ForEach ($ThisProperty in $ACEPropertyNames) {
            $ACEProperties[$ThisProperty] = $ThisAccessRule.$ThisProperty
        }
        [pscustomobject]$ACEProperties
    }

    $ACEProperties['IsInherited'] = $false
    $ACEProperties['IdentityReference'] = $DirectorySecurity.Owner
    $ACEProperties['FileSystemRights'] = [System.Security.AccessControl.FileSystemRights]::FullControl
    $ACEProperties['InheritanceFlags'] = [System.Security.AccessControl.InheritanceFlags]::None
    $ACEProperties['PropagationFlags'] = [System.Security.AccessControl.PropagationFlags]::None
    $ACEProperties['AccessControlType'] = [System.Security.AccessControl.AccessControlType]::Allow

    #TODO: Output an object for the owner as well to represent that they have Full Control
    [PSCustomObject]$ACEProperties

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
            } else {
                #$DFSDetails = [NetApi32Dll]::NetDfsGetInfo($TargetPath) # Can't use this because it doesn't work if the provided path is a subfolder of a DFS folder
                $AllDfs = Get-NetDfsEnum -Verbose -FolderPath $TargetPath
                $DfsDetails = $AllDfs |
                Group-Object -Property DfsEntryPath |
                Where-Object -FilterScript { "$TargetPath" -like "$($_.Name)\*" } |
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
<#
# Dot source any functions
ForEach ($ThisScript in $ScriptFiles) {
    # Dot source the function
    . $($ThisScript.FullName)
}
#>
Export-ModuleMember -Function @('Expand-AccountPermission','Expand-Acl','Format-FolderPermission','Format-SecurityPrincipal','Get-FolderAce','Get-FolderTarget','Get-Subfolder','New-NtfsAclIssueReport','Remove-DuplicatesAcrossIgnoredDomains')


