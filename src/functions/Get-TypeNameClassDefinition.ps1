function Get-TypeNameClassDefinition {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeLine = $True)]
        [String]$TypeName,
        [Parameter(Position = 1, Mandatory = $True, ValueFromPipeLine = $True)]
        [string[]]$ClassPaths
    )
    begin {
        $result = $null
    }
    process {
        # loop classes and try to find type definition
        $tokens = $null
        $errors = $null
        :lookup foreach ($classPath in $ClassPaths) {
            $parsedScriptFile = [Management.Automation.Language.Parser]::ParseInput((Get-Content -Path $classPath), [ref]$tokens, [ref]$errors)
            $parsedScriptFile.FindAll([Func[Management.Automation.Language.Ast,bool]]{
                param([System.Management.Automation.Language.Ast] $Ast)
                end {
                    return ($Ast -is [System.Management.Automation.Language.TypeDefinitionAst])
                }
            }, $true) | ForEach-Object {
                if ($_.Name -ieq $TypeName -and $_.IsClass) {
                    $result = $classPath
                    break lookup
                }
            }
        }
    }
    end {
        return $result
    }
}