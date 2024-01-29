function Find-ServerNameInPath {
    <#
    .SYNOPSIS
    Parse a literal path to find its server
    .DESCRIPTION
    Currently only supports local file paths or UNC paths
    .INPUTS
    None. Pipeline input is not accepted.
    .OUTPUTS
    [System.String] representing the name of the server that was extracted from the path
    .EXAMPLE
    Find-ServerNameInPath -LiteralPath 'C:\Test'

    Return the hostname of the local computer because a local filepath was used
    .EXAMPLE
    Find-ServerNameInPath -LiteralPath '\\server123\Test\'

    Return server123 because a UNC path for a folder shared on server123 was used
#>
    [OutputType([System.String])]
    param (
        [string]$LiteralPath,

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName)
    )
    if ($LiteralPath[1] -eq '\') {
        #UNC
        $SkippedFirstTwoChars = $LiteralPath.Substring(2, $LiteralPath.Length - 2)
        $NextSlashIndex = $SkippedFirstTwoChars.IndexOf('\')
        $SkippedFirstTwoChars.Substring(0, $NextSlashIndex).Replace('?', $ThisFqdn)
    }
    else {
        #Local
        $ThisFqdn
    }

}
