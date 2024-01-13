---
external help file: PsNtfs-help.xml
Module Name: PsNtfs
online version:
schema: 2.0.0
---

# Get-FolderAce

## SYNOPSIS
Alternative to Get-Acl designed to be as lightweight and flexible as possible

## SYNTAX

```
Get-FolderAce [[-LiteralPath] <String>] [-IncludeInherited] [[-Sections] <AccessControlSections>]
 [[-IncludeExplicitRules] <Boolean>] [[-AccountType] <Type>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
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

### -ProgressAction
{{ Fill ProgressAction Description }}

```yaml
Type: System.Management.Automation.ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### [PSCustomObject]
## NOTES
Currently only supports Directories but could easily be copied to support files, or Registry or AD providers

## RELATED LINKS
