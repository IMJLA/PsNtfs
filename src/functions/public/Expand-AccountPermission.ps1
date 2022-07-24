function Expand-AccountPermission {
    <#
        .SYNOPSIS
        Convert an object representing a security principal into a collection of objects respresenting the access control entries for that principal
        .DESCRIPTION
        Convert an object from Format-SecurityPrincipal (one object per principal, containing nested access entries) into flat objects (one per access entry per account)
        .INPUTS
        [pscustomobject]$AccountPermission
        .OUTPUTS
        [pscustomobject] One object per access control entry per account
        .EXAMPLE
        (Get-Acl).Access |
        Group-Object -Property IdentityReference |
        Expand-IdentityReference |
        Format-SecurityPrincipal |
        Expand-AccountPermission

        Incomplete example but it shows the chain of functions to generate the expected input for this
    #>
    param (
        # Object that was output from Format-SecurityPrincipal
        $AccountPermission
    )
    ForEach ($Account in $AccountPermission) {

        $PropertiesToExclude = @(
            'NativeObject',
            'NtfsAccessControlEntries',
            'Group'
        )
        $Props = @{}

        $AccountNoteProperties = $Account |
        Get-Member -MemberType NoteProperty |
        Where-Object -Property Name -NotIn $PropertiesToExclude

        ForEach ($ThisProperty in $AccountNoteProperties) {
            if ($null -eq $Props[$ThisProperty.Name]) {
                $Value = $Account.$($ThisProperty.Name)

                if ($null -ne $Value) {
                    # We wrap this in an expression and use output redirection to supress this error:
                    # The following exception occurred while retrieving member "GetType": "Not implemented"
                    [string]$Type = & { $Value.GetType().FullName } 2>$null
                } else {
                    [string]$Type = $null
                }

                switch ($Type) {
                    'System.DirectoryServices.PropertyCollection' {
                        ForEach ($ThisAccountProperty in $Account.Properties.Keys) {
                            $Props[$ThisAccountProperty] = ConvertFrom-PropertyValueCollectionToString -PropertyValueCollection $Account.Properties[$ThisAccountProperty]
                        }
                        $Props[$ThisProperty.Name] = "Converted to properties prefixed with AccountProperty"
                    }
                    'System.DirectoryServices.PropertyValueCollection' {
                        $Props[$ThisProperty.Name] = ConvertFrom-PropertyValueCollectionToString -PropertyValueCollection $Value
                    }
                    default {
                        <#
                            By default we will just let most types get cast as a string
                            Includes but not limited to:
                                $null (because GetType is not implemented)
                                System.String
                                System.Boolean
                                System.Byte[]
                        #>
                        $Props[$ThisProperty.Name] = "$Value"
                    }
                }
            }
        }

        ForEach ($ACE in $Account.NtfsAccessControlEntries) {

            $ACENoteProperties = $ACE |
            Get-Member -MemberType NoteProperty

            ForEach ($ThisProperty in $ACENoteProperties) {
                $Props["ACE$($ThisProperty.Name)"] = [string]$ACE.$($ThisProperty.Name)
            }

            [pscustomobject]$Props
        }
    }
}
