function Get-ClassDependencyGraph {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeLine = $True)]
        [String[]]$Classes
    )
    begin {
        $fullySatisfiedGraph = $true
    }
    process {
        # isolate dependencies first
        [array]$depList = @()
        foreach ($class in $Classes) {
            $content = Get-Content -Path $class -Raw
            $depCheck = ([PSCustomObject]@{
                TypeName = $null
                ClassDefinition = $class
                Dependencies = @()
            })
            # static ref search
            $tokens = $null
            $errors = $null
            $parsedScriptFile = [Management.Automation.Language.Parser]::ParseInput($content, [ref]$tokens, [ref]$errors)
            $depCheck.TypeName = ($parsedScriptFile.EndBlock.Statements | Where-Object {$_.IsClass}).Name

            $staticRefs = $parsedScriptFile.EndBlock.FindAll({
                $args[0] -is [Management.Automation.Language.InvokeMemberExpressionAst]
            }, $true)
            $typeCastingRefs = $parsedScriptFile.EndBlock.FindAll({
                $args[0] -is [Management.Automation.Language.TypeConstraintAst]
            }, $true)
            # using string splitting for now whilst AST is fully investigated
            if ($typeCastingRefs) {
                foreach ($typeCastingRef in $typeCastingRefs) {
                    if ($typeCastingRef.Extent.Text) {
                        $typeName = $typeCastingRef.Extent.Text.Trim("[]")
                        Write-Verbose "Found static usage of type '$($typeName)' in '$($class)'"
                        # if we don't know this type we can only assume it is a dependency
                        if (-not ([System.Management.Automation.PSTypeName]"$($typeName)").Type) {
                            # if we can't find a definition which matches this requirement we need to know
                            if (-not ($definitionPath = Get-TypeNameClassDefinition -ClassPaths $Classes -TypeName $typeName)) {
                                $fullySatisfiedGraph = $false
                                Write-Warning "Unable to find Type Definition file for Type '$($typeName)'"
                            }
                            # we found it
                            else {
                                Write-Verbose "Type '$($typeName)' definition was found in path '$($definitionPath)'"
                                $depCheck.Dependencies += ([PSCustomObject]@{
                                    TypeName = $typeName
                                    TypeDefinition = $definitionPath
                                })
                            }
                        }
                        else {
                            Write-Verbose "Type '$($typeName)' is known to runtime, no dependency mapping required."
                        }
                    }
                }
            }
            # using string splitting for now whilst AST is fully investigated
            if ($staticRefs) {
                foreach ($staticRef in $staticRefs) {
                    if ($staticRef.Expression.TypeName) {
                        $typeName = $staticRef.Expression.TypeName.Name
                        Write-Verbose "Found static usage of type '$($typeName)' in '$($class)'"
                        # if we don't know this type we can only assume it is a dependency
                        if (-not ([System.Management.Automation.PSTypeName]"$($typeName)").Type) {
                            # if we can't find a definition which matches this requirement we need to know
                            if (-not ($definitionPath = Get-TypeNameClassDefinition -ClassPaths $Classes -TypeName $typeName)) {
                                $fullySatisfiedGraph = $false
                                Write-Warning "Unable to find Type Definition file for Type '$($typeName)'"
                            }
                            # we found it
                            else {
                                Write-Verbose "Type '$($typeName)' definition was found in path '$($definitionPath)'"
                                $depCheck.Dependencies += ([PSCustomObject]@{
                                    TypeName = $typeName
                                    TypeDefinition = $definitionPath
                                })
                            }
                        }
                        else {
                            Write-Verbose "Type '$($typeName)' is known to runtime, no dependency mapping required."
                        }
                    }
                }
            }
            # could also be New-Object instantiations
            if ($content -imatch "New-Object") {
                $newObjects = $parsedScriptFile.EndBlock.FindAll({
                    ($args[0] -is [System.Management.Automation.Language.CommandAst])
                }, $true)
                foreach ($newObject in $newObjects) {
                    $elements = $newObject.CommandElements
                    if (-not ($inspectionTarget = $elements | Where-Object {$_.ParameterName -ieq "TypeName"})) {
                        # could be unnamed parameter at position 0 in args
                        $typeName = $elements[1].Value
                    }
                    else {
                        # need to add 1 to the position at which typename is found
                        $c = 0
                        :seek foreach ($item in $elements) {
                            if ($item.ParameterName -ieq "TypeName") {
                                break seek
                            }
                            $c++
                        }
                        $typeName = ($elements[$c + 1]).Value
                    }
                    Write-Verbose "Found New-Object usage of type '$($typeName)' in '$($class)'"
                    # if we don't know this type we can only assume it is a dependency
                    if (-not ([System.Management.Automation.PSTypeName]"$($typeName)").Type) {
                        # if we can't find a definition which matches this requirement we need to know
                        if (-not ($definitionPath = Get-TypeNameClassDefinition -ClassPaths $Classes -TypeName $typeName)) {
                            $fullySatisfiedGraph = $false
                            Write-Warning "Unable to find Type Definition file for Type '$($typeName)'"
                        }
                        # we found it
                        else {
                            $depCheck.Dependencies += ([PSCustomObject]@{
                                TypeName = $typeName
                                TypeDefinition = $definitionPath
                            })
                        }
                    }
                    else {
                        Write-Verbose "Type '$($typeName)' is known to runtime, no dependency mapping required."
                    }
                }
            }

            # add to list
            $depList += $depCheck
        }

        # start with item 0
        $Global:ResolvedDependencies = @()
        $Global:Seen = @()
        $depList | ForEach-Object {
            Resolve-Dependency -Node $_ -AllNodes $depList
        }
    }
    end {
        #Write-Output $outArray
    }
}