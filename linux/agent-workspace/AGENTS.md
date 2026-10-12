# Agent workspace

This is the portable starting point for an AI agent. The environment installer lives in [setup](https://github.com/natsume6075/setup); this repository contains the shared instructions, skills, decisions and handoff.

- Follow `docs/HANDOFF.md` and keep it updated after each milestone.
- Use minimal, reviewable changes and test before committing.
- Treat `setup` as the source of truth for OS and package installation.
- Prefer harness-neutral `AGENTS.md`, portable Agent Skills, and MCP where appropriate. Keep harness-specific adapters isolated.
- Keep working Git repositories on the Linux filesystem, not within a bidirectionally synchronized cloud folder.
- Koofr syncs personal knowledge and artifacts; do not commit vault contents, tokens, local configs, or credentials.
- Do not modify/delete existing personal data, publish to external services, enable remote access, or install services without explicit approval.
- Track pending manual steps instead of claiming completion without validation.
