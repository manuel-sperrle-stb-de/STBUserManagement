
Function Get-RandomPassword {

    param (

        [ValidateRange(4, [int]::MaxValue)]
        [int]$Length = 32,

        [int]$UpperChars = 2,
        [string]$UpperCharSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",

        [int]$LowerChars = 2,
        [string]$LowerCharSet = "abcdefghijklmnopqrstuvwxyz",

        [int]$NumericChars = 2,
        [string]$NumericCharSett = "0123456789",

        [int]$SpecialChars = 2,
        [string]$SpecialCharSet = "/*-+,!?=()@;:._"

    )

    if ($UpperChars + $LowerChars + $NumericChars + $SpecialChars -gt $Length) {
        throw "number of UpperChars/LowerChars/NumericChars/SpecialChars char must be LowerChars or equal to Length"
    }

    $charSet = ""
    if ($UpperChars -gt 0) { $charSet += $UpperCharSet }
    if ($LowerChars -gt 0) { $charSet += $LowerCharSet }
    if ($NumericChars -gt 0) { $charSet += $NumericCharSett }
    if ($SpecialChars -gt 0) { $charSet += $SpecialCharSet }
    $charSet = $charSet.ToCharArray()

    $Rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $Bytes = New-Object byte[]($Length)
    $Rng.GetBytes($Bytes)

    $Result = New-Object char[]($Length)
    For ($i = 0 ; $i -lt $Length ; $i++) {
        $result[$i] = $charSet[$bytes[$i] % $charSet.Length]
    }

    $Password = (-join $Result)
    $Valid = $true
    if ($UpperChars -gt ($password.ToCharArray() | Where-Object { $_ -cin $UpperCharSet.ToCharArray() }).Count) { $valid = $false }
    if ($LowerChars -gt ($password.ToCharArray() | Where-Object { $_ -cin $LowerCharSet.ToCharArray() }).Count) { $valid = $false }
    if ($NumericChars -gt ($password.ToCharArray() | Where-Object { $_ -cin $NumericCharSett.ToCharArray() }).Count) { $valid = $false }
    if ($SpecialChars -gt ($password.ToCharArray() | Where-Object { $_ -cin $SpecialCharSet.ToCharArray() }).Count) { $valid = $false }

    if (!$Valid) {
        $Splat = @{
            Length          = $Length
            UpperChars      = $UpperChars
            UpperCharSet    = $UpperCharSet
            LowerChars      = $LowerChars
            LowerCharSet    = $LowerCharSet
            NumericChars    = $NumericChars
            NumericCharSett = $NumericCharSett
            SpecialChars    = $SpecialChars
            SpecialCharSet  = $SpecialCharSet

        }
        $Password = Get-RandomPassword @Splat
    }

    $Password

}
