function Get-NtfsAccessRule {
    <#
    .INPUTS
    [System.String]$DirectoryPath
    .OUTPUTS
    [PsNtfs.PsNtfsAccessRule]
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
                $FileSecurity = [System.Security.AccessControl.FileSecurity]::new(
                    $DirectoryInfo,
                    $Sections
                )
                $FileSecurity.GetAccessRules($IncludeExplicitRules, $IncludeInherited, $AccountType) |
                ForEach-Object {
                    [PsNtfs.PsNtfsAccessRule]::new(
                        $CurrentPath,
                        $FileSecurity.AreAccessRulesProtected,
                        $_.FileSystemRights,
                        $_.AccessControlType,
                        $_.IdentityReference,
                        $_.IsInherited,
                        $_.InheritanceFlags,
                        $_.PropagationFlags
                    )
                    <#
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
                    #>
                }

            }

        }

    }

}
