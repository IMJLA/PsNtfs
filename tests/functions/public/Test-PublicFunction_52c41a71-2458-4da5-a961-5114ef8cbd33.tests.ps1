$ScriptName = 'Test-PublicFunction_52c41a71-2458-4da5-a961-5114ef8cbd33.ps1'
$ScriptPath = "$($PSScriptRoot -replace 'tests','src')\$ScriptName"

Describe "'$ScriptName' Function Tests" {
    # TestCases are splatted to the script so we need hashtables
    $validPowerShellTestCase = @{Script = $ScriptPath }
    It "Script '<Script>' is valid PowerShell" -TestCases $validPowerShellTestCase {
        param ($Script)
        $ScriptContents = Get-Content -LiteralPath $Script -ErrorAction Stop
        $Errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($ScriptContents, [ref]$Errors)
        $Errors.Count | Should -Be 0
    }

    $noErrorsTestCase = @{ThisScriptPath = $ScriptPath }
    It "Script file '$ScriptName' can be run without any errors" -TestCases $noErrorsTestCase {
        param ($ThisScriptPath)
        { . $ThisScriptPath } | Should -Not -Throw
    }

}


