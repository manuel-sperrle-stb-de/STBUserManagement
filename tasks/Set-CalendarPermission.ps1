#Requires -Modules @{ ModuleName="ExchangeOnlineManagement"; ModuleVersion="3.2.0" }

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

# ExchangeOnline
Connect-ExchangeOnline

$LogFile = Join-Path $PSScriptRoot ('log\{0}.{1}.log' -f $MyInvocation.MyCommand.Name, ((Get-Date -Format s) -replace '[^\d]', $null) )
try { Stop-Transcript } catch {}
Start-Transcript $LogFile -Verbose

try {

    $mailboxes = Get-EXOMailbox -Properties UserPrincipalName, SamAccountName -Filter "RecipientTypeDetails -like 'UserMailbox'"  #OPath-Syntax!

    $DesiredAccessRights = "Reviewer"

    foreach ($mailbox in $mailboxes) {

        "Processing {0} ..." -f $mailbox.UserPrincipalName | Write-Host

        # Kalendername erstellen
        $Calendars = Get-MailboxFolderStatistics -Identity $mailbox.SamAccountName -FolderScope Calendar
        $CalendarName = $mailbox.SamAccountName + ":\" + $Calendars[0].Name

        $CalendarName | Write-Host

        $MailboxFolderPermission = Get-MailboxFolderPermission $CalendarName
        $DefaultAccessRights = ($MailboxFolderPermission | Where-Object { $_.User.UserType.Value -eq "Default" }).AccessRights

        # Check ob die DesiredAccessRights enthalten sind
        'AccessRights: {0}' -f ($DefaultAccessRights -join " ") | Write-Host

        if ($DefaultAccessRights -contains $DesiredAccessRights ) {
            'Check' | Write-Host -ForegroundColor Green
        }
        else {
            'Update to {0}' -f $DesiredAccessRights | Write-Host -ForegroundColor Yellow
            Set-MailboxFolderPermission -Identity $CalendarName -User "Standard" -AccessRights $DesiredAccessRights -Verbose
        }

    }

}
catch {
    Stop-Transcript -Verbose
}
Stop-Transcript -Verbose
