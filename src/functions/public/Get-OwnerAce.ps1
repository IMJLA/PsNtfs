function Get-OwnerAce {

    param (

        # Path to the parent item whose owners to export
        [string]$Item,

        # Thread-safe cache of items and their owners
        [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]$OwnerCache = [System.Collections.Concurrent.ConcurrentDictionary[String, PSCustomObject]]::new()
    )

    return

}
