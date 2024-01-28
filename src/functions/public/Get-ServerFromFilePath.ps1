function Get-ServerFromFilePath {
    param (
        [string]$FilePath,

        <#
        FQDN of the computer running this function.

        Can be provided as a string to avoid calls to HOSTNAME.EXE and [System.Net.Dns]::GetHostByName()
        #>
        [string]$ThisFqdn = ([System.Net.Dns]::GetHostByName((HOSTNAME.EXE)).HostName)
    )

    if ($FilePath[1] -eq '\') {
        #UNC
        $SkippedFirstTwoChars = $FilePath.Substring(2, $FilePath.Length - 2)
        $NextSlashIndex = $SkippedFirstTwoChars.IndexOf('\')
        $SkippedFirstTwoChars.Substring(0, $NextSlashIndex)
    }
    else {
        #Local
        $ThisFqdn
    }

}