---
external help file: PsNtfs-help.xml
Module Name: PsNtfs
online version:
schema: 2.0.0
---

# Get-DirectorySecurity

## SYNOPSIS
Alternative to Get-Acl designed to be as lightweight and flexible as possible
    Lightweight: Does not return the Path property like Get-Acl does
    Flexible how? 
Was it long paths? 
DFS? 
Can't remember what didn't work with Get-Acl

## SYNTAX

```
Get-DirectorySecurity [[-LiteralPath] <String>] [-IncludeInherited] [[-Sections] <AccessControlSections>]
 [[-IncludeExplicitRules] <Boolean>] [[-AccountType] <Type>] [[-DebugOutputStream] <String>]
 [[-ThisHostname] <String>] [[-WhoAmI] <String>] [[-LogBuffer] <PSReference>] [[-ACLsByPath] <Hashtable>]
 [[-WarningCache] <Hashtable>]
```

## DESCRIPTION
Returns an object for each access control entry instead of a single object for the ACL
Excludes inherited permissions by default but allows them to be included with the -IncludeInherited switch parameter

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -AccountType
Type of IdentityReference to return in each ACE

```yaml
Type: System.Type
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: System.Security.Principal.SecurityIdentifier
Accept pipeline input: False
Accept wildcard characters: False
```

### -ACLsByPath
Cache of access control lists keyed by path

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 9
Default value: @{}
Accept pipeline input: False
Accept wildcard characters: False
```

### -DebugOutputStream
Will be sent to the Type parameter of Write-LogMsg in the PsLogMessage module

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: Debug
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeExplicitRules
Include non-inherited Access Control Entries in the results

```yaml
Type: System.Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeInherited
Include inherited Access Control Entries in the results

```yaml
Type: System.Management.Automation.SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -LiteralPath
Path to the directory whose permissions to get

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogBuffer
Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sections
Access Control Sections to include. 
By default all Sections are included except:
 - Audit because it requires admin rights if run on the local system and we want to avoid that requirement
 - Group because it is a legacy Section which does not control access in Windows anymore

```yaml
Type: System.Security.AccessControl.AccessControlSections
Parameter Sets: (All)
Aliases:
Accepted values: None, Audit, Access, Owner, Group, All

Required: False
Position: 2
Default value: Access, Owner
Accept pipeline input: False
Accept wildcard characters: False
```

### -ThisHostname
Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: (HOSTNAME.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

### -WarningCache
Hashtable of warning messages to avoid writing duplicate warnings when recurisive calls error while retrying a folder

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 10
Default value: @{}
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhoAmI
Username to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: (whoami.EXE)
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### [PSCustomObject]
## NOTES
Currently only supports Directories but could easily be copied to support files, or Registry or AD providers

TODO: Performance Test Methods

    $test = 'c:\windows'
    \[System.Security.AccessControl.AccessControlSections\]$Sections = (
        \[System.Security.AccessControl.AccessControlSections\]::Access -bor
        \[System.Security.AccessControl.AccessControlSections\]::Owner
    )

    # Method 1
    $acl = \[System.IO.FileSystemAclExtensions\]::GetAccessControl(
        \[System.IO.DirectoryInfo\]::new($test)
    )
    # Path  Owner                       Access
    # ----  -----                       ------
    #       NT SERVICE\TrustedInstaller CREATOR OWNER Allow  268435456…

    # Method 2
    $acl2 = \[System.Security.AccessControl.DirectorySecurity\]::new($test, $Sections)
    # Path  Owner                       Access
    # ----  -----                       ------
    #       NT SERVICE\TrustedInstaller CREATOR OWNER Allow  268435456…

    # Method 3
    # Get-Acl does not support long paths (\>256 characters)
    $acl3 = Get-Acl -Path $test

## RELATED LINKS
