
Function Get-MgSiteByDisplayName {

    [CmdletBinding()]
    param (
        # DisplayName
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]
        $DisplayName
    )

    process {

        $DisplayName | ForEach-Object {
            $ThisObject = $_
            # no server side filter -> only "search"
            Get-MgSite -Search $ThisObject | Where-Object { $_.DisplayName -eq $ThisObject }
        }

    }

}
