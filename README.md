# PowershellClassLoader
A dynamic class loader utility for use in modules. Detects inter class dependencies and builds required load sequence as well as detecting circular dependencies.

## Introduction
Currently there is no solution within a Powershell module to dynamically determine class load sequence. This becomes an issue if you have inter-class dependencies within the target module.
The alternative to dynamically determining load order is to maintain a static list to process during module import; this is suboptimal as it requires maintenance.

*Note:* This repository doesn't aim to provide any strong opinion or reference for overall module structure.

## How it works
The following article was used to generate the algorithm in Powershell:
- https://www.electricmonk.nl/docs/dependency_resolving_algorithm/dependency_resolving_algorithm.html

1. Each class file (determined by search in module structure which can be adapted as needed to target) is processed via the Powershell Abstract Syntax Tree and the following declarations are noted:
    - Strong type casting of variables, ie: `[MyClass]$myVariable`
      - If the type is not known to the runtime it is assumed to be required and neccessary within the module
    - Static property or method usage of a type, ie: `$myVariable = [MyClass]::MyStaticProperty`
    - `New-Object` declarations creating a TypeName by explicit parameter usage or by inferred parameter ordering.
2. As each file is processed, should any of the above be found the class is sent into another helper function which uses the AST to find the class file which exposes the Type.

## Requirements
1. Keep your classes in a discrete directory from that of your function definitions.

## How to use
1. Add the helper functions into your module
   - Again, this repository doesn't aim to make recommendations on structure.... put there wherever makes you happy.
2. Paste the logic from within the PowershellClassLoader.psm1 into your psm1 and adapt the following variables to suit your module structure:
   - `$functionsPath`
   - `$classesPath`

## Unit Testing
1. Watch this space