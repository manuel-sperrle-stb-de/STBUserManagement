#Requires -RunAsAdministrator

param(
    $InstallModules = @(
        @{ ModuleName = "MSOnline"; ModuleVersion = "1.1.183.66" }
        @{ ModuleName = "MicrosoftTeams"; ModuleVersion = "5.2.0" }
        @{ ModuleName = "ExchangeOnlineManagement"; ModuleVersion = "3.2.0" }
        @{ ModuleName = "Microsoft.Graph.Users"; ModuleVersion = "2.4.0" }
        @{ ModuleName = "Microsoft.Graph.Authentication"; ModuleVersion = "2.4.0" }
    )
)

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

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

ForEach ($Module in $InstallModules) {
    $Get = Get-InstalledModule $Module.ModuleName -ErrorAction SilentlyContinue
    if (-not $Get -and $Module.ModuleVersion) {
        Install-Module $Module -Scope AllUsers -MinimumVersion $Module.ModuleVersion
    }
    elseif ($Get -and [version]$Get.Version -lt $Module.ModuleVersion) {
        $Get | Update-Module -RequiredVersion $Module.ModuleVersion
    }
}
