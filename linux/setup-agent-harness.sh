#!/usr/bin/env bash
# Optional Codex setup on Ubuntu/WSL2. Existing linux/setup.sh stays unchanged.
set -euo pipefail

REPO_URL="https://github.com/natsume6075/agent-workspace.git"
WORKSPACE="${AGENT_WORKSPACE:-$HOME/workspace/agent-workspace}"

if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "Note: WSL not detected; continuing on Linux."
fi

sudo apt-get update
sudo apt-get install -y curl git ca-certificates

# Prefer a reproducible Node LTS via nvm (no system-wide npm permissions).
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts
npm install -g @openai/codex@latest

if [ -d "$WORKSPACE/.git" ]; then
    echo "Workspace already cloned: $WORKSPACE (no overwrite, no automatic pull)"
elif [ -e "$WORKSPACE" ]; then
    echo "Refusing to overwrite existing directory: $WORKSPACE" >&2
    exit 1
else
    mkdir -p "$(dirname "$WORKSPACE")"
    git clone "$REPO_URL" "$WORKSPACE"
fi

for required in README.md AGENTS.md .agents/docs/TASKS.md .agents/docs/HANDOFF.md .codex/config.toml; do
    if [ ! -f "$WORKSPACE/$required" ]; then
        echo "Missing in agent-workspace: $required" >&2
        echo "Check the repository's branch and clone state. No files were overwritten." >&2
        exit 1
    fi
done

echo
echo "Codex: $(codex --version)"
echo "Workspace: $WORKSPACE"
cat <<'EOF'

Next:
  codex login
  cd ~/workspace/agent-workspace
  codex

Codex reads AGENTS.md; ongoing tasks and handoff are under .agents/docs/.
Set up Koofr desktop on Windows separately. Do not cloud-sync a live Git worktree.
EOF
