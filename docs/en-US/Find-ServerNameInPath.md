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
Find-ServerNameInPath [[-LiteralPath] <String>] [-Cache] <PSReference> [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
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

### -Cache
In-process cache to reduce calls to other processes or disk, and store repetitive parameters for better readability of code and logs

```yaml
Type: System.Management.Automation.PSReference
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None. Pipeline input is not accepted.
## OUTPUTS

### [System.String] representing the name of the server that was extracted from the path
## NOTES

## RELATED LINKS
