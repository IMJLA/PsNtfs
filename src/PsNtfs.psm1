<#
# Dot source any functions
ForEach ($ThisScript in $ScriptFiles) {
    # Dot source the function
    . $($ThisScript.FullName)
}
#>
Export-ModuleMember -Function @('ConvertTo-SimpleProperty','Expand-AccountPermission','Expand-Acl','Find-ServerNameInPath','Format-FolderPermission','Format-SecurityPrincipal','Get-FolderAce','Get-FolderTarget','Get-Subfolder','New-NtfsAclIssueReport','Remove-DuplicatesAcrossIgnoredDomains')



























