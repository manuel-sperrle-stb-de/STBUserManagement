
Function Get-AmmendmentsFromMgSiteListItems {

    [CmdletBinding()]
    param(

        [Parameter(Mandatory)]
        [object]
        $MgSite,

        [Parameter(Mandatory)]
        [object]
        $MgSiteList

    )

    $GetMgSiteListItemSTBParams = @{
        MgSite     = $MgSite
        MgSiteList = $MgSiteList
    }

    'Fetching Mg ...' | Write-Host
    #Get-MgSiteListItemSTB @GetMgSiteListItemSTBParams | Select-Object -First 1 -ExpandProperty Fields | Select-Object -ExpandProperty AdditionalProperties | ConvertTo-Json -Depth 3 | Write-Host
    Get-MgSiteListItemSTB @GetMgSiteListItemSTBParams | ForEach-Object {

        $Ammendment = [ordered]@{

            Ammendment = [ordered]@{

                # "Type": "MgUser|AdUser"
                Type     = & {
                    switch ($_.Fields.AdditionalProperties.Target) {
                        'office.com' { 'MgUser' }
                        'local.stb.de' { 'AdUser' }
                    }
                }

                # "DateTime": "yyyy-MM-ddThh:mm:ss", // sortable - Format s
                DateTime = Get-Date $_.Fields.AdditionalProperties.Datum -Format s

                # "Action": "Add(|New|Create)|Update|Remove(|Delete)"
                Action   = $_.Fields.AdditionalProperties.'Ver_x00e4_nderung'


            } # /Ammendment

            Meta       = [ordered]@{

                SiteId     = $_.SiteId
                ListId     = $_.ListId
                ListItemId = $_.ListItemId

                Fields     = [ordered]@{
                    Title = $_.Fields.AdditionalProperties.Title
                    Info  = $_.Fields.AdditionalProperties.Info
                    Go    = $_.Fields.AdditionalProperties.Go
                    Done  = $_.Fields.AdditionalProperties.Done
                }

            } # /Meta

            Request    = [ordered]@{

                AdditionalProperties            = $_.Fields.AdditionalProperties

                MgUser                          = [ordered]@{

                    Id                = $_.Fields.AdditionalProperties.mg
                    UserPrincipalName = $_.Fields.AdditionalProperties.UserPrincipalName

                    DisplayName       = $_.Fields.AdditionalProperties.Title
                    GivenName         = $_.Fields.AdditionalProperties.Vorname
                    SurName           = $_.Fields.AdditionalProperties.Nachname

                    UserType          = $_.Fields.AdditionalProperties.UserType

                    Mail              = $_.Fields.AdditionalProperties.Mail
                    mailNickname      = $_.Fields.AdditionalProperties.Mail -split '@' | Select-Object -First 1

                    CompanyName       = $_.Fields.AdditionalProperties.CompanyName
                    Department        = $_.Fields.AdditionalProperties.Department
                    JobTitle          = $_.Fields.AdditionalProperties.JobTitle
                    StreetAddress     = $_.Fields.AdditionalProperties.StreetAddress
                    PostalCode        = $_.Fields.AdditionalProperties.PostalCode
                    City              = $_.Fields.AdditionalProperties.City
                    State             = $_.Fields.AdditionalProperties.State
                    Country           = $_.Fields.AdditionalProperties.Country

                    businessPhones    = @(
                        if ($_.Fields.AdditionalProperties.BusinessPhoneSIP) { $_.Fields.AdditionalProperties.BusinessPhoneSIP }
                    )

                    UsageLocation     = 'DE'

                    AccountEnabled    = $true

                    PasswordProfile   = @{
                        Password = Get-RandomPassword
                    }

                } # /MgUser

                ADUser                          = [ordered]@{

                    #Id                = $_.Fields.AdditionalProperties.mg
                    UserPrincipalName = $_.Fields.AdditionalProperties.UserPrincipalName

                    DisplayName       = $_.Fields.AdditionalProperties.Title
                    GivenName         = $_.Fields.AdditionalProperties.Vorname
                    SurName           = $_.Fields.AdditionalProperties.Nachname

                    # Type ? UserType          = $_.Fields.AdditionalProperties.UserType

                    EmailAddress      = $_.Fields.AdditionalProperties.Mail # Mg: Mail
                    SamAccountName    = $_.Fields.AdditionalProperties.Mail -split '@' | Select-Object -First 1 # Mg: mailNickname

                    Company           = $_.Fields.AdditionalProperties.CompanyName # Mg: CompanyName
                    Department        = $_.Fields.AdditionalProperties.Department
                    Title             = $_.Fields.AdditionalProperties.JobTitle # Mg: JobTitle
                    StreetAddress     = $_.Fields.AdditionalProperties.StreetAddress
                    PostalCode        = $_.Fields.AdditionalProperties.PostalCode
                    City              = $_.Fields.AdditionalProperties.City
                    State             = $_.Fields.AdditionalProperties.State
                    Country           = $_.Fields.AdditionalProperties.Country

                    OfficePhone       = $_.Fields.AdditionalProperties.BusinessPhoneSIP # Mg: businessPhones @()

                    # UsageLocation     = 'DE'
                    # AccountEnabled    = $true

                    AccountPassword   = Get-RandomPassword | ConvertTo-SecureString -AsPlainText -Force # Mg: PasswordProfile

                } # /ADUser


                MgUserCustomSecurityAttributes  = [ordered]@{

                    employeeAttributes = [ordered]@{

                        '@odata.type'             = '#microsoft.graph.customSecurityAttributeValue'

                        userIsServiceAccount      = $_.Fields.AdditionalProperties.userIsServiceAccount
                        userIsHauptamt            = $_.Fields.AdditionalProperties.userIsHauptamt
                        userIsEhrenamt            = $_.Fields.AdditionalProperties.userIsEhrenamt

                        'employeeTags@odata.type' = '#Collection(String)'
                        employeeTags              = @(
                            if ($_.Fields.AdditionalProperties.userIsServiceAccount) { 'ServiceAccount' }
                            if ($_.Fields.AdditionalProperties.userIsHauptamt) { 'Hauptamt' }
                            if ($_.Fields.AdditionalProperties.userIsEhrenamt) { 'Ehrenamt' }
                        )

                    } # /EmployeeAttributes

                } # /MgUserCustomSecurityAttributes

                MgUserAuthenticationEmailMethod = [ordered]@{
                    EmailAddress = $_.Fields.AdditionalProperties.MFAMail
                }

                MgUserAuthenticationPhoneMethod = [ordered]@{
                    PhoneNumber = $_.Fields.AdditionalProperties.MFAPhone -replace '\s', $null
                    PhoneType   = 'mobile'
                }

            } # /Request

        } # /[ordered]@{}

        # NeededProperty = "PresentProperty"
        @{
            MobilePhone = "BusinessPhoneMobile"
            FaxNumber   = "FaxNumber"
        }.GetEnumerator() | ForEach-Object {
            $Key = $_.Key
            $Value = $_.Value
            if ($_.Fields.AdditionalProperties.$Value) {
                $Ammendment.$Key = $_.Fields.AdditionalProperties.$Value
            }
        }

        $Ammendment

    } # /Foreach-Object

}
