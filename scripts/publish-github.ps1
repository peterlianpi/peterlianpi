# Create GitHub repo (if needed) and push about-me + optional profile README
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$RepoName = 'about-me'
$User = 'peterlianpi'

Set-Location $Root

if (-not (Test-Path (Join-Path $Root '.git'))) {
    Write-Error 'Run from initialized repo. git init && git add && git commit first.'
}

if (-not (git remote get-url origin 2>$null)) {
    git remote add origin "git@github.com:${User}/${RepoName}.git"
}

$token = $env:GITHUB_TOKEN
if ($token) {
    Write-Host "Creating repo ${User}/${RepoName} (if missing)..."
    $headers = @{
        Authorization = "Bearer $token"
        Accept        = 'application/vnd.github+json'
    }
    $body = @{
        name        = $RepoName
        description = 'Source for peterlianpi.site — JSON model, build, deploy'
        private     = $false
    } | ConvertTo-Json
    try {
        Invoke-RestMethod -Method Post -Uri 'https://api.github.com/user/repos' -Headers $headers -Body $body -ContentType 'application/json' | Out-Null
        Write-Host 'Repository created.'
    } catch {
        if ($_.Exception.Message -notmatch 'already exists|name already exists') {
            Write-Warning "Create repo skipped: $($_.Exception.Message)"
        }
    }
} else {
    Write-Host "No GITHUB_TOKEN — create repo manually: https://github.com/new?name=$RepoName"
}

Write-Host 'Pushing main branch...'
git push -u origin main

$profileDir = Join-Path $Root '_github-profile'
if (Test-Path $profileDir) {
    Write-Host 'Pushing profile README (peterlianpi/peterlianpi)...'
    Push-Location $profileDir
    git add README.md
    if (git diff --cached --quiet) {
        Write-Host 'Profile README unchanged.'
    } else {
        git commit -m "Update profile README: GTG role, portfolio source, tech stack"
        git push origin main
    }
    Pop-Location
}

Write-Host "Done: https://github.com/${User}/${RepoName}"
