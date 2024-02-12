---
Module Name: PsNtfs
Module Guid: d2475b4e-5027-4728-ae4e-799ad4dd12e4
Download Help Link: {{ Update Download Link }}
Help Version: 2.0.162
Locale: en-US
---

# PsNtfs Module
## Description
Work with the contents of NTFS volumes

## PsNtfs Cmdlets
### [ConvertTo-SimpleProperty](ConvertTo-SimpleProperty.md)

ConvertTo-SimpleProperty [[-InputObject] <Object>] [[-Property] <string>] [[-PropertyDictionary] <hashtable>] [[-Prefix] <string>]


### [Expand-AccountPermission](Expand-AccountPermission.md)
Expand an object representing a security principal and into a collection of objects respresenting the access control entries for that principal

### [Expand-Acl](Expand-Acl.md)
Expand an Access Control List into its constituent Access Control Entries

### [Find-ServerNameInPath](Find-ServerNameInPath.md)
Parse a literal path to find its server

### [Format-SecurityPrincipal](Format-SecurityPrincipal.md)

Format-SecurityPrincipal [[-ResolvedID] <string>] [[-PrincipalsByResolvedID] <hashtable>]


### [Format-SecurityPrincipalMember](Format-SecurityPrincipalMember.md)

Format-SecurityPrincipalMember [[-InputObject] <Object[]>]


### [Format-SecurityPrincipalMemberUser](Format-SecurityPrincipalMemberUser.md)

Format-SecurityPrincipalMemberUser [[-InputObject] <Object>]


### [Format-SecurityPrincipalName](Format-SecurityPrincipalName.md)

Format-SecurityPrincipalName [[-InputObject] <Object>]


### [Format-SecurityPrincipalUser](Format-SecurityPrincipalUser.md)

Format-SecurityPrincipalUser [[-InputObject] <Object>]


### [Get-DirectorySecurity](Get-DirectorySecurity.md)
Alternative to Get-Acl designed to be as lightweight and flexible as possible
    Lightweight: Does not return the Path property like Get-Acl does
    Flexible how?  Was it long paths?  DFS?  Can't remember what didn't work with Get-Acl
TEMP NOTE: Get-DirectorySecurity combined with Get-FileSystemAccessRule is basically what Get-FolderACE does

### [Get-FileSystemAccessRule](Get-FileSystemAccessRule.md)
Alternative to Get-Acl designed to be as lightweight and flexible as possible
TEMP NOTE: Get-DirectorySecurity combined with Get-FileSystemAccessRule is basically what Get-FolderACE does

### [Get-FolderAce](Get-FolderAce.md)
Alternative to Get-Acl designed to be as lightweight and flexible as possible
    Lightweight: Does not return the Path property like Get-Acl does
    Flexible how?  Was it long paths?  DFS?  Can't remember what didn't work with Get-Acl

### [Get-OwnerAce](Get-OwnerAce.md)

Get-OwnerAce [[-Item] <string>] [[-ACLsByPath] <hashtable>]


### [Get-ServerFromFilePath](Get-ServerFromFilePath.md)

Get-ServerFromFilePath [[-FilePath] <string>] [[-ThisFqdn] <string>]


### [Get-Subfolder](Get-Subfolder.md)

Get-Subfolder [[-TargetPath] <string>] [[-FolderRecursionDepth] <int>] [[-DebugOutputStream] <string>] [[-ThisHostname] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>] [<CommonParameters>]


### [New-NtfsAclIssueReport](New-NtfsAclIssueReport.md)

New-NtfsAclIssueReport [[-FolderPermissions] <Object>] [[-UserPermissions] <Object>] [[-GroupNameRule] <scriptblock>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [[-LogMsgCache] <hashtable>]



