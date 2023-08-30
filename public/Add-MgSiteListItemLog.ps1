Function Add-MgSiteListItemLog {

    [CmdletBinding()]
    param (

        [Parameter(Mandatory, ValueFromPipeline)]
        [object[]]
        $InputObject,

        [Parameter(Mandatory)]
        [object]
        $SiteId,

        [Parameter(Mandatory)]
        [object]
        $ListId,

        [Parameter(Mandatory)]
        [object]
        $ListItemId

    )

    begin {

        $MgSiteListItemParams = @{
            SiteId      = $SiteId
            ListId      = $ListId
            ListItemId  = $ListItemId
            ErrorAction = 'Stop'
        }

        $Get = Get-MgSiteListItem @MgSiteListItemParams
        $Log = $Get.Fields.AdditionalProperties.Log

    }

    process {

        $InputObject | ForEach-Object {
            $Log += "`n$_"
        }

    }

    end {

        $UpdateMgSiteListItemParams = $MgSiteListItemParams
        $UpdateMgSiteListItemParams.BodyParameter = @{
            fields = @{
                Log = $Log
            }
        }
        Update-MgSiteListItem @UpdateMgSiteListItemParams

    }

}
