param(
    [switch]$Watch,
    [int]$IntervalSeconds = 1,
    [switch]$Copy,
    [switch]$AsJson,
    [switch]$IncludeAccessToken
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-KRWebViewMainProcess {
    Get-CimInstance Win32_Process |
        Where-Object {
            $_.Name -eq "KRWebView.exe" -and
            $_.CommandLine -and
            $_.CommandLine -notmatch "--type="
        } |
        Sort-Object ProcessId
}

function Get-EncodedArgument {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandLine
    )

    $parts = $CommandLine -split '"', 3
    if ($parts.Count -lt 3) {
        return $null
    }

    $tail = $parts[2].Trim()
    if (-not $tail) {
        return $null
    }

    return ($tail -split "\s+")[0]
}

function Decode-KRBase64 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EncodedText
    )

    # KRWebView uses '.' where standard Base64 would normally use '=' padding.
    $normalized = $EncodedText -replace "\.", "="
    $bytes = [Convert]::FromBase64String($normalized)
    return [Text.Encoding]::UTF8.GetString($bytes)
}

function Try-ParseJson {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $null
    }

    try {
        return $Text | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Get-FragmentQueryParameters {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    $result = @{}
    $fragment = ""

    try {
        $uri = [Uri]$Url
        $fragment = $uri.Fragment
    }
    catch {
        $fragmentIndex = $Url.IndexOf("#")
        if ($fragmentIndex -ge 0) {
            $fragment = $Url.Substring($fragmentIndex)
        }
    }

    if (-not $fragment) {
        return $result
    }

    $questionIndex = $fragment.IndexOf("?")
    if ($questionIndex -lt 0) {
        return $result
    }

    $query = $fragment.Substring($questionIndex + 1)
    foreach ($pair in ($query -split "&")) {
        if (-not $pair) {
            continue
        }

        $keyValue = $pair -split "=", 2
        $key = [Uri]::UnescapeDataString($keyValue[0])
        $value = if ($keyValue.Count -gt 1) {
            [Uri]::UnescapeDataString($keyValue[1])
        }
        else {
            ""
        }

        $result[$key] = $value
    }

    return $result
}

function Convert-ProcessToGachaResult {
    param(
        [Parameter(Mandatory = $true)]
        $Process
    )

    $encodedArgument = Get-EncodedArgument -CommandLine $Process.CommandLine
    if (-not $encodedArgument) {
        return $null
    }

    $decodedJson = Decode-KRBase64 -EncodedText $encodedArgument
    $outerPayload = Try-ParseJson -Text $decodedJson
    if (-not $outerPayload) {
        return $null
    }

    $url = [string]$outerPayload.url
    if ([string]::IsNullOrWhiteSpace($url)) {
        return $null
    }

    if ($url -notmatch "gacha|record") {
        return $null
    }

    $innerParam = Try-ParseJson -Text ([string]$outerPayload.param).Trim()
    $queryParameters = Get-FragmentQueryParameters -Url $url

    $result = [ordered]@{
        Source         = "process_cmdline"
        ProcessId      = $Process.ProcessId
        ParentProcessId = $Process.ParentProcessId
        Url            = $url
        PlayerId       = $queryParameters["player_id"]
        GachaId        = $queryParameters["gacha_id"]
        GachaType      = $queryParameters["gacha_type"]
        RecordId       = $queryParameters["record_id"]
        ServerId       = $queryParameters["svr_id"]
        ServerArea     = $queryParameters["svr_area"]
        Language       = $queryParameters["lang"]
        Platform       = $queryParameters["platform"]
        UserId         = if ($innerParam) { $innerParam.userInfo.userId } else { $null }
        Uuid           = $outerPayload.uuid
        CapturedAt     = (Get-Date).ToString("s")
    }

    if ($IncludeAccessToken -and $innerParam) {
        $result["AccessToken"] = $innerParam.userInfo.accessToken
    }

    return [pscustomobject]$result
}

function Write-Result {
    param(
        [Parameter(Mandatory = $true)]
        $Result
    )

    if ($Copy) {
        Set-Clipboard -Value $Result.Url
    }

    if ($AsJson) {
        $Result | ConvertTo-Json -Depth 5
        return
    }

    $Result | Format-List
}

function Invoke-Once {
    $results = foreach ($process in (Get-KRWebViewMainProcess)) {
        try {
            Convert-ProcessToGachaResult -Process $process
        }
        catch {
            continue
        }
    }

    $results = $results | Where-Object { $_ } | Sort-Object ProcessId -Unique

    if (-not $results) {
        Write-Host "No gacha record link found in current KRWebView processes."
        return
    }

    foreach ($result in $results) {
        Write-Result -Result $result
    }
}

if (-not $Watch) {
    Invoke-Once
    exit
}

$seen = New-Object System.Collections.Generic.HashSet[string]
Write-Host "Watching KRWebView processes. Open the gacha history page in-game to capture the link."

while ($true) {
    foreach ($process in (Get-KRWebViewMainProcess)) {
        try {
            $result = Convert-ProcessToGachaResult -Process $process
            if (-not $result) {
                continue
            }

            $key = "{0}|{1}" -f $result.ProcessId, $result.Url
            if ($seen.Add($key)) {
                Write-Result -Result $result
            }
        }
        catch {
            continue
        }
    }

    Start-Sleep -Seconds $IntervalSeconds
}
