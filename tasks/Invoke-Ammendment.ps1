#Requires -Modules @{ ModuleName="ActiveDirectory"; ModuleVersion="1.0.1.0" }, @{ ModuleName="ADSync"; ModuleVersion="1.0.0.0" }, @{ ModuleName="Microsoft.Graph.Authentication"; ModuleVersion="2.4.0" }, @{ ModuleName="Microsoft.Graph.Users"; ModuleVersion="2.4.0" }

Get-ChildItem "$PSScriptRoot/../public" -Recurse -Filter *.ps1 | ForEach-Object { . $_.FullName }
. (Join-Path $PSScriptRoot 'Get-AmmendmentFromMgSiteListConfiguration.ps1')

$LogFile = Join-Path $PSScriptRoot ('log\{0}.{1}.log' -f $MyInvocation.MyCommand.Name, ((Get-Date -Format s) -replace '[^\d]', $null) )
try { Stop-Transcript } catch {}
Start-Transcript $LogFile -Verbose

try {

    $AzureADConnectTrigger = $false

    # TBD : Filter for DateTime
    $AmmendmentFilter = Get-AmmendmentFromMgSiteListConfiguration | Where-Object { -not $_.Meta.Fields.Done -and $_.Meta.Fields.Go }

    # ForEach AdUser
    ForEach ($Ammendment in ( $AmmendmentFilter | Where-Object { $Ammendment.Ammendment.Target -like 'AdUser' } )) {

        [string[]]$Log = @()
        $Ammendment.Ammendment, $Ammendment.Meta.Fields.UserPrincipalName | ConvertTo-Json

        $MgSiteListItem = @{
            SiteId      = $Ammendment.Meta.SiteId
            ListId      = $Ammendment.Meta.ListId
            ListItemId  = $Ammendment.Meta.ListItemId
            ErrorAction = 'Stop'
        }

        # ShortHand
        $Request = $Ammendment.Request

        # Add AdUser
        if ($Ammendment.Ammendment.Action -like 'Add') {

            # Add-ADUser
            if (-not $Ammendment.Meta.Fields.ad) {
                $Message = 'Check for ADUser'
                $Message
                $Log += $Message
                #'Add-ADUser ...'
                $AzureADConnectTrigger = $true
            }

            # TBD: Set-ADUser

        }

        # Update AdUser
        if ($Ammendment.Ammendment.Action -like 'Update') {
        }

        # Remove AdUser
        if ($Ammendment.Ammendment.Action -like 'Remove') {
        }

        #if ($Log) { $Log | Add-MgSiteListItemLog @MgSiteListItem }

    }

    # AzureADConnect
    if ($AzureADConnectTrigger) {
        'AzureADConnect triggered'

        Start-ADSyncSyncCycle -PolicyType Delta
        # TBD: AzureADConnect
    }

    # ForEach
    ForEach ($Ammendment in $AmmendmentFilter) {

        [string[]]$Log = @()
        $Ammendment.Ammendment, $Ammendment.Meta.Fields.UserPrincipalName | ConvertTo-Json

        $MgSiteListItem = @{
            SiteId      = $Ammendment.Meta.SiteId
            ListId      = $Ammendment.Meta.ListId
            ListItemId  = $Ammendment.Meta.ListItemId
            ErrorAction = 'Stop'
        }

        # ShortHand
        $Request = $Ammendment.Request

        'Get-MgUser'
        $MgUser = Get-MgUser -ConsistencyLevel eventual -Filter "startsWith(UserPrincipalName, '$($Ammendment.Request.MgUser.UserPrincipalName)')" -ErrorAction Stop
        if (-not $MgUser) {
            $Message = 'Critical Error: MgUser not found'
            $Message | Write-Error
            $Log += $Message
        }


        'Update Field: mg'
        if ($Ammendment.Meta.Fields.ad -and -not $Ammendment.Meta.Fields.mg -and $Ammendment.Ammendment.Action -notlike 'Remove') {

            $Message = 'Update Field: mg'
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


        # MgUserAuthenticationEmailMethod
        if ($Request.MgUserAuthenticationEmailMethod.EmailAddress -and $Ammendment.Ammendment.Action -notlike 'Remove') {
            'MgUserAuthenticationEmailMethod'

            $MgUserAuthenticationEmailMethod = Get-MgUserAuthenticationEmailMethod -UserId $MgUser.Id -ErrorAction SilentlyContinue

            $MgUserAuthenticationEmailMethodParams = @{
                UserId        = $MgUser.Id
                BodyParameter = $Request.MgUserAuthenticationEmailMethod
            }

            if ($MgUserAuthenticationEmailMethod) {
                $MgUserAuthenticationEmailMethodParams.EmailAuthenticationMethodId = $MgUserAuthenticationEmailMethod.Id
                Update-MgUserAuthenticationEmailMethod @MgUserAuthenticationEmailMethodParams
            }
            else {
                New-MgUserAuthenticationEmailMethod @MgUserAuthenticationEmailMethodParams
            }

            Get-MgUserAuthenticationEmailMethod -UserId $MgUser.Id

        }

        # MgUserAuthenticationPhoneMethod
        if ($Request.MgUserAuthenticationPhoneMethod.PhoneNumber -and $Ammendment.Ammendment.Action -notlike 'Remove') {
            'MgUserAuthenticationPhoneMethod'

            $MgUserAuthenticationPhoneMethod = Get-MgUserAuthenticationPhoneMethod -UserId $MgUser.Id -ErrorAction SilentlyContinue

            $MgUserAuthenticationPhoneMethodParams = @{
                UserId        = $MgUser.Id
                BodyParameter = $Request.MgUserAuthenticationPhoneMethod
            }

            if ($MgUserAuthenticationPhoneMethod) {
                $MgUserAuthenticationPhoneMethodParams.PhoneAuthenticationMethodId = $MgUserAuthenticationPhoneMethod.Id
                Update-MgUserAuthenticationPhoneMethod @MgUserAuthenticationPhoneMethodParams
            }
            else {
                New-MgUserAuthenticationPhoneMethod @MgUserAuthenticationPhoneMethodParams
            }

            Get-MgUserAuthenticationPhoneMethod -UserId $MgUser.Id

        }

        # License

        # Tags

        # Groups

        # PhoneAssignment
        if ($Ammendment.Request.MgUser.businessPhones[0]) {
            'PhoneAssignment'
            $PhoneAssignmentParams = @{
                Identity = $Ammendment.Request.MgUser.UserPrincipalName
                TelephoneNumber = $Ammendment.Request.MgUser.businessPhones[0]
            }
            .\Set-PhoneAssignment.ps1 @PhoneAssignmentParams
        }

        # MFAStatus / StrongAuthentificationRequirement
        # CalendarPermission

        #if ($Log) { $Log | Add-MgSiteListItemLog @MgSiteListItem }

    }

}
catch {
    Stop-Transcript -Verbose
}
Stop-Transcript -Verbose
