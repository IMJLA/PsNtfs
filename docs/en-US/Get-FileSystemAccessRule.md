---
external help file: PsNtfs-help.xml
Module Name: PsNtfs
online version:
schema: 2.0.0
---

# Get-FileSystemAccessRule

## SYNOPSIS
Alternative to Get-Acl designed to be as lightweight and flexible as possible
TEMP NOTE: Get-DirectorySecurity combined with Get-FileSystemAccessRule is basically what Get-FolderACE does

## SYNTAX

```
Get-FileSystemAccessRule [[-DirectorySecurity] <DirectorySecurity>] [-IncludeInherited]
 [[-IncludeExplicitRules] <Boolean>] [[-AccountType] <Type>] [[-DebugOutputStream] <String>]
 [[-TodaysHostname] <String>] [[-WhoAmI] <String>] [[-LogBuffer] <Hashtable>]
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
Position: 3
Default value: System.Security.Principal.SecurityIdentifier
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
Position: 4
Default value: Silent
Accept pipeline input: False
Accept wildcard characters: False
```

### -DirectorySecurity
Discretionary Access List whose FileSystemAccessRules to return

```yaml
Type: System.Security.AccessControl.DirectorySecurity
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
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
Position: 2
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

### -LogBuffer
Hashtable of log messages for Write-LogMsg (can be thread-safe if a synchronized hashtable is provided)

```yaml
Type: System.Collections.Hashtable
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: ([hashtable]::Synchronized(@{}))
Accept pipeline input: False
Accept wildcard characters: False
```

### -TodaysHostname
Hostname to record in log messages (can be passed to Write-LogMsg as a parameter to avoid calling an external process)

```yaml
Type: System.String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: (HOSTNAME.EXE)
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
Position: 6
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

## RELATED LINKS
