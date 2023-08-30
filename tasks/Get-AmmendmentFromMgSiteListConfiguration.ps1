function Get-AmmendmentFromMgSiteListConfiguration {

    param (
        $MgSiteDisplayName = (Get-Content (Join-Path $PSScriptRoot 'Configuration\MgSiteDisplayName')),
        $MgSiteListDisplayName = (Get-Content (Join-Path $PSScriptRoot 'Configuration\MgSiteListDisplayName'))
    )

    Get-ChildItem "$PSScriptRoot/../public" -Recurse -Filter *.ps1 | ForEach-Object { . $_.FullName }

    $ConnectMgGraphParams = @{
    }
    Connect-MgGraph @ConnectMgGraphParams
    
    $GetAmmendmentFromMgSiteListItemByDisplayNameParams = @{
        MgSiteDisplayName = $MgSiteDisplayName
        MgSiteListDisplayName = $MgSiteListDisplayName
    }
    
    Get-AmmendmentFromMgSiteListItemByDisplayName @GetAmmendmentFromMgSiteListItemByDisplayNameParams
    
}
