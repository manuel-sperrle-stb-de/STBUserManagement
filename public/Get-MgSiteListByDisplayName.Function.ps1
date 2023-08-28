Function Get-MgSiteListByDisplayName {

    [CmdletBinding()]
    param (

        # DisplayName
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $DisplayName,

        # MgSite object
        [Parameter(Mandatory)]
        [object]
        $MgSite

    )

    process {
        $DisplayName | ForEach-Object {
            # server side filter
            $GetMgSiteListParams = @{
                SiteId = $MgSite.Id
                Filter = "DisplayName eq '{0}'" -f $_
            }
            Get-MgSiteList @GetMgSiteListParams
        }
    }

}
