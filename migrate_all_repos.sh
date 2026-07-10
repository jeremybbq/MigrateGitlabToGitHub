#!/bin/bash
set -e

# =======================
# CONFIGURATION
# =======================
GITLAB_URL=${GITLAB_URL:-"https://gitlab.lms.fau.de"}
GITLAB_API_BASE=${GITLAB_URL%/}
GITLAB_USER=${GITLAB_USER:-""}
GITLAB_TOKEN=${GITLAB_TOKEN:-""}
GITHUB_USER=${GITHUB_USER:-""}
GITHUB_TOKEN=${GITHUB_TOKEN:-""}

# Check required variables
if [ -z "$GITLAB_USER" ] || [ -z "$GITHUB_USER" ] || [ -z "$GITHUB_TOKEN" ] || [ -z "$GITLAB_TOKEN" ]; then
  echo "⚠️  Please export all required environment variables:"
  echo "   GITLAB_USER, GITLAB_TOKEN, GITHUB_USER, GITHUB_TOKEN"
  exit 1
fi

# =======================
# FETCH REPOS FROM GITLAB
# =======================
echo "Fetching GitLab repositories for $GITLAB_USER ..."

# Use membership-based API
curl --silent --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$GITLAB_API_BASE/api/v4/projects?membership=true&per_page=100" \
  | grep -o '"http_url_to_repo":"[^"]*"' | cut -d'"' -f4 > gitlab_repos.txt

REPO_COUNT=$(wc -l < gitlab_repos.txt)
echo "Found $REPO_COUNT repositories."

if [ "$REPO_COUNT" -eq 0 ]; then
  echo "⚠️  No repositories found. Check your GitLab token or URL."
  exit 1
fi

# =======================
# MIGRATE EACH REPO
# =======================
mkdir -p migrated
cd migrated

while read -r REPO_URL; do
  REPO_NAME=$(basename "$REPO_URL" .git)
  echo "----> Processing $REPO_NAME"

  # Skip if already cloned locally
  if [ -d "$REPO_NAME.git" ]; then
    echo "✅ $REPO_NAME already cloned locally, skipping."
    continue
  fi

  # Skip if repo already exists on GitHub
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -u "$GITHUB_USER:$GITHUB_TOKEN" \
    "https://api.github.com/repos/$GITHUB_USER/$REPO_NAME")
  
  if [ "$RESPONSE" -eq 200 ]; then
    echo "✅ $REPO_NAME already exists on GitHub, skipping."
    continue
  fi

  # --- Clone mirror from GitLab ---
  echo "Cloning $REPO_NAME from GitLab ..."
  AUTH_REPO_URL=${REPO_URL/https:\/\//https:\/\/oauth2:$GITLAB_TOKEN@}
  git clone --mirror "$AUTH_REPO_URL"

  cd "$REPO_NAME.git"

  # --- Remove files >100MB ---
  echo "Removing files larger than 100MB from history ..."
  git filter-repo --strip-blobs-bigger-than 100M

  # --- Create GitHub repo ---
  echo "Creating GitHub repo $REPO_NAME ..."
  curl -s -u "$GITHUB_USER:$GITHUB_TOKEN" \
       -d "{\"name\":\"$REPO_NAME\", \"private\":true}" \
       https://api.github.com/user/repos >/dev/null

  # --- Push to GitHub ---
  echo "Pushing $REPO_NAME to GitHub ..."
  git remote add github "https://$GITHUB_USER:$GITHUB_TOKEN@github.com/$GITHUB_USER/$REPO_NAME.git"

  # Push all refs (mirror) to GitHub
  git push --mirror github

  cd ..
  echo "🎉 $REPO_NAME migrated successfully."

done < ../gitlab_repos.txt

echo "✅ All repositories processed!"
