---
external help file: PsNtfs-help.xml
Module Name: PsNtfs
online version:
schema: 2.0.0
---

# Find-ServerNameInPath

## SYNOPSIS
Parse a literal path to find its server

## SYNTAX

```
Find-ServerNameInPath [[-LiteralPath] <String>]
```

## DESCRIPTION
Currently only supports local file paths or UNC paths

## EXAMPLES

### EXAMPLE 1
```
Find-ServerNameInPath -LiteralPath 'C:\Test'
```

Return the hostname of the local computer because a local filepath was used

### EXAMPLE 2
```
Find-ServerNameInPath -LiteralPath '\\server123\Test\'
```

Return server123 because a UNC path for a folder shared on server123 was used

## PARAMETERS

### -LiteralPath
{{ Fill LiteralPath Description }}

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

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### [System.String] representing the name of the server that was extracted from the path
## NOTES

## RELATED LINKS
