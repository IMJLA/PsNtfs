function Format-SecurityPrincipalUser {
    param ([object]$InputObject)

    if ($InputObject.Properties) {
        $sAmAccountName = $InputObject.Properties['sAmAccountName']
    }
    if ("$sAmAccountName" -eq '') {
        $InputObject.Name
    }
    else {
        $sAmAccountName
    }
}