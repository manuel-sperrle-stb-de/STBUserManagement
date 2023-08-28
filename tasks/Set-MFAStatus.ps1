#Requires -Version 5
#Requires -Modules @{ ModuleName = "MSOnline"; "ModuleVersion" = "1.1.183.66" }

if ($PSVersionTable.PSVersion.Major -ne "5") {
    try {
        'Calling powershell.exe (Windows v5)'
        powershell -C $MyInvocation.Line
    }
    catch {
        $_
    }
    finally {
        Exit 0
    }
}

# Statics
$StrongAuthenticationRequirement = [Microsoft.Online.Administration.StrongAuthenticationRequirement]@{
    RelyingParty = "*"
    State        = "Enforced"
}

'Start Transcript'
$CommandPath = Split-Path $MyInvocation.MyCommand.Path
$CommandName = $MyInvocation.MyCommand.Name
$LogFile = Join-Path $CommandPath ('log\{0}.log' -f $CommandName)
Try { Stop-Transcript } Catch {}
Start-Transcript $LogFile -Append -Verbose

'Connect-MsolService'
Try {
    Get-MsolUser -MaxResults 1 -ErrorAction Stop | Out-Null
}
Catch {
    Connect-MsolService
}

'Get-MsolUser'
$MsolUsers = Get-MsolUser -All
$ExceptionObjectIds = Get-MsolGroupMember -GroupObjectId "e3449341-851c-43f8-98ea-0792c850c96e" | Select-Object -ExpandProperty ObjectId

$StrongAuthenticationRequirementProperty = @(
    'ObjectId'
    'UserPrincipalName'
    'StrongAuthenticationRequirements'
)
$MsolUsersSelection = $MsolUsers | Select-Object $StrongAuthenticationRequirementProperty  | Where-Object { $ExceptionObjectIds -notcontains $_.ObjectId }
$MsolUsersToEnforce = $MsolUsersSelection | Where-Object { $_.StrongAuthenticationRequirements.State -ne "Enforced" }

'MsolUsersToEnforce'
# Enforce MFA for Guest users added
$MsolUsersToEnforce


$MsolUsersToEnforce | ForEach-Object {
    Set-MsolUser -UserPrincipalName $_.UserPrincipalName -StrongAuthenticationRequirements $StrongAuthenticationRequirement -Verbose
}

'Stop Transcript'
Stop-Transcript
