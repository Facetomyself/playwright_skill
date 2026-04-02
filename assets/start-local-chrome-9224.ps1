$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$userDataDir = "D:\chrome-mcp-pw"
$debugPort = 9224
$debugHost = "127.0.0.1"
$startupTimeoutSeconds = 15

function Test-DebugPortListening {
    param(
        [string]$Host,
        [int]$Port,
        [int]$TimeoutMs = 500
    )

    $client = New-Object System.Net.Sockets.TcpClient

    try {
        $asyncResult = $client.BeginConnect($Host, $Port, $null, $null)
        if (-not $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) {
            return $false
        }

        $client.EndConnect($asyncResult)
        return $true
    } catch {
        return $false
    } finally {
        $client.Dispose()
    }
}

if (-not (Test-Path $chromePath)) {
    throw "Chrome not found: $chromePath"
}

if (-not (Test-Path $userDataDir)) {
    New-Item -ItemType Directory -Path $userDataDir -Force | Out-Null
}

if (Test-DebugPortListening -Host $debugHost -Port $debugPort) {
    Write-Output "Chrome remote debugging is already available on $($debugHost):$debugPort; reusing existing browser profile $userDataDir"
    exit 0
}

$args = @(
    "--remote-debugging-port=$debugPort"
    "--user-data-dir=$userDataDir"
    "about:blank"
)

Start-Process -FilePath $chromePath -ArgumentList $args | Out-Null

$deadline = (Get-Date).AddSeconds($startupTimeoutSeconds)

while ((Get-Date) -lt $deadline) {
    Start-Sleep -Milliseconds 500

    if (Test-DebugPortListening -Host $debugHost -Port $debugPort) {
        Write-Output "Started Chrome with remote debugging on $($debugHost):$debugPort and user-data-dir $userDataDir"
        exit 0
    }
}

throw "Chrome start timed out: remote debugging port $debugPort did not open within $startupTimeoutSeconds seconds. Check whether another Chrome instance is holding profile $userDataDir or started without remote debugging."
