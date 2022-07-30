function Get-FolderAce {
    <#
    .SYNOPSIS
    Alternative to Get-Acl designed to be as lightweight and flexible as possible
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
        [System.Security.AccessControl.AccessControlSections]$Sections = (
            [System.Security.AccessControl.AccessControlSections]::Access -bor
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
        return
    }

    $AclProperties = @{}
    $AclPropertyNames = (Get-Member -InputObject $DirectorySecurity -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name
    ForEach ($ThisProperty in $AclPropertyNames) {
        $AclProperties[$ThisProperty] = $DirectorySecurity.$ThisProperty
    }
    $AclProperties['Path'] = $LiteralPath
    $AccessRules = $DirectorySecurity.GetAccessRules($IncludeExplicitRules, $IncludeInherited, $AccountType)
    if (-not $AccessRules) {
        return
    }
    $ACEPropertyNames = (Get-Member -InputObject $AccessRules[0] -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name
    ForEach ($ThisAccessRule in $AccessRules) {
        $ACEProperties = @{
            SourceAccessList = [PSCustomObject]$AclProperties
        }
        ForEach ($ThisProperty in $ACEPropertyNames) {
            $ACEProperties[$ThisProperty] = $ThisAccessRule.$ThisProperty
        }
        [PSCustomObject]$ACEProperties
    }

    #TODO: Output an object for the owner as well to represent that they have Full Control
    $ACEProperties['IsInherited'] = $false
    $ACEProperties['IdentityReference'] = $DirectorySecurity.Owner
    $ACEProperties['FileSystemRights'] = [System.Security.AccessControl.FileSystemRights]::FullControl
    $ACEProperties['InheritanceFlags'] = [System.Security.AccessControl.InheritanceFlags]::None
    $ACEProperties['PropagationFlags'] = [System.Security.AccessControl.PropagationFlags]::None
    $ACEProperties['AccessControlType'] = [System.Security.AccessControl.AccessControlType]::Allow
    [PSCustomObject]$ACEProperties

}
