# Push portfolio source to GitHub (profile repo branch + optional about-me repo)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ProfileRepo = 'https://github.com/peterlianpi/peterlianpi.git'
$AboutMeRepo = 'https://github.com/peterlianpi/about-me.git'
$Branch = 'portfolio-site'

Set-Location $Root

if (-not (Test-Path (Join-Path $Root '.git'))) {
    Write-Error 'Not a git repo. Run: git init; git add .; git commit -m "Initial commit"'
}

if (-not (git remote get-url profile 2>$null)) {
    git remote add profile $ProfileRepo
}

Write-Host "Pushing $Branch branch to peterlianpi/peterlianpi..."
git push profile main:${Branch}

$token = $env:GITHUB_TOKEN
if ($token) {
    if (-not (git remote get-url origin 2>$null)) {
        git remote add origin $AboutMeRepo
    }
    Write-Host 'Creating peterlianpi/about-me (if missing)...'
    $headers = @{ Authorization = "Bearer $token"; Accept = 'application/vnd.github+json' }
    $body = @{ name = 'about-me'; description = 'Source for peterlianpi.site'; private = $false } | ConvertTo-Json
    try {
        Invoke-RestMethod -Method Post -Uri 'https://api.github.com/user/repos' -Headers $headers -Body $body -ContentType 'application/json' | Out-Null
    } catch { }
    Write-Host 'Pushing to peterlianpi/about-me...'
    git push -u origin main
}

$profileDir = Join-Path $Root '_github-profile'
if (Test-Path $profileDir) {
    Write-Host 'Updating profile README on main...'
    Push-Location $profileDir
    git pull origin main
    Copy-Item (Join-Path $Root 'data\github-readme.md') 'README.md' -Force -ErrorAction SilentlyContinue
    git add README.md
    if (-not (git diff --cached --quiet)) {
        git commit -m "Sync profile README with portfolio"
        git push origin main
    }
    Pop-Location
}

Write-Host 'Done.'
Write-Host "  Source: https://github.com/peterlianpi/peterlianpi/tree/$Branch"
if ($token) { Write-Host '  Mirror: https://github.com/peterlianpi/about-me' }
