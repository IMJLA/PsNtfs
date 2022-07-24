---
external help file: PsNtfs-help.xml
Module Name: PsNtfs
online version:
schema: 2.0.0
---

# Expand-AccountPermission

## SYNOPSIS
Convert an object representing a security principal into a collection of objects respresenting the access control entries for that principal

## SYNTAX

```
Expand-AccountPermission [[-AccountPermission] <Object>]
```

## DESCRIPTION
Convert an object from Format-SecurityPrincipal (one object per principal, containing nested access entries) into flat objects (one per access entry per account)

## EXAMPLES

### EXAMPLE 1
```
(Get-Acl).Access |
Group-Object -Property IdentityReference |
Expand-IdentityReference |
Format-SecurityPrincipal |
Expand-AccountPermission
```

Incomplete example but it shows the chain of functions to generate the expected input for this

## PARAMETERS

### -AccountPermission
Object that was output from Format-SecurityPrincipal

```yaml
Type: System.Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

### [pscustomobject]$AccountPermission
## OUTPUTS

### [pscustomobject] One object per access control entry per account
## NOTES

## RELATED LINKS
