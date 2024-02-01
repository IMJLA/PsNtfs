# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [2.0.107] - 2024-01-31 - bug get-folderace

## [2.0.106] - 2024-01-31 - bug get-folderace

## [2.0.105] - 2024-01-31 - bug get-folderace

## [2.0.104] - 2024-01-31 - bug get-folderace

## [2.0.103] - 2024-01-31 - bug get-folderace

## [2.0.102] - 2024-01-31 - bug get-folderace

## [2.0.101] - 2024-01-31 - bug get-folderace

## [2.0.100] - 2024-01-31 - bug get-folderace

## [2.0.99] - 2024-01-31 - bug get-folderace

## [2.0.98] - 2024-01-31 - bug get-folderace

## [2.0.97] - 2024-01-31 - bug get-folderace

## [2.0.96] - 2024-01-31 - bug get-folderace

## [2.0.95] - 2024-01-31 - bug get-folderace

## [2.0.94] - 2024-01-31 - test get-ownerace

## [2.0.93] - 2024-01-31 - troubleshooting

## [2.0.92] - 2024-01-31 - bugfix get-folderace

## [2.0.91] - 2024-01-31 - bugfix get-folderace

## [2.0.90] - 2024-01-31 - bug get-ownerace

## [2.0.89] - 2024-01-31 - bug get-folderace

## [2.0.88] - 2024-01-31 - bug get-folderace

## [2.0.87] - 2024-01-31 - bugfix get-folderace

## [2.0.86] - 2024-01-31 - bugfix progress bar format-folderpermission

## [2.0.85] - 2024-01-31 - bugfix progress bar format-folderpermission

## [2.0.84] - 2024-01-31 - bugfix progress bar format-folderpermission

## [2.0.83] - 2024-01-28 - bugfix get-subfolder logparams type

## [2.0.82] - 2024-01-28 - reduce calls to external executables

## [2.0.81] - 2024-01-28 - made Find-ServerNameInPath more efficient (no regex, single char comparison instead)

## [2.0.80] - 2024-01-28 - Add more debug output to Get-FolderAce. Also add Get-ServerFromFilePath although it is not in use

## [2.0.79] - 2024-01-27 - shortened param name

## [2.0.78] - 2024-01-21 - https://github.com/IMJLA/Export-Permission/issues/61

## [2.0.77] - 2024-01-21 - enhancement-performance remove usage of select-object -first

## [2.0.76] - 2024-01-21 - bugfix Format-SecurityPrincipal

## [2.0.75] - 2024-01-21 - bugfix Format-SecurityPrincipal

## [2.0.74] - 2024-01-21 - bugfix Format-SecurityPrincipal

## [2.0.73] - 2024-01-20 - updated comments get-folderace

## [2.0.72] - 2024-01-20 - bugfix owner feature in get-folderace

## [2.0.71] - 2024-01-20 - bugfix Get-FolderAce

## [2.0.70] - 2024-01-20 - add OwnerCache updating to Get-FolderAce and add Get-OwnerAce which uses it

## [2.0.69] - 2024-01-15 - updated Source in Get-FolderAce from DACL to Discretionary Access Control List

## [2.0.68] - 2024-01-15 - added owner feature to Get-FolderAce (returns object to represent Full Control for folder owner)

## [2.0.67] - 2024-01-15 - added feature to included representative ACE for Owner in Get-FolderACE

## [2.0.66] - 2024-01-15 - added feature to included representative ACE for Owner in Get-FolderACE

## [2.0.65] - 2024-01-15 - Resolve-Folder lns 35-37 workaround for https://github.com/IMJLA/PsNtfs/issues/1; also some DFS comments moved to PsDfs module

## [2.0.64] - 2024-01-13 - troubleshooting bug in get-folderace ln 51-55

## [2.0.63] - 2024-01-13 - think I am reintroducing a bug by not suppressing output in get-folderace lines 46-50 but testing anyway

## [2.0.62] - 2024-01-13 - bug fix in New-NtfsAclIssueReport

## [2.0.61] - 2024-01-13 - changed new-ntfsaclissuereport to not depend no the NtfsAccessControlEntries property of the $UserPermissions object

## [2.0.60] - 2024-01-13 - changed new-ntfsaclissuereport to not depend no the NtfsAccessControlEntries property of the $UserPermissions object

## [2.0.59] - 2024-01-13 - bug fix in expand-accountpermission

## [2.0.58] - 2024-01-12 - bugfix in convertto-simpleproperty on lines 48-51

## [2.0.57] - 2024-01-12 - corrected redundant metadata in log file code, lines 44-50 of format-folderpermission.ps1

## [2.0.56] - 2024-01-12 - implemented write-logmsg in format-folderpermission

## [2.0.55] - 2024-01-12 - reloaded env vars for updated psgallery api key for publishing

## [2.0.54] - 2024-01-12 - testing updated psgallery api key for publishing

## [2.0.53] - 2024-01-12 - removed .vscode folder due to inability to open folder

## [2.0.52] - 2024-01-12 - implemented write-logmsg

## [2.0.51] - 2024-01-12 - implemented write-logmsg in new-ntfsaclissuereport

## [2.0.50] - 2022-09-05 - renamed get-foldertarget to resolve-folder

## [2.0.49] - 2022-09-05 - Added Expand-Folder, in future can implement multithreading for Get-Subfolder via this function

## [2.0.48] - 2022-09-04 - Removed ACE object for ACL Owner until -IncludeOwner param is implemented

## [2.0.47] - 2022-09-03 - Bug fix to handle edge case with System.DirectoryServices.PropertyCollection in ConvertTo-SimpleProperty (which really feels unrelated to NTFS by the way)

## [2.0.46] - 2022-08-31 - bugfix Format-SecurityPrincipal including domainnetbios in Name property, and bugfix ConvertTo-SimpleProperty with a few additional types and functions to convert them

## [2.0.45] - 2022-08-28 - fixed export-permission bug 7 in format-folderpermission

## [2.0.44] - 2022-08-28 - fixed export-permission bug 7 in format-folderpermission

## [2.0.43] - 2022-08-28 - fixed export-permission bug 7 in format-folderpermission

## [2.0.42] - 2022-08-28 - fixed export-permission bug 7 in format-folderpermission

## [2.0.41] - 2022-08-28 - fixed export-permission bug 7 in format-folderpermission

## [2.0.40] - 2022-08-28 - fixed export-permission bug #7 in format-folderpermission

## [2.0.39] - 2022-08-28 - fixed export-permission bug #7 in format-folderpermission

## [2.0.38] - 2022-08-28 - Bugfix for WinNT DirectoryEntry objects in ConvertTo-SimpleProperty

## [2.0.37] - 2022-08-27 - Updated Get-FolderTarget

## [2.0.36] - 2022-08-27 - Updated Format-FolderPermission to work with the output from Select-UniqueAccountPermission instead of Format-SecurityPrincipal

## [2.0.35] - 2022-08-27 - Added SourceAclPath property to output of Expand-AccountPermission

## [2.0.34] - 2022-08-27 - Added mapped drive, UNC features and FQDN resolution to get-foldertarget

## [2.0.33] - 2022-08-27 - bug fix for unc folder targets in get-foldertarget

## [2.0.32] - 2022-08-27 - Bug fix in Get-FolderTarget for non-DFS UNC paths

## [2.0.31] - 2022-08-21 - bugfix (remove O: prefix from Owner identityreference)

## [2.0.30] - 2022-08-20 - removed function

## [2.0.29] - 2022-08-20 - Removed function

## [2.0.28] - 2022-08-14 - Bug fix in Get-FolderAce that was causing null items to be returned

## [2.0.27] - 2022-08-14 - Minor changes

## [2.0.26] - 2022-08-14 - More advanced generation of 'User' property in Format-SecurityPrincipal

## [2.0.25] - 2022-08-05 - Removed progress bar from Expand-AccountPermission (use multithreading instead)

## [2.0.24] - 2022-08-05 - Removed progress bar from Expand-AccountPermission (use multithreading instead)

## [2.0.23] - 2022-08-05 - added progress bar to format-folderpermission

## [2.0.22] - 2022-08-05 - bugfix in format-folderpermission with schemaclassname

## [2.0.21] - 2022-08-05 - Bugfixes

## [2.0.20] - 2022-08-05 - Bugfix in format-securityprincipal when retrieving samaccountname

## [2.0.19] - 2022-08-01 - Bug fix in DFS target filtering logic in Get-FolderTarget

## [2.0.18] - 2022-07-31 - Bug fix in ConvertTo-SimpleProperty

## [2.0.17] - 2022-07-31 - Bug fix in ConvertTo-SimpleProperty

## [2.0.16] - 2022-07-31 - Bug fix in ComvertTo-SimpleProperty

## [2.0.15] - 2022-07-31 - Bug fixes for Expand-AccountPermission which involved creating ConvertTo-SimpleProperty

## [2.0.14] - 2022-07-31 - Bug fixes for Expand-AccountPermission which involved creating ConvertTo-SimpleProperty

## [2.0.13] - 2022-07-31 - Bug fixes for Expand-AccountPermission which involved creating ConvertTo-SimpleProperty

## [2.0.12] - 2022-07-31 - Bug fixes for Expand-AccountPermission which involved creating ConvertTo-SimpleProperty

## [2.0.11] - 2022-07-31 - Bug fixes for Expand-AccountPermission, this involved creating ConvertTo-SimpleProperty

## [2.0.10] - 2022-07-31 - Added Find-ServerNameInPath

## [2.0.9] - 2022-07-30 - Specified -FilterScript for readability

## [2.0.8] - 2022-07-30 - Take 3

## [2.0.7] - 2022-07-30 - Trying again

## [2.0.6] - 2022-07-30 - Modification to psakefile to always commit to current git branch

## [2.0.5] - 2022-07-29 - Troubleshooting 5.1 compatibility

## [2.0.4] - 2022-07-27 - Revert last change, did not work

## [2.0.3] - 2022-07-27 - Workaround for PS 5.1 in GetDirectories

## [2.0.2] - 2022-07-25 - Cleaned up source .psm1 file

## [2.0.1] - 2022-07-25 - Bug fix in Format-FolderPermission

## [2.0.0] - 2022-07-24 - Major breaking changes, replaced Get-NtfsAccessRule with Get-FolderAce, added Expand-Acl and Expand-AccountPermission

## [1.0.25] - 2022-07-09 - publish to psgallery take 2

## [1.0.24] - 2022-07-09 - updated psakefile and published to psgallery

## [1.0.23] - 2022-06-26 - Removed group filtering from Format-SecurityPrincipal

## [1.0.22] - 2022-06-26 - Deleted New-PermissionsReport because it was unnecessary

## [1.0.21] - 2022-06-25 - Silent handling of 0 for FolderRecursionDepth parameter value

## [1.0.20] - 2022-06-25 - bug fix in GetDirectories debug output

## [1.0.19] - 2022-06-25 - Bug fix for get-childitem usage in get-subfolder

## [1.0.18] - 2022-06-25 - bug fix in Get-Subfolder

## [1.0.17] - 2022-06-25 - Implemented GetDirectories private function

## [1.0.16] - 2022-06-24 - Changed Write-Host to Write-Verbose in Format-FolderPermission

## [1.0.15] - 2022-06-24 - Suspect intermittent bug in PSScriptAnalyzer, trying again

## [1.0.14] - 2022-06-24 - Updated New-NtfsAclIssueReport to output pscustom object and move PRTG functionality to PsPrtg module

## [1.0.13] - 2022-06-19 - Bug fix in Get-NtfsAccessRule (now using DirectorySecurity instead of FileSecurity)

## [1.0.12] - 2022-06-19 - Fixed bug with incorrect property name in Format-FolderPermission

## [1.0.11] - 2022-06-19 - Removed custom classes

## [1.0.10] - 2022-06-19 - Fixed file name Get-NtfsAccessRule.ps1

## [1.0.9] - 2022-06-19 - Fixed manifest file

## [1.0.8] - 2022-06-19 - Added PsNtfsAccessRule class

## [1.0.7] - 2022-06-19 - Testing automatic git commit in build process

## [1.0.6] - 2022-06-19 - Troubleshooting build process

## [1.0.5] - 2022-06-19 - Initial working build

## [1.0.4] - 2022-06-19 - 

## [1.0.3] - 2022-06-19 - 

## [1.0.2] - 2022-06-19 - 

## [1.0.1] - 2022-06-19 - 

## [1.0.0] Unreleased

