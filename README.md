# Peter Pau Sian Lian — Portfolio (peterlianpi.site)

Source for [peterlianpi.site](https://peterlianpi.site).  
Architecture: **JSON model → build → static dist → nginx**.

**GitHub profile:** [github.com/peterlianpi](https://github.com/peterlianpi) · **Source branch:** [peterlianpi/peterlianpi `portfolio-site`](https://github.com/peterlianpi/peterlianpi/tree/portfolio-site)

## Structure (MVC-lite)

```
about-me/
├── data/
│   └── portfolio-profile.json   # Model — single source of truth
├── src/                         # Source (views + assets)
│   ├── index.template.html      # HTML shell with {{placeholders}}
│   └── assets/
│       ├── css/site.css         # Site styles
│       ├── css/chat.css         # Chat widget styles
│       └── js/
│           ├── main.js          # Nav, theme, hero canvas
│           └── chat/
│               ├── view.js      # Chat rendering
│               └── controller.js # Chat API + UI
├── scripts/
│   ├── build.ps1 / build.sh     # Build → dist/ + config.js
│   └── fetch-github.*
├── dist/                        # Generated — deploy this
└── deploy/
    ├── deploy.ps1               # build + upload dist/
    └── nginx-peterlianpi.site.conf
```

| Layer | Role |
|-------|------|
| **Model** | `data/portfolio-profile.json` |
| **View** | `src/index.template.html` + CSS |
| **Controller** | `scripts/build.ps1` generates HTML + `assets/js/config.js` |
| **Chat** | `view.js` + `controller.js` + generated config |

## Workflow

1. Edit **`data/portfolio-profile.json`** (job, stack, projects, chat prompts).
2. Build: `.\scripts\build.ps1` or `./scripts/build.sh`
3. Deploy: `.\deploy\deploy.ps1` (builds automatically)

Preview: open `dist/index.html` locally (chat needs live nginx proxy).

## AI chat

Proxied to [pcore-chatgpt](https://pcore-chatgpt.peterlianpi.site/). API key only in `deploy/secrets.env` (nginx).

## Scripts

| Task | Command |
|------|---------|
| Build site | `.\scripts\build.ps1` |
| Deploy (build + upload) | `.\deploy\deploy.ps1` |
| Refresh GitHub data | `.\scripts\fetch-github.ps1` |
| Apply nginx | `.\deploy\apply-nginx.ps1` |
| Refresh GitHub API data | `.\scripts\fetch-github.ps1` |
| Push to GitHub | `.\scripts\publish-github.ps1` |

## Publish to GitHub

```powershell
.\scripts\publish-github.ps1
```

This pushes:

- **`portfolio-site` branch** on [peterlianpi/peterlianpi](https://github.com/peterlianpi/peterlianpi) (full portfolio source)
- **Profile README** on `main` (if `_github-profile/` clone exists)

Optional: create a dedicated [about-me](https://github.com/new?name=about-me) repo and set `GITHUB_TOKEN` to auto-create + push there.

## Server

- **Host:** `awsserver`
- **Path:** `/var/www/peterlianpi.site/`
- **Chat:** `/api/chat/` → pcore-chatgpt

Never commit `deploy/secrets.env`.
