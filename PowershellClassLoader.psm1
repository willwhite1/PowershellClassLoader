# ========================================== #
# Prepare for module and dependency import   #
# ========================================== #
$currentModulePaths = $env:PSModulePath.Split(';')
$moduleFolder = Split-Path -Parent $MyInvocation.MyCommand.Path

# ========================================== #
# Perform module import operations           #
# ========================================== #

# global variables used in helpers to keep track
$Global:ResolvedDependencies = @()
$Global:Seen = @()

# CHANGE THESE TO MEET YOUR MODULE STRUCTURE
$functionsPath = "$($moduleFolder)\src\functions"
$classesPath = "$($moduleFolder)\src\classes"

# We need to import helper functions
$requiredFunctions = @("Get-ClassDependencyGraph", "Get-TypeNameClassDefinition", "Resolve-Dependency")
$missingRequirements = @()
foreach ($function in $requiredFunctions) {
    $functionPath = "$($functionsPath)\$($function).ps1"
    if (-not (Test-Path $functionPath)) {
        $missingRequirements += $functionPath
    }
    else {
        . $functionPath
    }
}
# abort now if we couldn't load all required helpers
if ($missingRequirements.Count -gt 0) {
    throw "Unable to locate required helper functions:`n$($missingRequirements | Out-String)"
}

# get a list of all classes
$classFiles = Get-ChildItem -Path $classesPath -Filter "*.ps1"
if ($classFiles) {
    Write-Verbose "Resolving Class Dependency Tree..." -Verbose
    $dependencyOrder = (Get-ClassDependencyGraph -Classes $classFiles.FullName)
    Write-Verbose "Importing Dependency Tree:`n$($Global:ResolvedDependencies | Out-String)" -Verbose
    $Global:ResolvedDependencies | ForEach-Object {
        $cPath = Get-TypeNameClassDefinition -TypeName $_ -ClassPaths $classFiles.FullName
        . $cPath
    }
}

# nullify the created globals
Remove-Variable -Name "ResolvedDependencies" -Scope Global
Remove-Variable -Name "Seen" -Scope Global

# ========================================== #
# Additional actions specific to the module  #
# ========================================== #

# Add additional steps here