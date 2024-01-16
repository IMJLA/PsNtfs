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
        [string]$DebugOutputStream = 'Silent',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$TodaysHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE)

    )

    # Use the same timestamp twice for efficiency through reduced calls to Get-Date, and for easy matching of the corresponding log entries
    $Timestamp = Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff'

    Write-Debug "  $Timestamp`t$TodaysHostname`t$WhoAmI`t$($MyInvocation.ScriptLineNumber)`tGet-FolderAce`t$($MyInvocation.ScriptLineNumber)`tDebug`t[System.Security.AccessControl.DirectorySecurity]::new('$LiteralPath', '$Sections')"
    $DirectorySecurity = & { [System.Security.AccessControl.DirectorySecurity]::new(
            $LiteralPath,
            $Sections
        )
    } 2>$null

    if ($null -eq $DirectorySecurity) {
        Write-Warning "$Timestamp`t$TodaysHostname`t$WhoAmI`t$($MyInvocation.ScriptLineNumber)`tGet-FolderAce`t$($MyInvocation.ScriptLineNumber)`tDebug`t# Found no ACL for '$LiteralPath'" -Type Warning @LogParams
        return
    }

    <#
    Get-Acl would have already populated the Path property on the Access List so we will too
    Creating new PSCustomObjects with all the original properties is faster than using Add-Member
    #>
    $AclProperties = @{}
    ForEach (
        $ThisProperty in
        (Get-Member -InputObject $DirectorySecurity -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name
    ) {
        $AclProperties[$ThisProperty] = $DirectorySecurity.$ThisProperty
    }
    $AclProperties['Path'] = $LiteralPath
    $SourceAccessList = [PSCustomObject]$AclProperties

    # Use the same timestamp twice for efficiency through reduced calls to Get-Date, and for easy matching of the corresponding log entries
    $Timestamp = Get-Date -Format 'yyyy-MM-ddThh:mm:ss.ffff'
    Write-Debug "  $Timestamp`t$TodaysHostname`t$WhoAmI`t$($MyInvocation.InvocationName)`tGet-FolderAce`t$($MyInvocation.ScriptLineNumber)`tDebug`t[System.Security.AccessControl.DirectorySecurity]::new('$LiteralPath', '$Sections').GetAccessRules(`$$IncludeExplicitRules, `$$IncludeInherited, [$AccountType])"
    $AccessRules = $DirectorySecurity.GetAccessRules($IncludeExplicitRules, $IncludeInherited, $AccountType)
    if ($AccessRules.Count -lt 1) {
        Write-Debug "  $Timestamp`t$TodaysHostname`t$WhoAmI`t$($($MyInvocation.ScriptLineNumber))`tGet-FolderAce`t$($MyInvocation.ScriptLineNumber)`tDebug`t# Found no matching access rules for '$LiteralPath'"
        return
    }

    $ACEPropertyNames = (Get-Member -InputObject $AccessRules[0] -MemberType Property, CodeProperty, ScriptProperty, NoteProperty).Name
    ForEach ($ThisAccessRule in $AccessRules) {
        $ACEProperties = @{
            SourceAccessList = $SourceAccessList
            Source           = 'Discretionary Access Control List'
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
        IdentityReference = $DirectorySecurity.Owner.Replace('O:', '')
        FileSystemRights  = [System.Security.AccessControl.FileSystemRights]::FullControl
        InheritanceFlags  = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
        PropagationFlags  = [System.Security.AccessControl.PropagationFlags]::None
        AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow
    }

}
