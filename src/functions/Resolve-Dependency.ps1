function Resolve-Dependency {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $True, ValueFromPipeLine = $True)]
        [PSCustomObject]$Node,
        [Parameter(Position = 1, Mandatory = $True, ValueFromPipeLine = $True)]
        [PSCustomObject[]]$AllNodes
    )
    begin {}
    process {
        Write-Verbose "Resolving TypeName '$($Node.TypeName)'"
        $Global:Seen += $Node.TypeName
        foreach ($edge in $Node.Dependencies) {
            $tNode = $AllNodes | Where-Object {$_.TypeName -ieq $edge.TypeName}
            if (-not ($Global:ResolvedDependencies -icontains $tNode.TypeName)) {
                if ($Global:Seen -icontains $tNode.TypeName) {
                    throw "Circular dependency found $($Node.TypeName) -> $($tNode.TypeName)"
                }
                Resolve-Dependency -Node $tNode -AllNodes $AllNodes
            }
        }
        if (-not ($Global:ResolvedDependencies -icontains $Node.TypeName)) {
            $Global:ResolvedDependencies += $Node.TypeName
        }
    }
    end {} 
}