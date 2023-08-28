﻿param (
    $MgSiteDisplayName = (Get-Content (Join-Path $PSScriptRoot 'Configuration\MgSiteDisplayName')),
    $MgSiteListDisplayName = (Get-Content (Join-Path $PSScriptRoot 'Configuration\MgSiteListDisplayName'))
)

'Loading Functions ...' | Write-Host
Get-ChildItem $PSScriptRoot/.. -Recurse -Filter *.Function.ps1 | ForEach-Object {
    $_.BaseName.TrimEnd('.Function') | Write-Host
    . $_.FullName
}

'PSDefaultParameterValues ...' | Write-Host
$PSDefaultParameterValues['Connect-MgGraph:Scopes'] = @(
    "Sites.Read.All"
    "Sites.ReadWrite.All"
)
$PSDefaultParameterValues['Get-MgSiteByDisplayName:DisplayName'] = $MgSiteDisplayName
$PSDefaultParameterValues['Get-MgSiteListByDisplayName:DisplayName'] = $MgSiteListDisplayName

'Connect-MgGraph ...' | Write-Host
Connect-MgGraph

'Get-MgSiteByDisplayName "{0}" ...' -f $MgSiteDisplayName | Write-Host
$MgSite = Get-MgSiteByDisplayName
$PSDefaultParameterValues['Get-MgSiteListByDisplayName:MgSite'] = $MgSite
$PSDefaultParameterValues['Get-AmmendmentsFromMgSiteListItems:MgSite'] = $MgSite
if (-not $MgSite.Id) { throw "MgSite could not be resolved" }
$MgSite.Id | Write-Host

'Get-MgSiteListByDisplayName "{0}" ...' -f $MgSiteListDisplayName | Write-Host
$MgSiteList = Get-MgSiteListByDisplayName
$PSDefaultParameterValues['Get-AmmendmentsFromMgSiteListItems:MgSiteList'] = $MgSiteList
if (-not $MgSiteList.Id) { throw "MgSiteList could not be resolved" }
$MgSiteList.Id | Write-Host

'Get-AmmendmentsFromMgSiteListItems ...' | Write-Host
$Ammendments = Get-AmmendmentsFromMgSiteListItems


# -----

$Conventions = @{
    Actions = @{
        Add    = @("Add", "New", "Create")
        Update = @("Update")
        Remove = @("Remove", "Delete")
    }
}

$Ammendments | Where-Object { $_.Meta.Fields.Go -and -not $_.Meta.Fields.Done -and $_.Ammendment.Type -like 'ADUser' -and $_.Ammendment.Action -in $Conventions.Actions.Add } | ForEach-Object {

    $_ | ConvertTo-Json -Depth 4

    $MgSiteListItemLogParams = @{
        SiteId     = $_.Meta.SiteId
        ListId     = $_.Meta.ListId
        ListItemId = $_.Meta.ListItemId
    }

    $ADUserRequest = $_.Request.ADUser

    # ProxyAddresses

    # Do
    $ADUser = New-ADUser @ADUserRequest
    $ADUser | Add-MgSiteListItemLog @MgSiteListItemLogParams

}