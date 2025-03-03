
function GetDirectories {

    param (

        [Parameter(Mandatory)]
        [string]$TargetPath,

        [string]$SearchPattern = '*',

        [System.IO.SearchOption]$SearchOption = [System.IO.SearchOption]::AllDirectories,

        # Hashtable of warning messages to avoid writing duplicate warnings when recursive calls error while retrying a folder
        [System.Collections.Specialized.OrderedDictionary]$WarningCache = [ordered]@{},

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    # Try to run the command as instructed
    Write-LogMsg -Text "[System.IO.Directory]::GetDirectories('$TargetPath','$SearchPattern',[System.IO.SearchOption]::$SearchOption)" -Cache $Cache

    try {

        $result = [System.IO.Directory]::GetDirectories($TargetPath, $SearchPattern, $SearchOption)
        return $result

    }
    catch {

        $WarningCache[$_.Exception.Message.Replace('Exception calling "GetDirectories" with "3" argument(s): ', '').Replace('"', '')] = $TargetPath

    }

    # Sometimes access is denied to a single buried subdirectory, so we will try searching the top directory only and then recursing through results one at a time
    Write-LogMsg -Text "[System.IO.Directory]::GetDirectories('$TargetPath','$SearchPattern',[System.IO.SearchOption]::TopDirectoryOnly)" -Cache $Cache

    try {

        $result = [System.IO.Directory]::GetDirectories($TargetPath, $SearchPattern, [System.IO.SearchOption]::TopDirectoryOnly)

    }
    catch {

        $ThisWarning = $_.Exception.Message.Replace('Exception calling "GetDirectories" with "3" argument(s): ', '').Replace('"', '')
        $WarningCache[$ThisWarning] = $TargetPath
        $Cache.Value['ErrorByItemPath_Enumeration'].Value[$TargetPath] = $ThisWarning

        # If this was not a recursive call to GetDirectories, write the warnings
        if (-not $PSBoundParameters.ContainsKey('WarningCache')) {

            $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat

            ForEach ($Warning in $WarningCache.Keys) {

                Write-LogMsg -Text $ThisWarning -Cache $Cache

            }
        }

        return

    }

    $GetSubfolderParams = @{
        Cache         = $Cache
        SearchOption  = $SearchOption
        SearchPattern = $SearchPattern
        WarningCache  = $WarningCache
    }

    ForEach ($Child in $result) {

        $Child
        Write-LogMsg -Text "[System.IO.Directory]::GetDirectories('$Child','$SearchPattern',[System.IO.SearchOption]::$SearchOption)" -Cache $Cache
        GetDirectories -TargetPath $Child @GetSubfolderParams

    }

    # If this was not a recursive call to GetDirectories, write the warnings
    if (-not $PSBoundParameters.ContainsKey('WarningCache')) {

        if ($WarningCache.Keys.Count -ge 1) {

            $StartingLogType = $Cache.Value['LogType'].Value
            $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat
            Write-LogMsg -Text "$($WarningCache.Keys.Count) errors while getting directories of '$TargetPath'.  See verbose log for details." -Cache $Cache
            $Cache.Value['LogType'].Value = 'Verbose' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat

            ForEach ($Warning in $WarningCache.Keys) {

                Write-LogMsg -Text $Warning -Cache $Cache

            }

            $Cache.Value['LogType'].Value = $StartingLogType

        }

    }

}
function ConvertTo-SimpleProperty {

    param (
        $InputObject,

        [string]$Property,

        [hashtable]$PropertyDictionary = @{},

        [string]$Prefix
    )

    <#
    An occurs when:
        A DirectoryEntry has a SchemaEntry property
        which is a DirectoryEntry
        which has a Properties property
        which is a System.DirectoryServices.PropertyCollection
        but throws the following error to the Success stream (not the error stream, so it is hard to catch):
            PS C:\Users\Test> $ThisDirectoryEntry.Properties
            format-default : The entry properties cannot be enumerated. Consider using the entry schema to determine what properties are available.
                + CategoryInfo          : NotSpecified: (:) [format-default], NotSupportedException
                + FullyQualifiedErrorId : System.NotSupportedException,Microsoft.PowerShell.Commands.FormatDefaultCommand
    To avoid the error we will inspect the key count in the PropertyCollection and abort if there are 0 keys.

    Steps to reproduce:
    PS C:\> $InputObject = [ADSI]"LDAP://ad.contoso.com/schema/user"
    PS C:\> $InputObject.Properties
    format-default: The entry properties cannot be enumerated. Consider using the entry schema to determine what properties are available.
    #>
    if ($Property -eq 'Properties') {
        if ( -not $InputObject.Properties.Keys.Count -gt 0 ) {
            return
        }
    }

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
            return

        }
        'System.DirectoryServices.PropertyValueCollection' {
            $PropertyDictionary["$Prefix$Property"] = ConvertFrom-PropertyValueCollectionToString -PropertyValueCollection $Value
            return
        }
        'System.Object[]' {
            $PropertyDictionary["$Prefix$Property"] = $Value
            return
        }
        'System.Object' {
            $PropertyDictionary["$Prefix$Property"] = $Value
            return
        }
        'System.DirectoryServices.SearchResult' {
            $PropertyDictionary["$Prefix$Property"] = ConvertFrom-SearchResult -SearchResult $Value
            return
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
            return
        }
        'System.DirectoryServices.ResultPropertyValueCollection' {
            $PropertyDictionary["$Prefix$Property"] = ConvertFrom-ResultPropertyValueCollectionToString -ResultPropertyValueCollection $Value
            return
        }
        'System.Management.Automation.PSCustomObject' {
            $PropertyDictionary["$Prefix$Property"] = $Value
            return
        }
        'System.Collections.Hashtable' {
            $PropertyDictionary["$Prefix$Property"] = [PSCustomObject]$Value
            return
        }
        'System.Byte[]' {
            $PropertyDictionary["$Prefix$Property"] = ConvertTo-DecStringRepresentation -ByteArray $Value
            return
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
            return

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

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    if ($LiteralPath[1] -eq '\') {
        #UNC
        $SkippedFirstTwoChars = $LiteralPath.Substring(2, $LiteralPath.Length - 2)
        $NextSlashIndex = $SkippedFirstTwoChars.IndexOf('\')
        $SkippedFirstTwoChars.Substring(0, $NextSlashIndex).Replace('?', $Cache.Value['ThisFqdn'].Value)
    }
    else {
        #Local
        $Cache.Value['ThisFqdn'].Value
    }

}
function Format-SecurityPrincipalMember {

    param (
        [object[]]$ResolvedID,
        [string]$ParentIdentityReference,
        [object[]]$Access,
        [hashtable]$PrincipalsByResolvedID = ([hashtable]::Synchronized(@{}))
    )

    ForEach ($ID in $ResolvedID) {

        $Principal = $PrincipalsByResolvedID[$ID]

        # Include specific desired properties
        $OutputProperties = @{
            Access                          = $Access
            ParentIdentityReferenceResolved = $ParentIdentityReference
        }

        if ($Principal.DirectoryEntry) {

            $InputProperties = (Get-Member -InputObject $Principal.DirectoryEntry -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

            ForEach ($ThisProperty in $InputProperties) {
                $OutputProperties[$ThisProperty] = $Principal.DirectoryEntry.$ThisProperty
            }

        }

        # Include any existing properties
        $InputProperties = (Get-Member -InputObject $Principal -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name

        ForEach ($ThisProperty in $InputProperties) {
            $OutputProperties[$ThisProperty] = $Principal.$ThisProperty
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
    .DESCRIPTION
    Returns an object for each access control entry instead of a single object for the ACL
    Excludes inherited permissions by default but allows them to be included with the -IncludeInherited switch parameter
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    [PSCustomObject]
    .NOTES
    Currently only supports Directories but could easily be copied to support files, or Registry or AD providers

    TODO: Performance Test Methods

        $test = 'c:\windows'
        [System.Security.AccessControl.AccessControlSections]$Sections = (
            [System.Security.AccessControl.AccessControlSections]::Access -bor
            [System.Security.AccessControl.AccessControlSections]::Owner
        )

        # Method 1
        $acl = [System.IO.FileSystemAclExtensions]::GetAccessControl(
            [System.IO.DirectoryInfo]::new($test)
        )
        # Path  Owner                       Access
        # ----  -----                       ------
        #       NT SERVICE\TrustedInstaller CREATOR OWNER Allow  268435456…

        # Method 2
        $acl2 = [System.Security.AccessControl.DirectorySecurity]::new($test, $Sections)
        # Path  Owner                       Access
        # ----  -----                       ------
        #       NT SERVICE\TrustedInstaller CREATOR OWNER Allow  268435456…

        # Method 3
        # Get-Acl does not support long paths (>256 characters)
        $acl3 = Get-Acl -Path $test
    #>

    param(

        # Path to the directory whose permissions to get
        [string]$LiteralPath,

        # Include inherited Access Control Entries in the results
        [Switch]$IncludeInherited,

        <#
        Access Control Sections to include.  By default all Sections are included except:
         - Audit because it requires admin rights if run on the local system and we want to avoid that requirement
         - Group because it is a legacy Section which does not control access in Windows anymore
        #>
        [System.Security.AccessControl.AccessControlSections]$Sections = (
            [System.Security.AccessControl.AccessControlSections]::Access -bor
            [System.Security.AccessControl.AccessControlSections]::Owner),

        # Include non-inherited Access Control Entries in the results
        [bool]$IncludeExplicitRules = $true,

        # Type of IdentityReference to return in each ACE
        [System.Type]$AccountType = [System.Security.Principal.SecurityIdentifier],

        # Cache of access control lists keyed by path
        [Parameter(Mandatory)]
        [ref]$AclByPath,

        # Hashtable of warning messages to avoid writing duplicate warnings when recurisive calls error while retrying a folder
        [hashtable]$WarningCache = @{},

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    Write-LogMsg -Text "[System.Security.AccessControl.DirectorySecurity]::new('$LiteralPath', '$Sections')" -Cache $Cache

    try {

        $DirectorySecurity = & { [System.Security.AccessControl.DirectorySecurity]::new(
                $LiteralPath,
                $Sections
            )
        } 2>$null

    }
    catch {

        $ThisWarning = $_.Exception.Message.Replace('Exception calling ".ctor" with "2" argument(s): ', '').Replace('"', '')
        $WarningCache[$LiteralPath] = $ThisWarning
        $Cache.Value['ErrorByItemPath_AclRetrieval'].Value[$LiteralPath] = $ThisWarning
        $StartingLogType = $Cache.Value['LogType'].Value
        $Cache.Value['LogType'].Value = 'Verbose' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat
        Write-LogMsg  -Text " # Error getting ACL for '$LiteralPath': '$ThisWarning'" -Cache $Cache
        $Cache.Value['LogType'].Value = $StartingLogType
        return

    }

    <#
    Get-Acl would have already populated the Path property on the Access List, but [System.Security.AccessControl.DirectorySecurity] has a null Path property instead
    Creating new PSCustomObjects with all the original properties then manually setting the Path is faster than using Add-Member
    #>
    $AclProperties = @{
        PSTypeName = 'Permission.Item'
    }

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
    #Write-LogMsg -Text "[System.Security.AccessControl.DirectorySecurity]::new('$LiteralPath', '$Sections').GetOwner([$AccountType])" -Cache $Cache
    $AclProperties['Owner'] = $DirectorySecurity.GetOwner($AccountType).Value

    #Write-LogMsg -Text "[System.Security.AccessControl.DirectorySecurity]::new('$LiteralPath', '$Sections').GetAccessRules(`$$IncludeExplicitRules, `$$IncludeInherited, [$AccountType])" -Cache $Cache
    $AclProperties['Access'] = $DirectorySecurity.GetAccessRules($IncludeExplicitRules, $IncludeInherited, $AccountType)
    $AclByPath.Value[$LiteralPath] = [PSCustomObject]$AclProperties

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
        [Parameter(Mandatory)]
        [ref]$LogBuffer

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
function Get-OwnerAce {

    # Simulate ACEs for item owners who differ from the owner of the item's parent

    param (

        # Path to the parent item whose owners to export
        [string]$Item,

        # Cache of access control lists keyed by path
        [Parameter(Mandatory)]
        [ref]$AclByPath

    )

    # ToDo - Confirm the logic for selecting this to make sure it accurately represents NTFS ownership behavior, then replace this comment with that confirmation and an explanation
    $InheritanceFlags = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit

    $SourceAccessList = $AclByPath.Value[$Item]
    $ThisParent = $Item.Substring(0, [math]::Max($Item.LastIndexOf('\'), 0)) # ToDo - This method of finding the parent path is faster than Split-Path -Parent but it has a dependency on a folder path not containing a trailing \ which is not currently what I am seeing in my simple test but should be supported in the future (possibly default)
    $ParentOwner = $AclByPath.Value[$ThisParent].Owner
    if (
        $SourceAccessList.Owner -ne $ParentOwner -and
        $SourceAccessList.Owner -ne $ParentOwner.IdentityReference
    ) {

        # Avoid items which have no corresponding ACL due to an error being returned (or some other expected circumstance).
        if ($AclByPath.Value[$Item]) {

            $AclByPath.Value[$Item].Owner = [PSCustomObject]@{
                IdentityReference = $SourceAccessList.Owner
                AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow
                FileSystemRights  = [System.Security.AccessControl.FileSystemRights]::FullControl
                InheritanceFlags  = $InheritanceFlags
                IsInherited       = $false
                PropagationFlags  = [System.Security.AccessControl.PropagationFlags]::None
            }

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
        [int]$RecurseDepth = -1,

        [hashtable]$Output = [hashtable]::Synchronized(@{}),

        # In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs
        [Parameter(Mandatory)]
        [ref]$Cache

    )

    if ($RecurseDepth -eq -1) {
        $DepthString = '∞'
    }
    else {
        $DepthString = $RecurseDepth
    }

    $Output[$TargetPath] = if ($Host.Version.Major -gt 2) {

        switch ($RecurseDepth) {
            -1 {
                GetDirectories -TargetPath $TargetPath -SearchOption ([System.IO.SearchOption]::AllDirectories) -Cache $Cache
            }
            0 {}
            1 {
                GetDirectories -TargetPath $TargetPath -SearchOption ([System.IO.SearchOption]::TopDirectoryOnly) -Cache $Cache
            }
            Default {

                $RecurseDepth = $RecurseDepth - 1
                Write-LogMsg -Text "Get-ChildItem '$TargetPath' -Force -Name -Recurse -Attributes Directory -Depth $RecurseDepth" -Cache $Cache
                (Get-ChildItem $TargetPath -Force -Recurse -Attributes Directory -Depth $RecurseDepth -ErrorVariable $GCIErrors -ErrorAction SilentlyContinue).FullName

                if ($GCIErrors.Count -gt 0) {

                    $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat
                    Write-LogMsg -Text "$($GCIErrors.Count) errors while getting directories of '$TargetPath'.  See verbose log for details." -Cache $Cache
                    $Cache.Value['LogType'].Value = 'Verbose' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat

                    ForEach ($Warning in $GCIErrors) {

                        Write-LogMsg -Text " # $($Warning.Exception.Message)" -Cache $Cache

                    }

                }

            }
        }

    }
    else {

        Write-LogMsg -Text "Get-ChildItem '$TargetPath' -Recurse" -Cache $Cache
        Get-ChildItem $TargetPath -Recurse -ErrorVariable $GCIErrors -ErrorAction SilentlyContinue |
        Where-Object -FilterScript { $_.PSIsContainer } |
        ForEach-Object { $_.FullName }

        if ($GCIErrors.Count -gt 0) {

            $StartingLogType = $Cache.Value['LogType'].Value
            $Cache.Value['LogType'].Value = 'Warning' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat
            Write-LogMsg -Text "$($GCIErrors.Count) errors while getting directories of '$TargetPath'. See verbose log for details." -Cache $Cache
            $Cache.Value['LogType'].Value = 'Verbose' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat

            ForEach ($Warning in $GCIErrors) {
                Write-LogMsg -Text " # $($Warning.Exception.Message)" -Cache $Cache
            }

            $Cache.Value['LogType'].Value = $StartingLogType

        }

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
        [Parameter(Mandatory)]
        [ref]$LogBuffer
    )

    $LogParams = @{
        ThisHostname = $ThisHostname
        Type         = 'Verbose'
        Buffer       = $LogBuffer
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
    $FoldersWithCreatorOwner = ($UserPermissions | Where-Object { $_.Name -match 'CREATOR OWNER' }).Group.NtfsAccessControlEntries.Path | Sort-Object -Unique
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
Export-ModuleMember -Function @('ConvertTo-SimpleProperty','Expand-Acl','Find-ServerNameInPath','Format-SecurityPrincipalMember','Format-SecurityPrincipalMemberUser','Format-SecurityPrincipalName','Format-SecurityPrincipalUser','Get-DirectorySecurity','Get-FileSystemAccessRule','Get-OwnerAce','Get-ServerFromFilePath','Get-Subfolder','New-NtfsAclIssueReport')






































































































































































































































