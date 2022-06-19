function Get-NtfsAccessRule {
    <#
    .INPUTS
    [System.String]$DirectoryPath
    .OUTPUTS
    [PSCustomObject]
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
                $FileSecurity = [System.Security.AccessControl.DirectorySecurity]::new(
                    $DirectoryInfo,
                    $Sections
                )

                $FileSecurity.GetAccessRules($IncludeExplicitRules, $IncludeInherited, $AccountType) |
                ForEach-Object {
                    [pscustomobject]@{
                        Path                        = $CurrentPath
                        PathAreAccessRulesProtected = $FileSecurity.AreAccessRulesProtected
                        FileSystemRights            = $_.FileSystemRights
                        AccessControlType           = $_.AccessControlType
                        IdentityReference           = $_.IdentityReference
                        IsInherited                 = $_.IsInherited
                        InheritanceFlags            = $_.InheritanceFlags
                        PropagationFlags            = $_.PropagationFlags
                    }
                }

            }

        }

    }

}
