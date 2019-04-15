class DataCache {
    #region properties
    [string]$CacheFilePath = ""
    [PSCustomObject]$CacheData = @{}
    #endregion

    #region default constructor
    DataCache([string]$ComputerName) {
        $tempFile = (New-TemporaryFile).FullName
        Add-Content -Path $tempFile -Value "{`"$($ComputerName)`": {}}"
        $this.CacheFilePath = $tempFile
        $this.Refresh()
    }
    #endregion

    #region methods
    [void] Add([string]$ComputerName, [string]$Name, [object]$Value) {
        # refresh first
        $this.Refresh()

        # add
        if (($this.CacheData."$ComputerName")."$Name") {
            ($this.CacheData."$ComputerName")."$Name" = $Value
        }
        else {
            ($this.CacheData."$ComputerName") | Add-Member -Name $Name -Value $Value -MemberType NoteProperty
        }

        # save
        $this.Save()
    }
    [void] Remove([string]$ComputerName, [string]$Name) {
        # refresh first
        $this.Refresh()

        # remove
        if (($this.CacheData."$ComputerName")."$Name") {
            ($this.CacheData."$ComputerName".PSObject.Properties).Remove($Name)
        }

        # save
        $this.Save()
    }
    hidden [void] Refresh() {
        # get latest data
        $this.CacheData = ConvertFrom-Json -InputObject ([string](Get-Content -Path $this.CacheFilePath))
    }
    hidden [void] Save() {
        # get latest data
        ConvertTo-Json -InputObject $this.CacheData -Depth 100 | Set-Content -Path $this.CacheFilePath
    }
    #endregion
}