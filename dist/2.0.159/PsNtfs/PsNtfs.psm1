
function GetDirectories {

    param (

        [Parameter(Mandatory)]
        [string]$TargetPath,

        [string]$SearchPattern = '*',

        [System.IO.SearchOption]$SearchOption = [System.IO.SearchOption]::AllDirectories,

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Debug',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$ThisHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages
    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    # Try to run the command as instructed
    Write-LogMsg @LogParams -Text "[System.IO.Directory]::GetDirectories('$TargetPath','$SearchPattern',[System.IO.SearchOption]::$SearchOption)"
    try {
        $result = [System.IO.Directory]::GetDirectories($TargetPath, $SearchPattern, $SearchOption)
        return $result
    }
    catch {
        $LogParams['Type'] = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat
        Write-LogMsg @LogParams -Text $_.Exception.Message.Replace('Exception calling "GetDirectories" with "3" argument(s): ', '').Replace('"', '')
        $LogParams['Type'] = $DebugOutputStream
    }

    # Sometimes access is denied to a single buried subdirectory, so we will try searching the top directory only and then recursing through results one at a time
    Write-LogMsg @LogParams -Text "[System.IO.Directory]::GetDirectories('$TargetPath','$SearchPattern',[System.IO.SearchOption]::TopDirectoryOnly)"
    try {
        $result = [System.IO.Directory]::GetDirectories($TargetPath, $SearchPattern, [System.IO.SearchOption]::TopDirectoryOnly)
    }
    catch {
        $LogParams['Type'] = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat
        Write-LogMsg @LogParams -Text $_.Exception.Message.Replace('Exception calling "GetDirectories" with "3" argument(s): ', '').Replace('"', '')
        return
    }

    $GetSubfolderParams = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $ThisHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
        SearchOption      = $SearchOption
        SearchPattern     = $SearchPattern
    }

    ForEach ($Child in $result) {
        Write-LogMsg @LogParams -Text "[System.IO.Directory]::GetDirectories('$Child','$SearchPattern',[System.IO.SearchOption]::$SearchOption)"
        GetDirectories -TargetPath $Child @GetSubfolderParams
    }

}
function ConvertTo-SimpleProperty {
    param (
        $InputObject,

        [string]$Property,

        [hashtable]$PropertyDictionary = @{},

        [string]$Prefix
    )

    $Value = $InputObject.$Property

    [string]$Type = $null
    if ($Value) {
        # Ensure the GetType method exists to avoid this error:
        # The following exception occurred while retrieving member "GetType": "Not implemented"
        if (Get-Member -InputObject $Value -Name GetType) {
            [string]$Type = $Value.GetType().FullName
        }
        else {
            # The only scenario we've encountered where the GetType() method does not exist is DirectoryEntry objects from the WinNT provider
            # Force the type to 'System.DirectoryServices.DirectoryEntry'
            [string]$Type = 'System.DirectoryServices.DirectoryEntry'
        }
    }

    switch ($Type) {
        'System.DirectoryServices.DirectoryEntry' {
            $PropertyDictionary["$Prefix$Property"] = ConvertFrom-DirectoryEntry -DirectoryEntry $Value
        }
        'System.DirectoryServices.PropertyCollection' {
            $ThisObject = @{}
            <#
            This error was happening when:
                A DirectoryEntry has a SchemaEntry property
                which is a DirectoryEntry
                which has a Properties property
                which is a System.DirectoryServices.PropertyCollection
                but throws the following error to the Success stream (not the error stream, so it is hard to catch):
                    PS C:\Users\Test> $ThisDirectoryEntry.Properties
                    format-default : The entry properties cannot be enumerated. Consider using the entry schema to determine what properties are available.
                        + CategoryInfo          : NotSpecified: (:) [format-default], NotSupportedException
                        + FullyQualifiedErrorId : System.NotSupportedException,Microsoft.PowerShell.Commands.FormatDefaultCommand
            To catch the error we will redirect the Success Stream to the Error Stream
            Then if the Exception type matches, we will use the continue keyword to break out of the current switch statement
            #>
            $KeyCount = $Value.Keys.$KeyCount
            if (-not $KeyCount -gt 0) {
                continue
            }

            ForEach ($ThisProperty in $Value.Keys) {
                $ThisPropertyString = ConvertFrom-PropertyValueCollectionToString -PropertyValueCollection $Value[$ThisProperty]
                $ThisObject[$ThisProperty] = $ThisPropertyString

                # This copies the properties up to the top level.
                # Want to remove this later
                # The nested pscustomobject accomplishes the goal of removing hashtables and PropertyValueCollections and PropertyCollections
                # But I may have existing functionality expecting these properties so I am not yet ready to remove this
                # When I am, I should move this code into a ConvertFrom-PropertyCollection function in the Adsi module
                $PropertyDictionary["$Prefix$ThisProperty"] = $ThisPropertyString

            }
            $PropertyDictionary["$Prefix$Property"] = [PSCustomObject]$ThisObject
            continue
        }
        'System.DirectoryServices.PropertyValueCollection' {
            $PropertyDictionary["$Prefix$Property"] = ConvertFrom-PropertyValueCollectionToString -PropertyValueCollection $Value
            continue
        }
        'System.Object[]' {
            $PropertyDictionary["$Prefix$Property"] = $Value
            continue
        }
        'System.Object' {
            $PropertyDictionary["$Prefix$Property"] = $Value
            continue
        }
        'System.DirectoryServices.SearchResult' {
            $PropertyDictionary["$Prefix$Property"] = ConvertFrom-SearchResult -SearchResult $Value
            continue
        }
        'System.DirectoryServices.ResultPropertyCollection' {
            $ThisObject = @{}

            ForEach ($ThisProperty in $Value.Keys) {
                $ThisPropertyString = ConvertFrom-ResultPropertyValueCollectionToString -ResultPropertyValueCollection $Value[$ThisProperty]
                $ThisObject[$ThisProperty] = $ThisPropertyString

                # This copies the properties up to the top level.
                # Want to remove this later
                # The nested pscustomobject accomplishes the goal of removing hashtables and PropertyValueCollections and PropertyCollections
                # But I may have existing functionality expecting these properties so I am not yet ready to remove this
                # When I am, I should move this code into a ConvertFrom-PropertyCollection function in the Adsi module
                $PropertyDictionary["$Prefix$ThisProperty"] = $ThisPropertyString

            }
            $PropertyDictionary["$Prefix$Property"] = [PSCustomObject]$ThisObject
            continue
        }
        'System.DirectoryServices.ResultPropertyValueCollection' {
            $PropertyDictionary["$Prefix$Property"] = ConvertFrom-ResultPropertyValueCollectionToString -ResultPropertyValueCollection $Value
            continue
        }
        'System.Management.Automation.PSCustomObject' {
            $PropertyDictionary["$Prefix$Property"] = $Value
            continue
        }
        'System.Collections.Hashtable' {
            $PropertyDictionary["$Prefix$Property"] = [PSCustomObject]$Value
            continue
        }
        'System.Byte[]' {
            $PropertyDictionary["$Prefix$Property"] = ConvertTo-DecStringRepresentation -ByteArray $Value
        }
        default {
            <#
                By default we will just let most types get cast as a string
                Includes but not limited to:
                    $null (because GetType is not implemented)
                    System.String
                    System.Boolean
            #>
            $PropertyDictionary["$Prefix$Property"] = "$Value"
            continue
        }
    }

    return $PropertyDictionary
}
function Expand-AccountPermission {
    <#
        .SYNOPSIS
        Expand an object representing a security principal and into a collection of objects respresenting the access control entries for that principal
        .DESCRIPTION
        Expand an object from Format-SecurityPrincipal (one object per principal, containing nested access entries) into flat objects (one per access entry per account)
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
        $AccountPermission,

        # Properties to exclude from the output because they cause problems or are unnecessary/redundant/undesirable
        # All properties listed on a single line to workaround a bug in PlatyPS when building MAML help
        # (error is 'Invalid yaml: expected simple key-value pairs')
        # Caused by multi-line default parameter values in the markdown
        [string[]]$PropertiesToExclude = @('NativeObject', 'NtfsAccessControlEntries', 'Group')
    )
    ForEach ($Account in $AccountPermission) {

        $Props = @{}

        $AccountNoteProperties = $Account |
        Get-Member -MemberType Property, CodeProperty, ScriptProperty, NoteProperty |
        Where-Object -Property Name -NotIn $PropertiesToExclude

        ForEach ($ThisProperty in $AccountNoteProperties) {
            if ($null -eq $Props[$ThisProperty.Name]) {
                $Props = ConvertTo-SimpleProperty -InputObject $Account -Property $ThisProperty.Name -PropertyDictionary $Props
            }
        }

        ForEach ($ACE in $Account.NtfsAccessControlEntries) {

            $ACENoteProperties = $ACE |
            Get-Member -MemberType Property, CodeProperty, ScriptProperty, NoteProperty

            ForEach ($ThisProperty in $ACENoteProperties) {
                $Props = ConvertTo-SimpleProperty -InputObject $ACE -Property $ThisProperty.Name -PropertyDictionary $Props -Prefix "ACE"
            }

            $Props['SourceAclPath'] = $ACE.SourceAccessList.Path

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
function Find-ServerNameInPath {
    <#
    .SYNOPSIS
    Parse a literal path to find its server
    .DESCRIPTION
    Currently only supports local file paths or UNC paths
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    [System.String] representing the name of the server that was extracted from the path
    .EXAMPLE
    Find-ServerNameInPath -LiteralPath 'C:\Test'

    Return the hostname of the local computer because a local filepath was used
    .EXAMPLE
    Find-ServerNameInPath -LiteralPath '\\server123\Test\'

    Return server123 because a UNC path for a folder shared on server123 was used
#>
    [OutputType([System.String])]
    param (
        [string]$LiteralPath,

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName)
    )
    if ($LiteralPath[1] -eq '\') {
        #UNC
        $SkippedFirstTwoChars = $LiteralPath.Substring(2, $LiteralPath.Length - 2)
        $NextSlashIndex = $SkippedFirstTwoChars.IndexOf('\')
        $SkippedFirstTwoChars.Substring(0, $NextSlashIndex).Replace('?', $ThisFqdn)
    }
    else {
        #Local
        $ThisFqdn
    }

}
function Format-SecurityPrincipal {

    # Format Security Principals (distinguish group members from principals directly listed in the NTFS DACLs)
    # The IdentityReference property will be null for any principals directly listed in the NTFS DACLs

    param (

        # Security Principals received from Expand-IdentityReference in the Adsi module
        [string]$ResolvedID,

        # Thread-safe hashtable to use for caching directory entries and avoiding duplicate directory queries
        [hashtable]$PrincipalsByResolvedID = ([hashtable]::Synchronized(@{}))

    )

    # Get any existing properties for inclusion later
    $InputProperties = (Get-Member -InputObject $PrincipalsByResolvedID.Values[0] -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

    $ThisPrincipal = $PrincipalsByResolvedID[$ResolvedID]

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
function Format-SecurityPrincipalMember {
    param ([object[]]$InputObject)

    ForEach ($ThisObject in $InputObject) {

        # Include specific desired properties
        $OutputProperties = @{
            User                     = Format-SecurityPrincipalMemberUser -InputObject $ThisObject
            IdentityReference        = @($ThisObject.Group.IdentityReferenceResolved)[0]
            NtfsAccessControlEntries = $ThisObject.Group
            ObjectType               = $ThisObject.SchemaClassName
        }

        # Include any existing properties
        $InputProperties = (Get-Member -InputObject $InputObject -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

        ForEach ($ThisProperty in $InputProperties) {
            $OutputProperties[$ThisProperty] = $ThisObject.$ThisProperty
        }

        [PSCustomObject]$OutputProperties

    }
}
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
function Format-SecurityPrincipalName {
    param ([object]$InputObject)
    if ($InputObject.DirectoryEntry.Properties) {
        $ThisName = $InputObject.DirectoryEntry.Properties['name']
    }
    if ("$ThisName" -eq '') {
        $InputObject.Name -replace [regex]::Escape("$($InputObject.DomainNetBios)\"), ''
    }
    else {
        $ThisName
    }
}
function Format-SecurityPrincipalUser {
    param ([object]$InputObject)

    if ($InputObject.Properties) {
        $sAmAccountName = $InputObject.Properties['sAmAccountName']
    }
    if ("$sAmAccountName" -eq '') {
        $InputObject.Name
    }
    else {
        $sAmAccountName
    }
}
function Get-DirectorySecurity {
    <#
    .SYNOPSIS
    Alternative to Get-Acl designed to be as lightweight and flexible as possible
        Lightweight: Does not return the Path property like Get-Acl does
        Flexible how?  Was it long paths?  DFS?  Can't remember what didn't work with Get-Acl
    TEMP NOTE: Get-DirectorySecurity combined with Get-FileSystemAccessRule is basically what Get-FolderACE does
    .DESCRIPTION
    Returns an object for each access control entry instead of a single object for the ACL
    Excludes inherited permissions by default but allows them to be included with the -IncludeInherited switch parameter
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    [PSCustomObject]
    .NOTES
    Currently only supports Directories but could easily be copied to support files, or Registry or AD providers
    #>

    param(

        # Path to the directory whose permissions to get
        [string]$LiteralPath,

        # Include all sections except Audit because it requires admin rights if run on the local system and we want to avoid that requirement
        [System.Security.AccessControl.AccessControlSections]$Sections = (
            [System.Security.AccessControl.AccessControlSections]::Access -bor
            [System.Security.AccessControl.AccessControlSections]::Owner -bor
            [System.Security.AccessControl.AccessControlSections]::Group)

    )

    [System.Security.AccessControl.DirectorySecurity]::new(
        $LiteralPath,
        $Sections
    )

}
function Get-FileSystemAccessRule {
    <#
    .SYNOPSIS
    Alternative to Get-Acl designed to be as lightweight and flexible as possible
    TEMP NOTE: Get-DirectorySecurity combined with Get-FileSystemAccessRule is basically what Get-FolderACE does
    .DESCRIPTION
    Returns an object for each access control entry instead of a single object for the ACL
    Excludes inherited permissions by default but allows them to be included with the -IncludeInherited switch parameter
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    [PSCustomObject]
    .NOTES
    Currently only supports Directories but could easily be copied to support files, or Registry or AD providers
    #>

    param(

        # Discretionary Access List whose FileSystemAccessRules to return
        [System.Security.AccessControl.DirectorySecurity]$DirectorySecurity,

        # Include inherited Access Control Entries in the results
        [Switch]$IncludeInherited,

        # Include non-inherited Access Control Entries in the results
        [bool]$IncludeExplicitRules = $true,

        # Type of IdentityReference to return in each ACE
        [System.Type]$AccountType = [System.Security.Principal.SecurityIdentifier],

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Silent',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$TodaysHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages

    )

    $AccessRules = $DirectorySecurity.GetAccessRules($IncludeExplicitRules, $IncludeInherited, $AccountType)
    if ($AccessRules.Count -lt 1) {
        Write-LogMsg @LogParams -Text "# Found no matching access rules for '$LiteralPath'"
        return
    }

    $ACEPropertyNames = (Get-Member -InputObject $AccessRules[0] -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name
    ForEach ($ThisAccessRule in $AccessRules) {
        $ACEProperties = @{
            SourceAccessList = $SourceAccessList
            Source           = 'Discretionary Access List'
        }
        ForEach ($ThisProperty in $ACEPropertyNames) {
            $ACEProperties[$ThisProperty] = $ThisAccessRule.$ThisProperty
        }
        [PSCustomObject]$ACEProperties
    }

    <#
    The creator of a folder is the Owner
    Unless S-1-3-4 (Owner Rights) is in the DACL, the Owner is implicitly granted two standard access rights defined in WinNT.h of the Win32 API:
      READ_CONTROL: The right to read the information in the object's security descriptor, not including the information in the system access control list (SACL).
      WRITE_DAC: The right to modify the discretionary access control list (DACL) in the object's security descriptor.
    Output an object for the Owner as well to represent that they have Full Control
    #>
    [PSCustomObject]@{
        SourceAccessList  = $SourceAccessList
        Source            = 'Ownership'
        IsInherited       = $false
        IdentityReference = $DirectorySecurity.Owner -replace '^O:', ''
        FileSystemRights  = [System.Security.AccessControl.FileSystemRights]::FullControl
        InheritanceFlags  = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
        PropagationFlags  = [System.Security.AccessControl.PropagationFlags]::None
        AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow
    }

}
function Get-FolderAce {
    <#
    .SYNOPSIS
    Alternative to Get-Acl designed to be as lightweight and flexible as possible
        Lightweight: Does not return the Path property like Get-Acl does
        Flexible how?  Was it long paths?  DFS?  Can't remember what didn't work with Get-Acl
    .DESCRIPTION
    Returns an object for each access control entry instead of a single object for the ACL
    Excludes inherited permissions by default but allows them to be included with the -IncludeInherited switch parameter
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    [PSCustomObject]
    .NOTES
    Currently only supports Directories but could easily be copied to support files, or Registry or AD providers
    #>

    param(

        # Path to the directory whose permissions to get
        [string]$LiteralPath,

        # Include inherited Access Control Entries in the results
        [Switch]$IncludeInherited,

        # Include all sections except Audit because it requires admin rights if run on the local system and we want to avoid that requirement
        [System.Security.AccessControl.AccessControlSections]$Sections = (
            [System.Security.AccessControl.AccessControlSections]::Access -bor
            [System.Security.AccessControl.AccessControlSections]::Owner -bor
            [System.Security.AccessControl.AccessControlSections]::Group),

        # Include non-inherited Access Control Entries in the results
        [bool]$IncludeExplicitRules = $true,

        # Type of IdentityReference to return in each ACE
        [System.Type]$AccountType = [System.Security.Principal.SecurityIdentifier],

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Debug',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$ThisHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Thread-safe cache of items and their owners
        [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]$OwnerCache = [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]::new(),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages,

        # Cache of access control lists keyed by path
        [hashtable]$ACLsByPath = [hashtable]::Synchronized(@{})

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    Write-LogMsg @LogParams -Text "[System.Security.AccessControl.DirectorySecurity]::new('$LiteralPath', '$Sections')"
    $DirectorySecurity = & { [System.Security.AccessControl.DirectorySecurity]::new(
            $LiteralPath,
            $Sections
        )
    } 2>$null

    if ($null -eq $DirectorySecurity) {
        $LogParams['Type'] = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat
        Write-LogMsg @LogParams -Text "# Found no ACL for '$LiteralPath'"
        $LogParams['Type'] = $DebugOutputStream
        return
    }

    <#
    Get-Acl would have already populated the Path property on the Access List, but [System.Security.AccessControl.DirectorySecurity] has a null Path property instead
    Creating new PSCustomObjects with all the original properties then manually setting the Path is faster than using Add-Member
    #>
    $AclProperties = @{}
    $AclPropertyNames = (Get-Member -InputObject $DirectorySecurity -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

    ForEach ($ThisProperty in $AclPropertyNames) {
        $AclProperties[$ThisProperty] = $DirectorySecurity.$ThisProperty
    }

    $AclProperties['Path'] = $LiteralPath

    <#
    The creator of a folder is the Owner
    Unless S-1-3-4 (Owner Rights) is in the DACL, the Owner is implicitly granted two standard access rights defined in WinNT.h of the Win32 API:
      READ_CONTROL: The right to read the information in the object's security descriptor, not including the information in the system access control list (SACL).
      WRITE_DAC: The right to modify the discretionary access control list (DACL) in the object's security descriptor.

    Previously the .Owner property was already populated with the NTAccount name of the Owner,
    but for some reason this stopped being true and now I have to call the GetOwner method.
    This at least lets us specify the AccountType to match what is used when calling the GetAccessRules method.
    #>
    Write-LogMsg @LogParams -Text "[System.Security.AccessControl.DirectorySecurity]::new('$LiteralPath', '$Sections').GetOwner([$AccountType])"
    $AclProperties['Owner'] = $DirectorySecurity.GetOwner($AccountType).Value

    Write-LogMsg @LogParams -Text "[System.Security.AccessControl.DirectorySecurity]::new('$LiteralPath', '$Sections').GetAccessRules(`$$IncludeExplicitRules, `$$IncludeInherited, [$AccountType])"
    $AclProperties['Access'] = $DirectorySecurity.GetAccessRules($IncludeExplicitRules, $IncludeInherited, $AccountType)
    pause
    $ACLsByPath[$LiteralPath] = [PSCustomObject]$AclProperties

    <#
    $ACL = [PSCustomObject]$AclProperties
    # Update the OwnerCache with the Source Access List, so that Get-OwnerAce can output an object for the Owner to represent that they have Full Control
    $OwnerCache[$LiteralPath] = $ACL

    $ACEPropertyNames = (Get-Member -InputObject $AccessRules[0] -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

    ForEach ($ThisAccessRule in $AccessRules) {
        $ACEProperties = @{
            SourceAccessList = $ACL
            Source           = 'Discretionary Access Control List'
        }
        ForEach ($ThisProperty in $ACEPropertyNames) {
            $ACEProperties[$ThisProperty] = $ThisAccessRule.$ThisProperty
        }
        [PSCustomObject]$ACEProperties
    }
    #>

}
function Get-OwnerAce {

    param (

        # Path to the parent item whose owners to export
        [string]$Item,

        # Thread-safe cache of items and their owners
        [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]$OwnerCache = [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]::new(),

        # Cache of access control lists keyed by path
        [hashtable]$ACLsByPath = [hashtable]::Synchronized(@{})
    )

    # ToDo - Confirm the logic for selecting this to make sure it accurately represents NTFS ownership behavior, then replace this comment with that confirmation and an explanation
    $InheritanceFlags = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit

    $SourceAccessList = $OwnerCache[$Item]
    $ThisParent = $Item.Substring(0, [math]::Max($Item.LastIndexOf('\'), 0)) # ToDo - This method of finding the parent path is faster than Split-Path -Parent but it has a dependency on a folder path not containing a trailing \ which is not currently what I am seeing in my simple test but should be supported in the future (possibly default)
    if ($SourceAccessList.Owner -ne $OwnerCache[$ThisParent].Owner) {
        [PSCustomObject]@{
            SourceAccessList  = $SourceAccessList
            IdentityReference = $SourceAccessList.Owner
            AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow
            FileSystemRights  = [System.Security.AccessControl.FileSystemRights]::FullControl
            InheritanceFlags  = $InheritanceFlags
            IsInherited       = $false
            PropagationFlags  = [System.Security.AccessControl.PropagationFlags]::None
            Source            = 'Ownership'
        }

    }

}
function Get-ServerFromFilePath {
    param (
        [string]$FilePath,

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName)
    )

    if ($FilePath[1] -eq '\') {
        #UNC
        $SkippedFirstTwoChars = $FilePath.Substring(2, $FilePath.Length - 2)
        $NextSlashIndex = $SkippedFirstTwoChars.IndexOf('\')
        $SkippedFirstTwoChars.Substring(0, $NextSlashIndex)
    }
    else {
        #Local
        $ThisFqdn
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
        [int]$FolderRecursionDepth = -1,

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Debug',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$ThisHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [hashtable]$LogMsgCache = $Global:LogMessages

    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $GetSubfolderParams = @{
        LogMsgCache       = $LogMsgCache
        ThisHostname      = $ThisHostname
        DebugOutputStream = $DebugOutputStream
        WhoAmI            = $WhoAmI
    }

    if ($FolderRecursionDepth -eq -1) {
        $DepthString = '∞'
    }
    else {
        $DepthString = $FolderRecursionDepth
    }

    if ($Host.Version.Major -gt 2) {

        switch ($FolderRecursionDepth) {
            -1 {
                GetDirectories -TargetPath $TargetPath -SearchOption ([System.IO.SearchOption]::AllDirectories) @GetSubfolderParams
            }
            0 {}
            1 {
                GetDirectories -TargetPath $TargetPath -SearchOption ([System.IO.SearchOption]::TopDirectoryOnly) @GetSubfolderParams
            }
            Default {
                $FolderRecursionDepth = $FolderRecursionDepth - 1
                Write-LogMsg @LogParams -Text "Get-ChildItem '$TargetPath' -Force -Name -Recurse -Attributes Directory -Depth $FolderRecursionDepth"
                (Get-ChildItem $TargetPath -Force -Recurse -Attributes Directory -Depth $FolderRecursionDepth).FullName
            }
        }

    }
    else {

        Write-LogMsg @LogParams -Text "Get-ChildItem '$TargetPath' -Recurse"
        Get-ChildItem $TargetPath -Recurse | Where-Object -FilterScript { $_.PSIsContainer } | ForEach-Object { $_.FullName }

    }

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
        [scriptblock]$GroupNameRule = { $true },

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

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = 'Verbose'
        LogMsgCache  = $LogMsgCache
        WhoAmI       = $WhoAmI
    }

    $IssuesDetected = $false

    # List of folders with broken inheritance (recommend moving to higher level to avoid breaking inheritance.  Deny entries are a less desirable alternative)
    $FoldersWithBrokenInheritance = $FolderPermissions |
    Select-Object -Skip 1 |
    Where-Object -FilterScript {
        @($_.Group.FolderInheritanceEnabled)[0] -eq $false -and
                (($_.Name -replace ([regex]::Escape($TargetPath)), '' -split '\\') | Measure-Object).Count -ne 2
    }
    $Count = ($FoldersWithBrokenInheritance | Measure-Object).Count
    if ($Count -gt 0) {
        $IssuesDetected = $true
        $Txt = "folders with broken inheritance: $($FoldersWithBrokenInheritance.Name -join "`r`n")"
    }
    else {
        $Txt = 'OK'
    }
    Write-LogMsg @LogParams -Text "$Count $Txt"

    # List of ACEs for groups that do not match the specified naming convention
    # Invert the naming convention scriptblock (because we actually want to identify groups that do NOT follow the convention)
    $ViolatesNamingConvention = [scriptblock]::Create("!($GroupNameRule)")
    $NonCompliantGroups = $SecurityPrincipals |
    Where-Object -FilterScript { $_.ObjectType -contains 'Group' } |
    Where-Object -FilterScript $ViolatesNamingConvention |
    Select-Object -ExpandProperty Group |
    ForEach-Object { "$($_.IdentityReference) on '$($_.Path)'" }

    $Count = ($NonCompliantGroups | Measure-Object).Count
    if ($Count -gt 0) {
        $IssuesDetected = $true
        $Txt = "groups that don't match naming convention: $($NonCompliantGroups -join "`r`n")"
    }
    else {
        $Txt = 'OK'
    }
    Write-LogMsg @LogParams -Text "$Count $Txt"

    # ACEs for users (recommend replacing with group-based access on any folder that is not a home folder)
    $UserACEs = $UserPermissions.Group |
    Where-Object -FilterScript {
        $_.ObjectType -contains 'User' -and
        $_.ACEIdentityReference -ne 'S-1-5-18' # The 'NT AUTHORITY\SYSTEM' account is part of default Windows file permissions and is out of scope
    } |
    ForEach-Object { "$($_.User) on '$($_.SourceAclPath)'" } |
    Sort-Object -Unique
    $Count = ($UserACEs | Measure-Object).Count
    if ($Count -gt 0) {
        $IssuesDetected = $true
        $Txt = "users with ACEs: $($UserACEs -join "`r`n")"
    }
    else {
        $Txt = 'OK'
    }
    Write-LogMsg @LogParams -Text "$Count $Txt"

    # ACEs for unresolvable SIDs (recommend removing these ACEs)
    $SIDsToCleanup = $UserPermissions.Group.NtfsAccessControlEntries |
    Where-Object -FilterScript { $_.IdentityReference -match 'S-\d+-\d+-\d+-\d+-\d+\-\d+\-\d+' } |
    ForEach-Object { "$($_.IdentityReference) on '$($_.Path)'" } |
    Sort-Object -Unique
    $Count = ($SIDsToCleanup | Measure-Object).Count
    if ($Count -gt 0) {
        $IssuesDetected = $true
        $Txt = "ACEs for unresolvable SIDs: $($SIDsToCleanup -join "`r`n")"
    }
    else {
        $Txt = 'OK'
    }
    Write-LogMsg @LogParams -Text "$Count $Txt"

    # CREATOR OWNER access (recommend replacing with group-based access, or with explicit user access for a home folder.)
    $FoldersWithCreatorOwner = ($UserPermissions | ? { $_.Name -match 'CREATOR OWNER' }).Group.NtfsAccessControlEntries.Path | Sort -Unique
    $Count = ($FoldersWithCreatorOwner | Measure-Object).Count
    if ($Count -gt 0) {
        $IssuesDetected = $true
        $Txt = "folders with 'CREATOR OWNER' ACEs: $($FoldersWithCreatorOwner -join "`r`n")"
    }
    else {
        $Txt = 'OK'
    }
    Write-LogMsg @LogParams -Text "$Count $Txt"

    [PSCustomObject]@{
        IssueDetected                = $IssuesDetected
        FoldersWithBrokenInheritance = $FoldersWithBrokenInheritance
        NonCompliantGroups           = $NonCompliantGroups
        UserACEs                     = $UserACEs
        SIDsToCleanup                = $SIDsToCleanup
        FoldersWithCreatorOwner      = $FoldersWithCreatorOwner
    }

}
<#
# Dot source any functions
ForEach ($ThisScript in $ScriptFiles) {
    # Dot source the function
    . $($ThisScript.FullName)
}
#>
Export-ModuleMember -Function @('ConvertTo-SimpleProperty','Expand-AccountPermission','Expand-Acl','Find-ServerNameInPath','Format-SecurityPrincipal','Format-SecurityPrincipalMember','Format-SecurityPrincipalMemberUser','Format-SecurityPrincipalName','Format-SecurityPrincipalUser','Get-DirectorySecurity','Get-FileSystemAccessRule','Get-FolderAce','Get-OwnerAce','Get-ServerFromFilePath','Get-Subfolder','New-NtfsAclIssueReport')






























































































































































