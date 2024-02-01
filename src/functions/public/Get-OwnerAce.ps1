function Get-OwnerAce {

    param (

        # Path to the parent item whose owners to export
        [string]$Item,

        # Thread-safe cache of items and their owners
        [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]$OwnerCache = [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]::new()
    )

    # ToDo - Confirm the logic for selecting this to make sure it accurately represents NTFS ownership behavior, then replace this comment with that confirmation and an explanation
    $InheritanceFlags = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit

    $SourceAccessList = $OwnerCache[$Item]
    $ThisParent = $Item.Substring(0, [math]::Max($Item.LastIndexOf('\'), 0)) # ToDo - This method of finding the parent path is faster than Split-Path -Parent but it has a dependency on a folder path not containing a trailing \ which is not currently what I am seeing in my simple test but should be supported in the future (possibly default)
    if ($SourceAccessList.Owner -ne $OwnerCache[$ThisParent].Owner) {
        [PSCustomObject]@{
            SourceAccessList  = $SourceAccessList
            IdentityReference = $SourceAccessList.Owner
            AccessControlType = [System.Security.AccessControl.AccessControlType]::Allow
            FileSystemRights  = [System.Security.AccessControl.FileSystemRights]::FullControl
            InheritanceFlags  = $InheritanceFlags
            IsInherited       = $false
            PropagationFlags  = [System.Security.AccessControl.PropagationFlags]::None
            Source            = 'Ownership'
        }

    }

}
