param (
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

$Ammendments | Where-Object { $_.Meta.Fields.Go -and -not $_.Meta.Fields.Done -and $_.Ammendment.Type -eq 'MgUser' -and $_.Ammendment.Action -in $Conventions.Actions.Add } | ForEach-Object {

    $Request = $_.Request
    $MgUser = Get-MgUser -UserId $Request.MgUser.Id -ErrorAction SilentlyContinue

    if (-not $MgUser) {
        try {
            $NewMgUserParams = $_.Request.MgUser
            $MgUser = New-MgUser @NewMgUserParams
        }
        catch {
            # Add failure report to ammendment Answer
            $_
        }
    }

    if ($MgUser -and $Request.MgUserAuthenticationEmailMethod) {

        'MgUserAuthenticationEmailMethod'
        $MgUserAuthenticationEmailMethod = Get-MgUserAuthenticationEmailMethod -UserId $MgUser.Id -ErrorAction SilentlyContinue

        if ($MgUserAuthenticationEmailMethod) {

            $UpdateMgUserAuthenticationEmailMethodParams = @{
                EmailAuthenticationMethodId = $MgUserAuthenticationEmailMethod.Id
                UserId                      = $MgUser.Id
                BodyParameter               = $Request.MgUserAuthenticationEmailMethod
            }
            'Update'
            Update-MgUserAuthenticationEmailMethod @UpdateMgUserAuthenticationEmailMethodParams | Format-List

        }
        else {

            $NewMgUserAuthenticationEmailMethodParams = @{
                UserId        = $MgUser.Id
                BodyParameter = $Request.MgUserAuthenticationEmailMethod
            }
            'New'
            New-MgUserAuthenticationEmailMethod @NewMgUserAuthenticationEmailMethodParams | Format-List

        }

        'Get'
        Get-MgUserAuthenticationEmailMethod -UserId $MgUser.Id | Format-List

    }

    if ($MgUser -and $Request.MgUserAuthenticationPhoneMethod) {

        'MgUserAuthenticationPhoneMethod'
        $MgUserAuthenticationPhoneMethod = Get-MgUserAuthenticationPhoneMethod -UserId $MgUser.Id -ErrorAction SilentlyContinue

        if ($MgUserAuthenticationPhoneMethod) {

            $UpdateMgUserAuthenticationPhoneMethodParams = @{
                PhoneAuthenticationMethodId = $MgUserAuthenticationPhoneMethod.Id
                UserId                      = $MgUser.Id
                BodyParameter               = $Request.MgUserAuthenticationPhoneMethod
            }
            'Update'
            Update-MgUserAuthenticationPhoneMethod @UpdateMgUserAuthenticationPhoneMethodParams | Format-List

        }
        else {

            $NewMgUserAuthenticationPhoneMethodParams = @{
                UserId        = $MgUser.Id
                BodyParameter = $Request.MgUserAuthenticationPhoneMethod
            }
            'New'
            New-MgUserAuthenticationPhoneMethod @NewMgUserAuthenticationPhoneMethodParams | Format-List

        }

        'Get'
        Get-MgUserAuthenticationPhoneMethod -UserId $MgUser.Id | Format-List

    }

    # TBD: Licenses

    # TBD: SageHR
    # TBD: SnipeIt
    # TBD: Zammad

}
