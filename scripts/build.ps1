# Build static site from data/portfolio-profile.json -> dist/
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$DataFile = Join-Path $Root 'data\portfolio-profile.json'
$SrcDir = Join-Path $Root 'src'
$DistDir = Join-Path $Root 'dist'
$Template = Join-Path $SrcDir 'index.template.html'

if (-not (Test-Path $DataFile)) { Write-Error "Missing $DataFile"; exit 1 }
if (-not (Test-Path $Template)) { Write-Error "Missing $Template"; exit 1 }

$p = Get-Content $DataFile -Raw -Encoding UTF8 | ConvertFrom-Json
$ver = ($p.lastUpdated -replace '[^0-9]', '') + '03'
$Md = '&middot;'

function Escape-Html([string]$t) {
    if (-not $t) { return '' }
    $t -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;'
}

function Format-HtmlText([string]$t) {
    if (-not $t) { return '' }
    $e = Escape-Html $t
    $e = $e -creplace [char]0x00B7, $Md
    $e = $e -creplace [char]0x2013, '&ndash;'
    $e = $e -creplace [char]0x2014, '&mdash;'
    $e
}

function Insert-IconHtml($item) {
    if ($item.PSObject.Properties['iconHtml'] -and $item.iconHtml) { return $item.iconHtml }
    if ($item.PSObject.Properties['icon'] -and $item.icon) { return Format-HtmlText $item.icon }
    ''
}

function Join-Dot($arr) { ($arr -join " $Md ") }

function Build-Badges($badges) {
    ($badges | ForEach-Object {
        '<li class="badge"><span class="badge__icon" aria-hidden="true">{0}</span><span class="badge__text">{1}</span></li>' -f (Insert-IconHtml $_), (Format-HtmlText $_.text)
    }) -join "`n            "
}

function Build-List($items) {
    ($items | ForEach-Object { '<li>{0}</li>' -f (Format-HtmlText $_) }) -join "`n            "
}

function Build-About($p) {
    @"
        <p class="card__text">$(Format-HtmlText $p.about.intro)</p>
        <p class="card__text"><strong class="text-accent">Mission:</strong> $(Format-HtmlText $p.mission)</p>
        <p class="card__text">$(Format-HtmlText $p.about.footer)</p>
"@
}

function Build-Experience($p) {
    $exp = $p.experience[0]
    $meta = "$(Format-HtmlText $exp.company) $Md $(Format-HtmlText $exp.department) $Md $(Format-HtmlText $exp.location) $Md $(Format-HtmlText $exp.period)"
    $stack = Join-Dot $exp.stack
    $groups = ($exp.groups | ForEach-Object {
        $items = Build-List $_.items
        @"
        <p class="timeline__group-title">$(Format-HtmlText $_.title)</p>
        <ul class="list list--bullet list--spaced">
            $items
        </ul>
"@
    }) -join "`n"
    @"
        <article class="timeline__item">
          <h3 class="timeline__role">$(Format-HtmlText $exp.role)</h3>
          <p class="timeline__meta">$meta</p>
          <p class="timeline__stack"><strong class="text-accent">Stack (work):</strong> $stack</p>
$groups
        </article>
"@
}

function Build-Community($p) {
    ($p.community | ForEach-Object {
        @"
        <article class="info-card">
          <h3 class="info-card__title">$(Insert-IconHtml $_) $(Format-HtmlText $_.title)</h3>
          <p class="info-card__body">$(Format-HtmlText $_.body)</p>
        </article>
"@
    }) -join "`n"
}

function Build-TechPill($pill) {
    $icon = if ($pill.icon) { "<i class=`"$($pill.icon)`"></i> " } else { '' }
    $emoji = if ($pill.emojiHtml) { "$($pill.emojiHtml) " } elseif ($pill.emoji) { "$(Format-HtmlText $pill.emoji) " } else { '' }
    "<span class=`"tech-pill`">$icon$emoji$(Format-HtmlText $pill.name)</span>"
}

function Build-Tech($p) {
    $w = $p.tech.work
    $per = $p.tech.personal
    $workPills = ($w.pills | ForEach-Object { Build-TechPill $_ }) -join "`n        "
    $perPills = ($per.pills | ForEach-Object { Build-TechPill $_ }) -join "`n        "
    @"
      <p class="stack-label"><strong>$(Format-HtmlText $w.label):</strong> $(Format-HtmlText $w.summary)</p>
      <div class="tech-grid tech-grid--work">
        $workPills
      </div>
      <p class="stack-label u-mt"><strong>$(Format-HtmlText $per.label):</strong> $(Format-HtmlText $per.summary)</p>
      <div class="tech-grid tech-grid--personal">
        $perPills
      </div>
"@
}

function Build-ProjectTitle($proj) {
    $title = Format-HtmlText $proj.title
    if ($proj.iconHtml) { return "$($proj.iconHtml) $title" }
    $title
}

function Build-Projects($p) {
    ($p.projects | ForEach-Object {
        $feat = if ($_.featured) { ' project-card--featured' } else { '' }
        $url = if ($_.url) { $_.url } else { '#' }
        $badge = if ($_.featured) { '<div class="project-card__badge">&#9733; FEATURED PROJECT</div>' } else { '' }
        $stats = if ($_.stats) {
            $s = ($_.stats | ForEach-Object {
                $line = if ($_.html) { $_.html } else { Format-HtmlText $_ }
                "<span>$line</span>"
            }) -join "`n            "
            "<div class=`"project-card__stats`">`n            $s`n          </div>"
        } else { '' }
        $code = if ($_.install) { "<code class=`"project-card__code`">`$ $(Format-HtmlText $_.install)</code>" } else { '' }
        $tags = if ($_.tags) {
            $t = ($_.tags | ForEach-Object { "<span class=`"tag`">$(Format-HtmlText $_)</span>" }) -join ''
            "<div class=`"tag-list`">$t</div>"
        } elseif ($_.starsHtml) {
            "<span class=`"tag tag--stars`">$($_.starsHtml)</span>"
        } elseif ($_.stars) {
            "<span class=`"tag tag--stars`">$(Format-HtmlText $_.stars)</span>"
        } else { '' }
        @"
        <a href="$(Escape-Html $url)" target="_blank" rel="noopener noreferrer" class="project-card$feat">
          $badge
          <h3 class="project-card__title">$(Build-ProjectTitle $_)</h3>
          <p class="project-card__desc">$(Format-HtmlText $_.description)</p>
          $stats
          $code
          $tags
        </a>
"@
    }) -join "`n"
}

function Build-Contact($p) {
    ($p.contact | ForEach-Object {
        $rel = if ($_.external) { ' target="_blank" rel="noopener noreferrer"' } else { '' }
        @"
        <a class="contact-card" href="$(Escape-Html $_.href)"$rel>
          <span class="contact-card__icon" aria-hidden="true">$(Insert-IconHtml $_)</span>
          <span class="contact-card__body">
            <span class="contact-card__label">$(Format-HtmlText $_.label)</span>
            <span class="contact-card__value">$(Format-HtmlText $_.value)</span>
          </span>
          <span class="contact-card__action" aria-hidden="true">&rarr;</span>
        </a>
"@
    }) -join "`n"
}

function Build-Learning($p) {
    ($p.learning | ForEach-Object {
        '<p class="card__text"><strong class="{0}">{1}:</strong> {2}</p>' -f (Escape-Html $_.class), (Format-HtmlText $_.label), (Format-HtmlText $_.text)
    }) -join "`n        "
}

function Build-ChatFacts($p) {
    $exp = $p.experience[0]
    $workStack = $exp.stack -join ', '
    $langs = $p.languages -join ', '
    $personal = ($p.tech.personal.summary -replace ' · ', ', ')
    @"
Peter Pau Sian Lian, $($p.location), GitHub: peterlianpi
Education: BSc Computer Science, University of the People (in progress)
Work: $($exp.role) at $($exp.company), Web Team, $($exp.period). GTG work stack: $workStack. React is NOT used at GTG. Employer is GTG only, not 5BB.
Projects: Zolai AI Second Brain, P-Core, EBYF Info, Student Management System, and more
Personal project stack: $personal
Languages: $langs
Contact: $($p.links.email), phone $($p.links.phone)
"@
}

function Build-ChatConfig($p) {
    $site = @{ typewriterPhrases = @($p.typewriterPhrases) }
    $chat = @{
        prompts    = @($p.chat.prompts)
        welcome    = $p.chat.welcome
        storageKey = $p.chat.storageKey
        facts      = (Build-ChatFacts $p).Trim()
        rules      = @(
            'Use simple markdown: bullet lists and **bold** labels only (no ### headings, no HTML)'
            'Never output citation tokens, entity tags, or special Unicode markers'
            'Never say 5BB; employer is Global Technology Group (GTG)'
            'At GTG he uses PHP, Laravel, Blade, WordPress, MySQL - do not list React as work stack'
            'React, Next.js, etc. are for personal projects only'
            'His job title is Junior Engineer, Web Development (SAE)'
            'Assume the visitor means Peter Pau Sian Lian; do not ask which Peter'
            'Stay concise; public info only'
        )
    }
    $siteJson = $site | ConvertTo-Json -Compress -Depth 5
    $chatJson = $chat | ConvertTo-Json -Compress -Depth 5
    @"
/* Generated by scripts/build.ps1 - do not edit */
window.PortfolioSiteConfig = $siteJson;
window.PortfolioChatConfig = $chatJson;
"@
}

Write-Host "Building dist/ (v$ver)..."
if (Test-Path $DistDir) { Remove-Item $DistDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $DistDir, (Join-Path $DistDir 'assets\css'), (Join-Path $DistDir 'assets\js\chat'), (Join-Path $DistDir 'data') | Out-Null

$html = Get-Content $Template -Raw -Encoding UTF8
$html = $html.Replace('{{BUILD_VERSION}}', $ver)
$html = $html.Replace('{{NAME}}', (Format-HtmlText $p.name))
$html = $html.Replace('{{TITLE}}', (Format-HtmlText $p.title))
$html = $html.Replace('{{SUMMARY}}', (Format-HtmlText $p.summary))
$html = $html.Replace('{{AVATAR}}', (Escape-Html $p.githubAvatar))
$html = $html.Replace('{{HERO_BADGES}}', (Build-Badges $p.hero.badges))
$html = $html.Replace('{{LINKS_GITHUB}}', (Escape-Html $p.links.github))
$html = $html.Replace('{{LINKS_HF}}', (Escape-Html $p.links.huggingface))
$html = $html.Replace('{{LINKS_KAGGLE}}', (Escape-Html $p.links.kaggle))
$html = $html.Replace('{{LINKS_BLOG}}', (Escape-Html $p.links.blog))
$html = $html.Replace('{{LINKS_EMAIL}}', (Escape-Html $p.links.email))
$html = $html.Replace('{{LINKS_TWITTER}}', (Escape-Html $p.links.twitter))
$html = $html.Replace('{{ABOUT_HTML}}', (Build-About $p))
$html = $html.Replace('{{EXPERIENCE_TIMELINE}}', (Build-Experience $p))
$html = $html.Replace('{{EXPERIENCE_EXTRA}}', @"
      <div class="grid grid--2 u-mt">
        <article class="info-card">
          <h3 class="info-card__title">$(Insert-IconHtml $p.careerGoalsCard) $(Format-HtmlText $p.careerGoalsCard.title)</h3>
          <ul class="list list--bullet list--spaced">
            $(Build-List $p.careerGoals)
          </ul>
        </article>
        <article class="info-card">
          <h3 class="info-card__title">$(Insert-IconHtml $p.funFactsCard) $(Format-HtmlText $p.funFactsCard.title)</h3>
          <ul class="list list--bullet list--spaced">
            $(Build-List $p.funFacts)
          </ul>
        </article>
      </div>
"@)
$html = $html.Replace('{{COMMUNITY_HTML}}', (Build-Community $p))
$html = $html.Replace('{{PROJECTS_HTML}}', (Build-Projects $p))
$html = $html.Replace('{{TECH_HTML}}', (Build-Tech $p))
$html = $html.Replace('{{LEARNING_HTML}}', (Build-Learning $p))
$html = $html.Replace('{{CONTACT_HTML}}', (Build-Contact $p))

[System.IO.File]::WriteAllText((Join-Path $DistDir 'index.html'), $html, [System.Text.UTF8Encoding]::new($false))

Copy-Item (Join-Path $SrcDir 'assets\css\site.css') (Join-Path $DistDir 'assets\css\site.css')
Copy-Item (Join-Path $SrcDir 'assets\css\chat.css') (Join-Path $DistDir 'assets\css\chat.css')
Copy-Item (Join-Path $SrcDir 'assets\js\main.js') (Join-Path $DistDir 'assets\js\main.js')
Copy-Item (Join-Path $SrcDir 'assets\js\chat\view.js') (Join-Path $DistDir 'assets\js\chat\view.js')
Copy-Item (Join-Path $SrcDir 'assets\js\chat\controller.js') (Join-Path $DistDir 'assets\js\chat\controller.js')
Copy-Item $DataFile (Join-Path $DistDir 'data\portfolio-profile.json')

[System.IO.File]::WriteAllText(
    (Join-Path $DistDir 'assets\js\config.js'),
    (Build-ChatConfig $p),
    [System.Text.UTF8Encoding]::new($false)
)

# Sync root index for local preview (optional)
Copy-Item (Join-Path $DistDir 'index.html') (Join-Path $Root 'index.html') -Force
Copy-Item (Join-Path $DistDir 'assets') (Join-Path $Root 'assets') -Recurse -Force

Write-Host "Done -> dist/ and root sync (v$ver)"
