function ConvertTo-SimpleProperty {

    param (
        $InputObject,

        [string]$Property,

        [hashtable]$PropertyDictionary = @{},

        [string]$Prefix
    )

    <#
    An occurs when:
        A DirectoryEntry has a SchemaEntry property
        which is a DirectoryEntry
        which has a Properties property
        which is a System.DirectoryServices.PropertyCollection
        but throws the following error to the Success stream (not the error stream, so it is hard to catch):
            PS C:\Users\Test> $ThisDirectoryEntry.Properties
            format-default : The entry properties cannot be enumerated. Consider using the entry schema to determine what properties are available.
                + CategoryInfo          : NotSpecified: (:) [format-default], NotSupportedException
                + FullyQualifiedErrorId : System.NotSupportedException,Microsoft.PowerShell.Commands.FormatDefaultCommand
    To avoid the error we will inspect the key count in the PropertyCollection and abort if there are 0 keys.

    Steps to reproduce:
    PS C:\> $InputObject = [ADSI]"LDAP://ad.contoso.com/schema/user"
    PS C:\> $InputObject.Properties
    format-default: The entry properties cannot be enumerated. Consider using the entry schema to determine what properties are available.
    #>
    if ($Property -eq 'Properties') {
        if ($InputObject.Properties.GetType().FullName -eq 'System.DirectoryServices.PropertyCollection') {
            if ( -not $InputObject.Properties.Keys.Count -gt 0 ) {
                return
            }
        }
    }

    $Value = $InputObject.$Property
    [string]$Type = $null

    if ($Value) {
        # Ensure the GetType method exists to avoid this error:
        # The following exception occurred while retrieving member "GetType": "Not implemented"
        if (Get-Member -InputObject $Value -Name GetType) {
            [string]$Type = $Value.GetType().FullName
        }
        else {
            # The only scenario we've encountered where the GetType() method does not exist is DirectoryEntry objects from the WinNT provider
            # Force the type to 'System.DirectoryServices.DirectoryEntry'
            [string]$Type = 'System.DirectoryServices.DirectoryEntry'
        }
    }

    switch ($Type) {
        'System.DirectoryServices.DirectoryEntry' {
            $PropertyDictionary["$Prefix$Property"] = ConvertFrom-DirectoryEntry -DirectoryEntry $Value
        }
        'System.DirectoryServices.PropertyCollection' {

            $ThisObject = @{}

            ForEach ($ThisProperty in $Value.Keys) {

                $ThisPropertyString = ConvertFrom-PropertyValueCollectionToString -PropertyValueCollection $Value[$ThisProperty]
                $ThisObject[$ThisProperty] = $ThisPropertyString

                # This copies the properties up to the top level.
                # Want to remove this later
                # The nested pscustomobject accomplishes the goal of removing hashtables and PropertyValueCollections and PropertyCollections
                # But I may have existing functionality expecting these properties so I am not yet ready to remove this
                # When I am, I should move this code into a ConvertFrom-PropertyCollection function in the Adsi module
                $PropertyDictionary["$Prefix$ThisProperty"] = $ThisPropertyString

            }

            $PropertyDictionary["$Prefix$Property"] = [PSCustomObject]$ThisObject
            return

        }
        'System.DirectoryServices.PropertyValueCollection' {
            $PropertyDictionary["$Prefix$Property"] = ConvertFrom-PropertyValueCollectionToString -PropertyValueCollection $Value
            return
        }
        'System.Object[]' {
            $PropertyDictionary["$Prefix$Property"] = $Value
            return
        }
        'System.Object' {
            $PropertyDictionary["$Prefix$Property"] = $Value
            return
        }
        'System.DirectoryServices.SearchResult' {
            $PropertyDictionary["$Prefix$Property"] = ConvertFrom-SearchResult -SearchResult $Value
            return
        }
        'System.DirectoryServices.ResultPropertyCollection' {
            $ThisObject = @{}

            ForEach ($ThisProperty in $Value.Keys) {
                $ThisPropertyString = ConvertFrom-ResultPropertyValueCollectionToString -ResultPropertyValueCollection $Value[$ThisProperty]
                $ThisObject[$ThisProperty] = $ThisPropertyString

                # This copies the properties up to the top level.
                # Want to remove this later
                # The nested pscustomobject accomplishes the goal of removing hashtables and PropertyValueCollections and PropertyCollections
                # But I may have existing functionality expecting these properties so I am not yet ready to remove this
                # When I am, I should move this code into a ConvertFrom-PropertyCollection function in the Adsi module
                $PropertyDictionary["$Prefix$ThisProperty"] = $ThisPropertyString

            }
            $PropertyDictionary["$Prefix$Property"] = [PSCustomObject]$ThisObject
            return
        }
        'System.DirectoryServices.ResultPropertyValueCollection' {
            $PropertyDictionary["$Prefix$Property"] = ConvertFrom-ResultPropertyValueCollectionToString -ResultPropertyValueCollection $Value
            return
        }
        'System.Management.Automation.PSCustomObject' {
            $PropertyDictionary["$Prefix$Property"] = $Value
            return
        }
        'System.Collections.Hashtable' {
            $PropertyDictionary["$Prefix$Property"] = [PSCustomObject]$Value
            return
        }
        'System.Byte[]' {
            $PropertyDictionary["$Prefix$Property"] = ConvertTo-DecStringRepresentation -ByteArray $Value
            return
        }
        default {
            <#
                By default we will just let most types get cast as a string
                Includes but not limited to:
                    $null (because GetType is not implemented)
                    System.String
                    System.Boolean
            #>
            $PropertyDictionary["$Prefix$Property"] = "$Value"
            return

        }

    }

}
