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
TEMP NOTE: Get-DirectorySecurity combined with Get-FileSystemAccessRule replaces Get-FolderACE

## SYNTAX

```
Get-DirectorySecurity [[-LiteralPath] <String>] [[-Sections] <AccessControlSections>]
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

### -Sections
Include all sections except Audit because it requires admin rights if run on the local system and we want to avoid that requirement

```yaml
Type: System.Security.AccessControl.AccessControlSections
Parameter Sets: (All)
Aliases:
Accepted values: None, Audit, Access, Owner, Group, All

Required: False
Position: 2
Default value: Access, Owner, Group
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
