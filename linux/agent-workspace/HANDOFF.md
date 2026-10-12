# Handoff — AI agent environment

## Goal
On Windows + WSL2 Ubuntu, clone `natsume6075/agent-workspace`, run Codex, and use this repository as the durable agent workspace. Later move the execution host to a home Linux server and optionally connect local LLMs. The layout must not depend on Codex-specific mechanisms.

## Ownership
- `natsume6075/setup`: Windows/WSL/Linux provisioning, including optional `linux/setup-agent-harness.sh`. Changes to setup go on `feat/add-agent-harness` until reviewed/merged. Preserve existing setup conventions and minimize user operations.
- `natsume6075/agent-workspace`: harness-neutral instructions, skills, plans, progress and adapters. This new repository starts empty and may need its first commit after bootstrap.
- Koofr: synchronized Obsidian Vault, documents and user-produced artifacts (separate from live Git working trees).

## Agreed architecture
Windows hosts WSL2 Ubuntu 24.04. Codex CLI runs inside WSL on the Linux filesystem. Koofr desktop runs on Windows; WSL can access the synced directory via `/mnt/c/Users/<user>/...` after determining the actual location. iOS Obsidian uses Koofr Sync plugin and its own local vault. Do not assert synchronization/compatibility without a real end-to-end test.
Shared `AGENTS.md`, Skills, and MCP are preferred. Hooks, permissions, settings and subagent wiring require harness-specific adapters. Cloud models first; evaluate Ollama/llama.cpp and GPU/server sizing later.

## Immediate steps for Codex
1. Audit the environment non-destructively: WSL version, Ubuntu release, DNS, apt, node/npm, Codex login, Windows/WSL filesystem paths, network/proxy needs.
2. Read current `setup` and this workspace. Check Git branches, diff, and uncommitted files before editing.
3. Complete and test a reproducible, idempotent bootstrap. Prefer automatic safe operations; for Windows admin prompts, authentication and Koofr login give precise human steps.
4. Initialize this repository with README/AGENTS.md/docs; push only after review. Ensure git identity/authentication are configured without printing secrets.
5. Configure Koofr paths and Obsidian Vault non-destructively. Validate PC => iPhone => PC synchronization. Avoid concurrent modification of same note.
6. Add a small initial harness-neutral skill and documented policies only once requirements are concrete.
7. Investigate Codex remote-control feasibility on this account and platform, then add secure remote operation instructions if verified.
8. Later evaluate Tailscale, home Linux server, secret management, backups, and local-LLM integration.
9. Update this handoff document with actual results, blocked items and next exact command after every work session.

## Safety
Never commit or sync OAuth tokens, API keys, `.env`, `.codex` session/auth state, `.ssh`, `node_modules`, build output, or a live `.git` database inside a cloud-sync mirror. Keep old Ubuntu 20.04 intact until migration is checked. Avoid blindly replacing `.wslconfig`, `resolv.conf`, proxy or shell profiles. User approves outbound writes to Slack/LINE/Google and any destructive change.

## Acceptance
- Fresh Ubuntu 24.04 on WSL2 can run one documented setup command and start Codex in the cloned workspace.
- Workspace persists instructions and task state through a new agent session.
- Koofr and Obsidian Sync workflow is proven by real file edits from both ends.
- No older environment was destroyed, no secrets committed, and rollback is documented.
