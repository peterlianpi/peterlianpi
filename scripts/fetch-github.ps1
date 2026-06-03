# Refresh GitHub profile and repo data for portfolio updates
$ScriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $ScriptsDir
$DataDir = Join-Path $Root "data"

$config = @{}
Get-Content (Join-Path $ScriptsDir "config.env") | Where-Object { $_ -match '^\s*[^#]' } | ForEach-Object {
    $parts = $_ -split '=', 2
    $config[$parts[0].Trim()] = $parts[1].Trim()
}

$user = $config.GITHUB_USER
$profileRepo = $config.GITHUB_PROFILE_REPO

Write-Host "Fetching GitHub profile..."
$profile = Invoke-RestMethod -Uri "https://api.github.com/users/$user"
$profile | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $DataDir "github-profile.json")

Write-Host "Fetching GitHub repos..."
$repos = Invoke-RestMethod -Uri "https://api.github.com/users/$user/repos?sort=updated&per_page=100"
if ($repos -isnot [System.Array]) { $repos = @($repos) }
ConvertTo-Json -InputObject $repos -Depth 5 | Set-Content -Encoding utf8 (Join-Path $DataDir "github-repos.json")

Write-Host "Fetching profile README..."
try {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$user/$profileRepo/main/README.md" `
        -OutFile (Join-Path $DataDir "github-readme.md")
} catch {
    Write-Warning "Could not fetch README: $_"
}

$original = @($repos | Where-Object { -not $_.fork } | ForEach-Object {
    [PSCustomObject]@{
        name        = $_.name
        description = $_.description
        url         = $_.html_url
        language    = $_.language
        stars       = $_.stargazers_count
        updated     = $_.updated_at
    }
})
ConvertTo-Json -InputObject $original -Depth 3 | Set-Content -Encoding utf8 (Join-Path $DataDir "github-repos-original.json")

Write-Host "Done. Saved to $DataDir"
Write-Host "  - github-profile.json"
Write-Host "  - github-repos.json ($($repos.Count) repos)"
Write-Host "  - github-repos-original.json ($($original.Count) original projects)"
Write-Host "  - github-readme.md"
