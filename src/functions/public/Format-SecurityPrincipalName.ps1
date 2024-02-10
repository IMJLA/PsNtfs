function Format-SecurityPrincipalName {
    param ([object]$InputObject)
    if ($InputObject.DirectoryEntry.Properties) {
        $ThisName = $InputObject.DirectoryEntry.Properties['name']
    }
    if ("$ThisName" -eq '') {
        $InputObject.Name -replace [regex]::Escape("$($InputObject.DomainNetBios)\"), ''
    }
    else {
        $ThisName
    }
}