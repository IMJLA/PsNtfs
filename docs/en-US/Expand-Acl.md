---
external help file: PsNtfs-help.xml
Module Name: PsNtfs
online version:
schema: 2.0.0
---

# Expand-Acl

## SYNOPSIS
Expand an Access Control List into its constituent Access Control Entries

## SYNTAX

```
Expand-Acl [[-InputObject] <PSObject>] [<CommonParameters>]
```

## DESCRIPTION
Enumerate the members of the Access property of the $InputObject parameter (which is an AuthorizationRuleCollection or similar)
Append the original ACL to each member as a SourceAccessList property
Then return each member

## EXAMPLES

### EXAMPLE 1
```
Get-Acl |
Expand-Acl
```

Use Get-Acl from the Microsoft.PowerShell.Security module as the source of the access list
This works in either Windows Powershell or in Powershell
Get-Acl does not support long paths (\>256 characters)
That was why I originally used the .Net Framework method

## PARAMETERS

### -InputObject
Access Control List whose Access Control Entries to return
Expects \[System.Security.AccessControl.FileSecurity\] objects from Get-Acl or otherwise
Expects \[System.Security.AccessControl.DirectorySecurity\] objects from Get-Acl or otherwise
Accepts any \[PSObject\] as long as it has an 'Access' property that contains a collection

```yaml
Type: System.Management.Automation.PSObject
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [PSObject]$InputObject
### Expected:
### [System.Security.AccessControl.DirectorySecurity]$InputObject from Get-Acl
### or
### [System.Security.AccessControl.FileSecurity]$InputObject from Get-Acl
## OUTPUTS

### [PSCustomObject]
## NOTES

## RELATED LINKS
