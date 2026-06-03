#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$ROOT/data"
# shellcheck source=config.env
source "$SCRIPTS_DIR/config.env"

mkdir -p "$DATA_DIR"

echo "Fetching GitHub profile..."
curl -fsSL "https://api.github.com/users/$GITHUB_USER" \
  | python3 -m json.tool > "$DATA_DIR/github-profile.json"

echo "Fetching GitHub repos..."
curl -fsSL "https://api.github.com/users/$GITHUB_USER/repos?sort=updated&per_page=100" \
  > "$DATA_DIR/github-repos.json"

echo "Fetching profile README..."
curl -fsSL "https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_PROFILE_REPO/main/README.md" \
  -o "$DATA_DIR/github-readme.md"

echo "Building original projects list..."
python3 - "$DATA_DIR/github-repos.json" "$DATA_DIR/github-repos-original.json" <<'PY'
import json, sys
repos = json.load(open(sys.argv[1], encoding="utf-8"))
original = [
    {
        "name": r["name"],
        "description": r.get("description"),
        "url": r["html_url"],
        "language": r.get("language"),
        "stars": r.get("stargazers_count", 0),
        "updated": r.get("updated_at"),
    }
    for r in repos
    if not r.get("fork")
]
json.dump(original, open(sys.argv[2], "w", encoding="utf-8"), indent=2)
print(f"  {len(original)} original projects")
PY

REPO_COUNT="$(python3 -c "import json; print(len(json.load(open('$DATA_DIR/github-repos.json'))))")"

echo "Done. Saved to $DATA_DIR"
echo "  - github-profile.json"
echo "  - github-repos.json ($REPO_COUNT repos)"
echo "  - github-repos-original.json"
echo "  - github-readme.md"
