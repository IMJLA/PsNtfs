---
Module Name: PsNtfs
Module Guid: d2475b4e-5027-4728-ae4e-799ad4dd12e4
Download Help Link: {{ Update Download Link }}
Help Version: 2.0.230
Locale: en-US
---

# PsNtfs Module
## Description
Work with the contents of NTFS volumes

## PsNtfs Cmdlets
### [ConvertTo-SimpleProperty](ConvertTo-SimpleProperty.md)

ConvertTo-SimpleProperty [[-InputObject] <Object>] [[-Property] <string>] [[-PropertyDictionary] <hashtable>] [[-Prefix] <string>]


### [Expand-Acl](Expand-Acl.md)
Expand an Access Control List into its constituent Access Control Entries

### [Find-ServerNameInPath](Find-ServerNameInPath.md)
Parse a literal path to find its server

### [Format-SecurityPrincipalMember](Format-SecurityPrincipalMember.md)

Format-SecurityPrincipalMember [[-ResolvedID] <Object[]>] [[-ParentIdentityReference] <string>] [[-Access] <Object[]>] [[-PrincipalsByResolvedID] <hashtable>]


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

### [Get-FileSystemAccessRule](Get-FileSystemAccessRule.md)
Alternative to Get-Acl designed to be as lightweight and flexible as possible
TEMP NOTE: Get-DirectorySecurity combined with Get-FileSystemAccessRule is basically what Get-FolderACE does

### [Get-OwnerAce](Get-OwnerAce.md)

Get-OwnerAce [[-Item] <string>] [-AclByPath] <ref> [<CommonParameters>]


### [Get-ServerFromFilePath](Get-ServerFromFilePath.md)

Get-ServerFromFilePath [[-FilePath] <string>] [[-ThisFqdn] <string>]


### [Get-Subfolder](Get-Subfolder.md)

Get-Subfolder [[-TargetPath] <string>] [[-RecurseDepth] <int>] [[-Output] <hashtable>] [-Cache] <ref> [<CommonParameters>]


### [New-NtfsAclIssueReport](New-NtfsAclIssueReport.md)

New-NtfsAclIssueReport [[-FolderPermissions] <Object>] [[-UserPermissions] <Object>] [[-GroupNameRule] <scriptblock>] [[-ThisHostName] <string>] [[-WhoAmI] <string>] [-LogBuffer] <ref> [<CommonParameters>]



