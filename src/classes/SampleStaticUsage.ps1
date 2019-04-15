class SampleStaticUsage {
    #region properties
    $DataCache = $null
    #endregion

    #region default constructor
    SampleStaticUsage([string]$ComputerName) {
        [DataCache]::New($ComputerName)
        #[CircularDependency]::New()
    }
    #endregion

    #region methods
    [void] DoSomething() {
        New-Object -TypeName DataCache -ArgumentList @($ENV:COMPUTERNAME)
        New-Object DataCache @($ENV:COMPUTERNAME)
    }
    #endregion
}