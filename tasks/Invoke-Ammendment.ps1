Get-ChildItem "$PSScriptRoot/../public" -Recurse -Filter *.ps1 | ForEach-Object { . $_.FullName }
. (Join-Path $PSScriptRoot 'Get-AmmendmentFromMgSiteListConfiguration.ps1')

$LogFile = Join-Path $PSScriptRoot ('log\{0}.{1}.log' -f $MyInvocation.MyCommand.Name, ((Get-Date -Format s) -replace '[^\d]', $null) )
try { Stop-Transcript } catch {}
Start-Transcript $LogFile -Verbose

try {

    #TBD : DateTime
    $AmmendmentFilter = Get-AmmendmentFromMgSiteListConfiguration | Where-Object { -not $_.Meta.Fields.Done -and $_.Meta.Fields.Go }

    ForEach ($Ammendment in $AmmendmentFilter) {

        [string[]]$Log = @()

        $MgSiteListItem = @{
            SiteId      = $Ammendment.Meta.SiteId
            ListId      = $Ammendment.Meta.ListId
            ListItemId  = $Ammendment.Meta.ListItemId
            ErrorAction = 'Stop'
        }

        $Ammendment.Ammendment, $Ammendment.Meta.Fields.UserPrincipalName | ConvertTo-Json

        # Add AdUser
        if ($Ammendment.Ammendment.Action -like 'Add' -and $Ammendment.Ammendment.Target -like 'AdUser') {

            # Add-ADUser
            if (-not $Ammendment.Meta.Fields.ad) {
                $Message = 'Check for ADUser'
                $Message
                $Log += $Message
                #'Add-ADUser ...'
                $SyncAzureADTrigger = $true
            }

            # TBD: Set-ADUser

        }

        # Update AdUser
        if ($Ammendment.Ammendment.Action -like 'Update' -and $Ammendment.Ammendment.Type -like 'AdUser') {
        }

        # Remove AdUser
        if ($Ammendment.Ammendment.Action -like 'Remove' -and $Ammendment.Ammendment.Type -like 'AdUser') {
        }

        $SyncAzureADTrigger = $false
        if ($SyncAzureADTrigger) {
            # TBD: Sync AD Connect!
        }

        # AdUser exists -> check field mg
        if ($Ammendment.Ammendment.Action -like 'Add' -and $Ammendment.Ammendment.Type -like 'AdUser' -and $Ammendment.Meta.Fields.ad -and -not $Ammendment.Meta.Fields.mg) {

            $Message = 'Get-MgUser'
            $Message
            $Log += $Message

            $MgUser = Get-MgUser -ConsistencyLevel eventual -Filter "startsWith(UserPrincipalName, '$($Ammendment.Request.MgUser.UserPrincipalName)')"

            if ($MgUser) {

                $Message = 'MgUser found -> Update Field: mg'
                $Message
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

        # Up to here all should have a synced! MgUser Account
        $MgUser = Get-MgUser -ConsistencyLevel eventual -Filter "startsWith(UserPrincipalName, '$($Ammendment.Request.MgUser.UserPrincipalName)')"

        if (-not $MgUser) {
            $Message = 'Critical Error: MgUser not found'
            $Message | Write-Error
            $Log += $Message
        }

        # MgUser exists!
        if ($MgUser -and $Ammendment.Ammendment.Action -like 'Add' -or $Ammendment.Ammendment.Action -like 'Update' -and $Ammendment.Meta.Fields.mg) {

            $Request = $Ammendment.Request

            if ($Request.MgUserAuthenticationEmailMethod) {
                'MgUserAuthenticationEmailMethod'

                $MgUserAuthenticationEmailMethod = Get-MgUserAuthenticationEmailMethod -UserId $MgUser.Id -ErrorAction SilentlyContinue

                if ($MgUserAuthenticationEmailMethod) {

                    $UpdateMgUserAuthenticationEmailMethodParams = @{
                        EmailAuthenticationMethodId = $MgUserAuthenticationEmailMethod.Id
                        UserId                      = $MgUser.Id
                        BodyParameter               = $Request.MgUserAuthenticationEmailMethod
                    }
                    Update-MgUserAuthenticationEmailMethod @UpdateMgUserAuthenticationEmailMethodParams

                }
                else {

                    $NewMgUserAuthenticationEmailMethodParams = @{
                        UserId        = $MgUser.Id
                        BodyParameter = $Request.MgUserAuthenticationEmailMethod
                    }
                    New-MgUserAuthenticationEmailMethod @NewMgUserAuthenticationEmailMethodParams

                }

                Get-MgUserAuthenticationEmailMethod -UserId $MgUser.Id

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

                    Update-MgUserAuthenticationPhoneMethod @UpdateMgUserAuthenticationPhoneMethodParams

                }
                else {

                    $NewMgUserAuthenticationPhoneMethodParams = @{
                        UserId        = $MgUser.Id
                        BodyParameter = $Request.MgUserAuthenticationPhoneMethod
                    }

                    New-MgUserAuthenticationPhoneMethod @NewMgUserAuthenticationPhoneMethodParams

                }

                Get-MgUserAuthenticationPhoneMethod -UserId $MgUser.Id

            }

            # License

            # Tags

            # Groups

            # PhoneAssignment

            # StrongAuthentificationRequirement


        }

        #if ($Log) { $Log | Add-MgSiteListItemLog @MgSiteListItem }

    }

}
catch {
    Stop-Transcript -Verbose
}
Stop-Transcript -Verbose
