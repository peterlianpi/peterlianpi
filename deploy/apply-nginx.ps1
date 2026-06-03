# Apply static-only nginx config to awsserver
$DeployDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$config = @{}
Get-Content (Join-Path $DeployDir "config.env") | Where-Object { $_ -match '^\s*[^#]' } | ForEach-Object {
    $parts = $_ -split '=', 2
    $config[$parts[0].Trim()] = $parts[1].Trim()
}

$secretsPath = Join-Path $DeployDir "secrets.env"
if (-not (Test-Path $secretsPath)) {
    Write-Error "secrets.env not found. Copy secrets.env.example and set PORTFOLIO_CHAT_API_KEY."
    exit 1
}

$secrets = @{}
Get-Content $secretsPath | Where-Object { $_ -match '^\s*[^#]' } | ForEach-Object {
    $parts = $_ -split '=', 2
    $secrets[$parts[0].Trim()] = $parts[1].Trim()
}

$apiKey = $secrets.PORTFOLIO_CHAT_API_KEY
if (-not $apiKey) {
    Write-Error "PORTFOLIO_CHAT_API_KEY is empty in secrets.env"
    exit 1
}

$ConfFile = Join-Path $DeployDir "nginx-peterlianpi.site.conf"
$RemoteConf = "$($config.NGINX_SITES)/$($config.NGINX_CONF)"
$tmpLocal = Join-Path $env:TEMP "nginx-$($config.NGINX_CONF).ready"

if (-not (Test-Path $ConfFile)) {
    Write-Error "Config not found at $ConfFile"
    exit 1
}

Write-Host "Preparing nginx config with portfolio chat key..."
$content = (Get-Content $ConfFile -Raw).Replace('__PORTFOLIO_CHAT_API_KEY__', $apiKey)
[System.IO.File]::WriteAllText($tmpLocal, $content, [System.Text.UTF8Encoding]::new($false))

Write-Host "Uploading nginx config..."
scp $tmpLocal "$($config.SSH_HOST):/tmp/$($config.NGINX_CONF)"

Write-Host "Installing config and reloading nginx..."
ssh $config.SSH_HOST "sudo cp /tmp/$($config.NGINX_CONF) $RemoteConf && sudo nginx -t && sudo systemctl reload nginx"

Write-Host "Nginx config applied for $($config.SITE_URL) (static site + portfolio chat proxy)"
