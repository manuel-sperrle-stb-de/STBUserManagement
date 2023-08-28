Function Get-MgSiteListItemSTB {

    [CmdletBinding()]
    param (

        [Parameter(Mandatory)]
        [object]
        $MgSite,

        [Parameter(Mandatory)]
        [object]
        $MgSiteList

    )

    $GetMgSiteListItemParams = @{
        SiteId         = $MgSite.Id
        ListId         = $MgSiteList.Id
        ExpandProperty = 'fields'
    }

    Get-MgSiteListItem @GetMgSiteListItemParams | Select-Object @(
        @{
            n = 'SiteId'
            e = { $MgSite.Id }
        }
        @{
            n = 'ListId'
            e = { $MgSiteList.Id }
        }
        @{
            n = 'ListItemId'
            e = { $_.Id }
        }
        '*'
    )

}
