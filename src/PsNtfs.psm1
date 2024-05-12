<#
# Dot source any functions
ForEach ($ThisScript in $ScriptFiles) {
    # Dot source the function
    . $($ThisScript.FullName)
}
#>
Export-ModuleMember -Function @('ConvertTo-SimpleProperty','Expand-Acl','Find-ServerNameInPath','Format-SecurityPrincipalMember','Format-SecurityPrincipalMemberUser','Format-SecurityPrincipalName','Format-SecurityPrincipalUser','Get-DirectorySecurity','Get-FileSystemAccessRule','Get-OwnerAce','Get-ServerFromFilePath','Get-Subfolder','New-NtfsAclIssueReport')






























































































































































































