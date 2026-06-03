# Deploy portfolio to peterlianpi.site (runs build first, deploys dist/)
$ErrorActionPreference = 'Stop'
$DeployDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $DeployDir
$BuildScript = Join-Path $Root 'scripts\build.ps1'

if (Test-Path $BuildScript) {
    Write-Host "Building site..."
    & $BuildScript
}

$DistDir = Join-Path $Root 'dist'
$config = @{}
Get-Content (Join-Path $DeployDir 'config.env') | Where-Object { $_ -match '^\s*[^#]' } | ForEach-Object {
    $parts = $_ -split '=', 2
    $config[$parts[0].Trim()] = $parts[1].Trim()
}

$IndexFile = Join-Path $DistDir 'index.html'
$AssetsDir = Join-Path $DistDir 'assets'
$DataDir = Join-Path $DistDir 'data'
$RemoteDir = $config.REMOTE_DIR
$remoteIndex = $config.REMOTE_INDEX

if (-not (Test-Path $IndexFile)) {
    Write-Error "dist/index.html not found. Run scripts/build.ps1 first."
    exit 1
}

Write-Host "Backing up current live site..."
ssh $config.SSH_HOST "sudo cp $RemoteDir/$remoteIndex $RemoteDir/$remoteIndex.bak"

Write-Host "Uploading $remoteIndex..."
scp $IndexFile "$($config.SSH_HOST):/tmp/$remoteIndex"
ssh $config.SSH_HOST "sudo cp /tmp/$remoteIndex $RemoteDir/$remoteIndex && rm /tmp/$remoteIndex"

if (Test-Path $AssetsDir) {
    Write-Host "Uploading assets/..."
    ssh $config.SSH_HOST "mkdir -p /tmp/portfolio-assets; rm -rf /tmp/portfolio-assets/*"
    scp -r "$AssetsDir\*" "$($config.SSH_HOST):/tmp/portfolio-assets/"
    ssh $config.SSH_HOST "sudo mkdir -p $RemoteDir/assets; sudo rm -rf $RemoteDir/assets/*; sudo cp -r /tmp/portfolio-assets/* $RemoteDir/assets/; rm -rf /tmp/portfolio-assets"
}

if (Test-Path $DataDir) {
    Write-Host "Uploading data/..."
    ssh $config.SSH_HOST "mkdir -p /tmp/portfolio-data"
    scp -r "$DataDir\*" "$($config.SSH_HOST):/tmp/portfolio-data/"
    ssh $config.SSH_HOST "sudo mkdir -p $RemoteDir/data; sudo cp -r /tmp/portfolio-data/* $RemoteDir/data/; rm -rf /tmp/portfolio-data"
}

Write-Host "Setting permissions..."
ssh $config.SSH_HOST "sudo chown -R root:root $RemoteDir; sudo find $RemoteDir -type f -exec chmod 644 {} \;"

Write-Host "Deployed to $($config.SITE_URL)"
