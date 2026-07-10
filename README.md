# MigrateGitlabToGitHub
A simple script for migrating all repos from GitLab (including LMS FAU GitLab) to GitHub.

`export GITLAB_USER="your_gitlab_user_name"`

`export GITHUB_USER="your_github_user_name"`

and generate access tokens for both platforms and export them,

`export GITLAB_TOKEN="your_gitlab_access_token"`

`export GITHUB_TOKEN="your_github_access_token" `

Then run the script with

`./migrate_all_repos.sh`

The default GitLab URL is `https://gitlab.lms.fau.de`. If needed, you can override it before running the script with

`export GITLAB_URL="your_gitlab_base_url"`
