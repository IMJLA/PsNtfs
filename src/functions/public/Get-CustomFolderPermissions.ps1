function Get-CustomFolderPermissions {
    <#
    .INPUTS
    [System.String]$DirectoryPath
    .OUTPUTS
    [System.Security.AccessControl.AuthorizationRuleCollection]
    #>

    [CmdletBinding(
        SupportsShouldProcess = $false,
        ConfirmImpact = "Low"
    )]

    param(

        # Path to the directory whose permissions to get
        [Parameter(ValueFromPipeline)]
        [string[]]$DirectoryPath,

        # Include inherited Access Control Entries in the results
        [Switch]$IncludeInherited
    )

    begin {
        $Sections = [System.Security.AccessControl.AccessControlSections]::Access
        $IncludeExplicitRules = $true
        $AccountType = [System.Security.Principal.SecurityIdentifier]
    }

    process {

        ForEach ($CurrentPath in $DirectoryPath) {

            $DirectoryInfo = Get-Item -LiteralPath $CurrentPath -ErrorAction SilentlyContinue

            if ($DirectoryInfo) {

                # New method for modern versions of PowerShell
                [System.Security.AccessControl.FileSecurity]::new(
                    $DirectoryInfo,
                    $Sections
                ).GetAccessRules($IncludeExplicitRules, $IncludeInherited, $AccountType) |
                ForEach-Object {
                    [pscustomobject]@{
                        Path                    = $CurrentPath
                        AreAccessRulesProtected = $_.AreAccessRulesProtected
                        FileSystemRights        = $_.FileSystemRights
                        AccessControlType       = $_.AccessControlType
                        IdentityReference       = $_.IdentityReference
                        IsInherited             = $_.IsInherited
                        InheritanceFlags        = $_.InheritanceFlags
                        PropagationFlags        = $_.PropagationFlags
                    }
                }

            }

        }

    }

}
