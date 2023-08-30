#Requires -Modules @{ ModuleName = "MicrosoftTeams"; ModuleVersion = "5.2.0" }

[CmdletBinding()]
param (

    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string]
    $Identity,

    [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
    [string]
    $TelephoneNumber

)

try {
    $CsOnlineUser = Get-CsOnlineUser $Identity
}
catch {
    Connect-MicrosoftTeams
}

$TelephoneNumber = $TelephoneNumber -replace '[^\d|\+]', $null

#$LogFile = Join-Path $PSScriptRoot ('log\{0}.{1}.log' -f $MyInvocation.MyCommand.Name, ((Get-Date -Format s) -replace '[^\d]', $null) )
# try { Stop-Transcript } catch {}
# Start-Transcript $LogFile -Verbose
if (-not $CsOnlineUser) { $CsOnlineUser = Get-CsOnlineUser $Identity }

'Grant-CsOnlineVoiceRoutingPolicy' | Write-Host
$CsOnlineUser | Grant-CsOnlineVoiceRoutingPolicy -PolicyName 'GenericStandard' -Verbose

'Grant-CsTeamsCallingPolicy' | Write-Host
$GrantCsTeamsCallingPolicyParams = @{
    Identity   = $CsOnlineUser.Identity
    PolicyName = 'Tag:AllowCalling'
    Verbose    = $true
}
Grant-CsTeamsCallingPolicy @GrantCsTeamsCallingPolicyParams

'Grant-CsTeamsUpgradePolicy' | Write-Host
$CsOnlineUser | Grant-CsTeamsUpgradePolicy -PolicyName 'Tag:UpgradeToTeams' -Verbose

'Set-CsPhoneNumberAssignment' | Write-Host
Set-CsPhoneNumberAssignment -Identity ('sip:' + $Identity) -PhoneNumber $TelephoneNumber -PhoneNumberType DirectRouting -Verbose



'Get-CsPhoneNumberAssignment' | Write-Host
Get-CsPhoneNumberAssignment -TelephoneNumber $TelephoneNumber | Select-Object TelephoneNumber, NumberType, ActivationState, Capability | Format-List

'Get-CsOnlineUser' | Write-Host
Get-CsOnlineUser $Identity | Select-Object UserPrincipalName, SipAddress, OnlineVoiceRoutingPolicy, TeamsCallingPolicy, TeamsUpgradePolicy | Format-List

# Remove
# Get-CsPhoneNumberAssignment -TelephoneNumber $TelephoneNumber | Remove-CsPhoneNumberAssignment

# Stop-Transcript -Verbose
