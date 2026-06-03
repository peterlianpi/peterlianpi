# Refresh portfolio profile data from AI (pcore-chatgpt)
# Requires scripts/secrets.env with PORTFOLIO_AI_USER and PORTFOLIO_AI_PASSWORD
$ScriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Split-Path -Parent $ScriptsDir
$DataDir = Join-Path $Root "data"
$secretsPath = Join-Path $ScriptsDir "secrets.env"

if (-not (Test-Path $secretsPath)) {
    Write-Error "Create scripts/secrets.env from scripts/secrets.env.example"
    exit 1
}

$secrets = @{}
Get-Content $secretsPath | Where-Object { $_ -match '^\s*[^#]' } | ForEach-Object {
    $parts = $_ -split '=', 2
    $secrets[$parts[0].Trim()] = $parts[1].Trim()
}

$base = $secrets.PORTFOLIO_AI_BASE_URL
if (-not $base) { $base = "https://pcore-chatgpt.peterlianpi.site" }

Write-Host "Logging in to $base ..."
$login = Invoke-RestMethod -Uri "$base/api/auth/login" -Method POST `
    -Body (@{ username = $secrets.PORTFOLIO_AI_USER; password = $secrets.PORTFOLIO_AI_PASSWORD } | ConvertTo-Json) `
    -ContentType "application/json"

$headers = @{ Authorization = "Bearer $($login.token)" }
$questions = @(
    "List public portfolio information about Peter Pau Sian Lian: summary, skills, projects, education, experience, community, languages, interests, career goals, fun facts. No sensitive data.",
    "What are Peter Pau Sian Lian's top projects and why do they matter?",
    "What conversation starter questions can portfolio visitors ask about Peter?"
)

$results = @()
foreach ($q in $questions) {
    Write-Host "Asking: $($q.Substring(0, [Math]::Min(60, $q.Length)))..."
    $body = @{ message = $q; temporary = $true } | ConvertTo-Json
    $r = Invoke-RestMethod -Uri "$base/api/chat" -Method POST -Body $body -ContentType "application/json" -Headers $headers
    $results += @{ question = $q; answer = $r.text }
}

@{ source = $base; fetchedAt = (Get-Date).ToUniversalTime().ToString("o"); responses = $results } |
    ConvertTo-Json -Depth 5 |
    Set-Content -Encoding utf8 (Join-Path $DataDir "portfolio-ai-responses.json")

Write-Host "Saved to data/portfolio-ai-responses.json"
