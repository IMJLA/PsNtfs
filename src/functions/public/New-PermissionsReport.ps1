function New-PermissionsReport {
    param (
        $Permissions,
        [string]$LogDir
    )

    $Permissions |
        Select Path,
            IdentityReference,
            AccessControlType,
            FileSystemRights,
            IsInherited,
            InheritanceFlags,
            PropagationFlags |
                Export-Csv -Path "$LogDir\RawPermissionsReport.csv" -NoTypeInformation -Force
    "$LogDir\RawPermissionsReport.csv"
}