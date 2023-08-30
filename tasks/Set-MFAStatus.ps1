#Requires -Modules @{ ModuleName = "MSOnline"; ModuleVersion = "1.1.183.66" }

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

try {
    $null = Get-MsolUser -MaxResults 1 -ErrorAction Stop
}
catch {
    Connect-MsolService
}

$LogFile = Join-Path $PSScriptRoot ('log\{0}.{1}.log' -f $MyInvocation.MyCommand.Name, ((Get-Date -Format s) -replace '[^\d]', $null) )
try { Stop-Transcript } catch {}
Start-Transcript $LogFile -Verbose

try {

    # Statics
    $StrongAuthenticationRequirement = [Microsoft.Online.Administration.StrongAuthenticationRequirement]@{
        RelyingParty = "*"
        State        = "Enforced"
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

}
catch {
    Stop-Transcript -Verbose
}
Stop-Transcript -Verbose
