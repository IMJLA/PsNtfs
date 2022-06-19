---
Module Name: PsNtfs
Module Guid: d2475b4e-5027-4728-ae4e-799ad4dd12e4 d2475b4e-5027-4728-ae4e-799ad4dd12e4
Download Help Link: {{ Update Download Link }}
Help Version: 1.0.2
Locale: en-US
---

# PsNtfs Module
## Description
Work with the contents of NTFS volumes

## PsNtfs Cmdlets
### [Format-FolderPermission](Format-FolderPermission.md)

Format-FolderPermission [[-UserPermission] <Object>] [[-FileSystemRightsToIgnore] <string[]>]


### [Format-SecurityPrincipal](Format-SecurityPrincipal.md)

Format-SecurityPrincipal [[-SecurityPrincipal] <Object>]


### [Get-CustomFolderPermissions](Get-CustomFolderPermissions.md)


### [Get-FolderTarget](Get-FolderTarget.md)

Get-FolderTarget [[-FolderPath] <string[]>]


### [Get-Subfolder](Get-Subfolder.md)

Get-Subfolder [[-TargetPath] <string>] [[-FolderRecursionDepth] <int>] [<CommonParameters>]


### [New-NtfsAclIssueReport](New-NtfsAclIssueReport.md)

New-NtfsAclIssueReport [[-FolderPermissions] <Object>] [[-UserPermissions] <Object>] [[-GroupNamingConvention] <scriptblock>] [[-PrtgProbe] <string>] [[-PrtgSensorProtocol] <string>] [[-PrtgSensorPort] <int>] [[-PrtgSensorToken] <string>]


### [New-PermissionsReport](New-PermissionsReport.md)

New-PermissionsReport [[-Permissions] <Object>] [[-LogDir] <string>]


### [Remove-DuplicatesAcrossIgnoredDomains](Remove-DuplicatesAcrossIgnoredDomains.md)

Remove-DuplicatesAcrossIgnoredDomains [[-UserPermission] <Object>] [[-DomainToIgnore] <string[]>] [<CommonParameters>]



