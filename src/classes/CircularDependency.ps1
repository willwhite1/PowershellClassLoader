class CircularDependency {
    #region properties
    $DataCache = $null
    #endregion

    #region default constructor
    CircularDependency([string]$ComputerName) {
        [SampleStaticUsage]::New($ComputerName)
        [DataCache]::New($ComputerName)
    }
    #endregion

    #region methods
    [void] DoSomething() {
    }
    #endregion
}