class PsNtfsAccessRule {
    # Just like [System.Security.AccessControl.FileSystemAccessRule] but with a Path property representing the file/folder associated with the Access Control Entry
    [System.String]$Path
    [System.Boolean]$PathAreAccessRulesProtected
    [System.Security.AccessControl.FileSystemRights]$FileSystemRights
    [System.Security.AccessControl.AccessControlType]$AccessControlType
    [System.Security.Principal.IdentityReference]$IdentityReference # Both the [System.Security.Principal.NTAccount] and [System.Security.Principal.SecurityIdentifier] classes derive from this class
    [System.Boolean]$IsInherited
    [System.Security.AccessControl.InheritanceFlags]$InheritanceFlags
    [System.Security.AccessControl.PropagationFlags]$PropagationFlags

    PsNtfsAccessRule (
        [System.String]$Path,
        [System.Boolean]$PathAreAccessRulesProtected,
        [System.Security.AccessControl.FileSystemRights]$FileSystemRights,
        [System.Security.AccessControl.AccessControlType]$AccessControlType,
        [System.Security.Principal.IdentityReference]$IdentityReference,
        [System.Boolean]$IsInherited,
        [System.Security.AccessControl.InheritanceFlags]$InheritanceFlags,
        [System.Security.AccessControl.PropagationFlags]$PropagationFlags
    ) {
        $this.Path = $Path
        $this.PathAreAccessRulesProtected = $PathAreAccessRulesProtected
        $this.FileSystemRights = $FileSystemRights
        $this.AccessControlType = $AccessControlType
        $this.IdentityReference = $IdentityReference
        $this.IsInherited = $IsInherited
        $this.InheritanceFlags = $InheritanceFlags
        $this.PropagationFlags = $PropagationFlags
    }

}
