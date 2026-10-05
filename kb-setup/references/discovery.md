# Discovery (run before asking anything)

Goal: answer as much as possible from the machine, so the interview only asks what truly needs the user. Use simple read-only commands (one per Bash call). Do not open document contents here — only names, sizes, counts and metadata.

## 1. Workspace
- `pwd`, `ls -la`, and a recursive listing limited to names/sizes (e.g. `find . -maxdepth 4 -type f -not -path './.git/*' | head -200`, `du -sh raw wiki docs 2>/dev/null`).
- Existing structure: `raw/`, `wiki/`, `kb/`, `docs/`, `kb/config.yaml` (→ adopt if present), `scripts/kb/kb.py` (v1 local engine → adopt), `.claude/skills/`, `CLAUDE.md`, `README.md` (read README/CLAUDE.md fully: they often contain the user's KB rules — precedence, header, versioning).
- Formats and volume: count by extension (pdf, docx, xlsx, pptx, zip, md, images); total MB; language guess from file names. ZIPs will be unzipped into sibling folders.
- Duplicates: `shasum -a 256` over binaries; byte-identical files are common (downloads saved twice under different names). They must be flagged and prose-extracted only once.
- Version hints in names (`v1.1.0`, `-v4`, `6ª Versão`, `rev 3`) and families of versions.

## 2. Versioning
- git: `git rev-parse --is-inside-work-tree`, `git status --short | head`, `.gitignore` contents (binaries ignored? the KB versions the converted .md and kb/).
- OneDrive/Teams: path under `~/Library/CloudStorage/OneDrive-*` (macOS) or `OneDrive - <Org>` / `%userprofile%\<Org>` (Windows). If present, the team probably shares the folder: plan for the curator lock, conflict copies and read-only consumers.

## 3. Managed policies (re-read at every init and upgrade — they change)
Read, if they exist: `~/.claude/remote-settings.json`, `~/.claude/policy-limits.json`, `/Library/Application Support/ClaudeCode/managed-settings.json` (macOS) or the platform equivalent, plus `~/.claude/settings.json` and project `.claude/settings*.json` (read-only). Check:
- `allowedMcpServers` / MCP restrictions → the KB never depends on MCP;
- `allowManagedHooksOnly` / hooks → no hooks: updates are manual (`/kb update`), reminders go in CLAUDE.md;
- `strictKnownMarketplaces`, plugin restrictions → skills are plain folders, never plugins;
- `permissions.allow/ask/deny` (pip/uv/docker/curl/network) → if `uv` or PyPI is blocked, stop and ask;
- `disableBypassPermissionsMode` → plan for auto mode: one simple command per call;
- `availableModels`, `cleanupPeriodDays` (affects session transcripts used for timing).
Never modify settings; if something is blocked, explain and ask.

## 4. Tools
- `uv --version` (required), `python3 --version` (the engine pins its own via uv), `git --version`.
- Engine health: `uv run ~/.claude/skills/kb-setup/scripts/kb.py --version` (first run creates the uv cache environment; nothing is written to the workspace).
- graphify (required; `references/graphify.md`). Check, one command per call:
  - `graphify --version` → must match the version this skill expects (0.9.76, the fork's `pyproject.toml`) and, in an existing workspace, `graphify.version` in `kb/config.yaml`;
  - `uv tool dir`, then read `<that dir>/graphifyy/uv-receipt.toml` → the `graphifyy` requirement must come from the fork (`editable = "<checkout path>"` or `git = "https://github.com/wagnerpinheiro/graphify-kb…"`), not a bare PyPI name;
  - `readlink ~/.claude/skills/kb-setup` → the fork checkout, if kb-setup is installed through the symlink (preferred install source);
  - `ls ~/.claude/skills/graphify` (global skill written by `graphify install --platform claude`) and `ls .claude/skills/graphify` (an old project-scoped copy from kb-setup < fork: plan to remove it so the fork's global skill is used).
  Missing, PyPI-sourced or a different version → plan the install/upgrade step and tell the user before the interview; do not continue init without graphify.
- Environment keys that would send data out: `env | grep -E '^(GEMINI_API_KEY|GOOGLE_API_KEY)='` (count only). If set, graphify must not run on client documents.

## 5. Competing skills
List global skills whose descriptions claim generic "questions about the project/files/documents" (graphify does). Plan explicit routing rules for the workspace CLAUDE.md so questions about sources go to `/kb`.

## 6. Output
Summarize findings in 10–15 lines for the user (no document content), list what you will ask, and record them later in `kb/SETUP.md`.
