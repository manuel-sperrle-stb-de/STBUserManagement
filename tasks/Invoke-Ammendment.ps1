Get-ChildItem "$PSScriptRoot/../public" -Recurse -Filter *.ps1 | ForEach-Object { . $_.FullName }
. (Join-Path $PSScriptRoot 'Get-AmmendmentFromMgSiteListConfiguration.ps1')

#TBD : DateTime
$AmmendmentFilter = Get-AmmendmentFromMgSiteListConfiguration | Where-Object { -not $_.Meta.Fields.Done -and $_.Meta.Fields.Go }

ForEach ($Ammendment in $AmmendmentFilter) {

    [string[]]$Log = @()
    $SyncAzureADTrigger = $false

    $MgSiteListItem = @{
        SiteId      = $Ammendment.Meta.SiteId
        ListId      = $Ammendment.Meta.ListId
        ListItemId  = $Ammendment.Meta.ListItemId
        ErrorAction = 'Stop'
    }

    # Add-ADUser
    if ($Ammendment.Ammendment.Action -eq 'Add' -and -not $Ammendment.Meta.Fields.ad) {
        $Message = 'Check for ADUser'
        $Message | Write-Host
        $Log += $Message
        #'Add-ADUser ...' | Write-Host
        $SyncAzureADTrigger = $true
    }

    if ($SyncAzureADTrigger) {
        # TBD: Sync AD Connect!
    }

    # TBD: Set-ADUser

    # ADUser exists - check field mg
    if($Ammendment.Ammendment.Action -eq 'Add' -and $Ammendment.Meta.Fields.ad -and -not $Ammendment.Meta.Fields.mg) {

        $Message = 'Get-MgUser'
        $Message | Write-Host
        $Log += $Message

        $MgUser = Get-MgUser -ConsistencyLevel eventual -Filter "startsWith(UserPrincipalName, '$($Ammendment.Request.MgUser.UserPrincipalName)')"

        if ($MgUser) {

            $Message = 'MgUser found -> Update Field: mg'
            $Message | Write-Host
            $Log += $Message
    
            $UpdateMgSiteListItemParams = $MgSiteListItem.Clone()
            $UpdateMgSiteListItemParams.BodyParameter = @{
                fields = @{
                    mg = $MgUser.Id
                }
            }
            Update-MgSiteListItem @UpdateMgSiteListItemParams

        }

    }

    # Tags

    # MFA

    # License

    # PhoneAssignment

    if ($Log) { $Log | Add-MgSiteListItemLog @MgSiteListItem }

}