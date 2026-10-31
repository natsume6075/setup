#!/usr/bin/env bash
# Install Ubuntu's packaged GitHub CLI; authentication stays with the human user.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run with sudo bash.' >&2; exit 1; }
. /etc/os-release
[[ $ID == ubuntu ]] || { echo 'This installer targets Ubuntu.' >&2; exit 1; }
apt-get update
apt-get install -y gh
gh --version
echo 'As your normal user: gh auth login --hostname github.com --git-protocol https --web'
echo 'Then: gh auth setup-git'
