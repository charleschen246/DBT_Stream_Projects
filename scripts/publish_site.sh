#!/usr/bin/env bash
# Rebuilds the dbt docs + dashboard from the warehouse and publishes them to GitHub Pages
# (the gh-pages branch). Run after `dbt build` against BigQuery.
set -euo pipefail
cd "$(dirname "$0")/.."

dbt docs generate --static
python scripts/build_dashboard.py

mkdir -p site
cp target/static_index.html site/index.html
touch site/.nojekyll   # serve files as-is

remote="$(git remote get-url origin)"
publish_dir="$(mktemp -d)"
cp -r site/. "$publish_dir"
(
  cd "$publish_dir"
  git init -q -b gh-pages
  git add -A
  git -c user.name="$(git -C "$OLDPWD" config user.name)" -c user.email="$(git -C "$OLDPWD" config user.email)" \
    commit -q -m "Publish docs and dashboard"
  git push -q -f "$remote" gh-pages
)
rm -rf "$publish_dir"
echo "Published to the gh-pages branch."
