# Pull live site files from peterlianpi.site on awsserver
$DeployDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $DeployDir

$config = @{}
Get-Content (Join-Path $DeployDir "config.env") | Where-Object { $_ -match '^\s*[^#]' } | ForEach-Object {
    $parts = $_ -split '=', 2
    $config[$parts[0].Trim()] = $parts[1].Trim()
}

Write-Host "Downloading $($config.REMOTE_INDEX)..."
scp "$($config.SSH_HOST):$($config.REMOTE_DIR)/$($config.REMOTE_INDEX)" (Join-Path $Root $config.REMOTE_INDEX)

Write-Host "Downloading backup..."
scp "$($config.SSH_HOST):$($config.REMOTE_DIR)/$($config.REMOTE_INDEX).bak" (Join-Path $Root "$($config.REMOTE_INDEX).bak")

Write-Host "Done. Files saved to $Root"
