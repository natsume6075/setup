#!/usr/bin/env bash
# Optional agent-harness setup for Ubuntu on WSL2.
# Existing linux/setup.sh remains unchanged.
set -euo pipefail

REPO_URL="https://github.com/natsume6075/agent-workspace.git"
WORKSPACE="${AGENT_WORKSPACE:-$HOME/workspace/agent-workspace}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if ! grep -qi microsoft /proc/version 2>/dev/null; then
    echo "Note: WSL was not detected; continuing on Linux."
fi

sudo apt-get update
sudo apt-get install -y curl git ca-certificates unzip

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    echo "Node.js/npm not found. Install Node.js LTS with nvm: https://github.com/nvm-sh/nvm"
    echo "After installing nvm and 'nvm install --lts', rerun this script."
    exit 1
fi

npm install -g @openai/codex@latest

if [ -d "$WORKSPACE/.git" ]; then
    echo "Workspace already cloned: $WORKSPACE (not overwriting)"
elif [ -e "$WORKSPACE" ]; then
    echo "Refusing to overwrite existing directory: $WORKSPACE" >&2
    exit 1
else
    mkdir -p "$(dirname "$WORKSPACE")"
    git clone "$REPO_URL" "$WORKSPACE"
fi

# First bootstrap only: agent-workspace may be an empty remote repository.
if [ ! -e "$WORKSPACE/AGENTS.md" ]; then
    cp "$SCRIPT_DIR/agent-workspace/AGENTS.md" "$WORKSPACE/AGENTS.md"
fi
if [ ! -e "$WORKSPACE/docs/HANDOFF.md" ]; then
    mkdir -p "$WORKSPACE/docs"
    cp "$SCRIPT_DIR/agent-workspace/HANDOFF.md" "$WORKSPACE/docs/HANDOFF.md"
fi

cat <<EOF

Installed Codex: $(codex --version)
Workspace: $WORKSPACE

Next steps:
  1. Run 'codex login' and sign in with ChatGPT.
  2. cd "$WORKSPACE" && codex
  3. Ask Codex to read AGENTS.md and docs/HANDOFF.md and continue.
  4. If agent-workspace was empty, review, commit and push the generated bootstrap files.

Koofr: install its desktop sync client on Windows (not inside headless WSL).
Use Koofr for vault/artifacts; keep active Git working trees on WSL's Linux filesystem.
EOF
