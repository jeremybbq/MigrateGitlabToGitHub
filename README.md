# MigrateGitlabToGitHub
A simple script for migrating all repos from Aalto Version GitLab to GitHub.

export GITLAB_USER="your_aalto_version_user_name"
export GITHUB_USER="your_github_user_name"

and generate access tokens for both platforms and export them,

export GITLAB_TOKEN="your_aalto_version_access_token"
export GITHUB_TOKEN="your_github_access_token" 

Then run the script with

./migrate_all_repos.sh

Note! If you are not migrating from the Aalto Version, you can change the default GitLab URL with

export GITLAB_URL = "your_gitlab_base_url"
