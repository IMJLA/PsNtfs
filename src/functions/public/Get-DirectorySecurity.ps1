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

        # Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module
        [string]$DebugOutputStream = 'Debug',

        # Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$ThisHostname = (HOSTNAME.EXE),

        # Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)
        [string]$WhoAmI = (whoami.EXE),

        # Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)
        [Parameter(Mandatory)]
        [ref]$LogBuffer = $null,

        # Cache of access control lists keyed by path
        [Parameter(Mandatory)]
        [ref]$AclByPath,

        # Hashtable of warning messages to avoid writing duplicate warnings when recurisive calls error while retrying a folder
        [hashtable]$WarningCache = @{}

    )

    $Log = @{
        ThisHostname = $ThisHostname
        Type         = $DebugOutputStream
        Buffer       = $LogBuffer
        WhoAmI       = $WhoAmI
    }

    Write-LogMsg @Log -Text "[System.Security.AccessControl.DirectorySecurity]::new('$LiteralPath', '$Sections')"

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
        $Log['Type'] = 'Verbose' # PS 5.1 will not allow you to override the Splat by manually calling the param, so we must update the splat
        Write-LogMsg @Log -Text " # Error getting ACL for '$LiteralPath': '$ThisWarning'"
        $Log['Type'] = $DebugOutputStream
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
    #Write-LogMsg @Log -Text "[System.Security.AccessControl.DirectorySecurity]::new('$LiteralPath', '$Sections').GetOwner([$AccountType])"
    $AclProperties['Owner'] = $DirectorySecurity.GetOwner($AccountType).Value

    #Write-LogMsg @Log -Text "[System.Security.AccessControl.DirectorySecurity]::new('$LiteralPath', '$Sections').GetAccessRules(`$$IncludeExplicitRules, `$$IncludeInherited, [$AccountType])"
    $AclProperties['Access'] = $DirectorySecurity.GetAccessRules($IncludeExplicitRules, $IncludeInherited, $AccountType)
    $AclByPath.Value[$LiteralPath] = [PSCustomObject]$AclProperties

}
