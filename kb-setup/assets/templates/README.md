# {{TITLE}}

<!-- kb-setup: write this README in the workspace language; keep it short and practical -->

{{PURPOSE}}

## Folders (Zettelkasten)
| Folder | What goes there |
|---|---|
| `raw/` | Sources as received (client, vendors, partners). Binaries (PDF/DOCX/XLSX/ZIP) get a `.md` with the same name beside them (deterministic conversion; images described in text). |
| `wiki/` | Team notes: `fleeting` (capture, minutes), `literature` (reading notes about one source), `permanent` (atomic ideas/decisions). Name: `YYYY-MM-DD-slug.md`; link with `[[...]]`. |
| `kb/` | Knowledge base (generated): ontology, triples, change index, navigable wiki (`kb/wiki/index.md`), evals, improvement backlog. |
| `docs/` | Deliverables produced here. Never indexed. |

## Note header
```yaml
---
title: ...
type: fleeting            # fleeting | literature | permanent
source: raw/...           # literature notes
last_reviewed: YYYY-MM-DD
reviewed_by: Full Name
review_every: {{REVIEW_EVERY}}
overrides: []             # raw/ sources or id:topic/<name> this note explicitly overrides
---
```
Facts for the graph (one per line): `- Decision: …`, `- Hypothesis: …`, `- Assumption: …`, `- Deadline: <milestone> = YYYY-MM-DD`, `- Term: <ACRONYM> = <definition>`, `- Condition: <topic> = <value>`.

## Precedence when sources disagree
1. The most recent document wins (date; same document family: version).
2. raw/ wins over wiki/, unless a note lists the source/topic in `overrides:`.
3. Overdue notes (past `review_every`) keep precedence but answers warn.

## Using it (Claude Code CLI or the Code tab of Claude Desktop, with this folder open)
- Ask questions in natural language (the `/kb` skill answers citing file/page).
- `/kb update` after adding/changing files (curator), `/kb status`, `/kb stale`, `/kb new-note "<title>"`.
- `/kb-setup review` for improvements, `/kb-setup eval` to measure tokens/time/quality, `/kb-setup upgrade` when the engine changes.

## Requirements and installation
<!-- kb-setup: keep the commands as they are; when this workspace has no engine copy, remove every line that mentions scripts/kb-engine -->
Who needs what: **consulting** (questions, `/kb status`) needs uv and Claude Code; **curating** (`/kb update`, `/kb-setup ...`) also needs the kb-setup skill and graphify. This workspace carries a copy of the engine in `scripts/kb-engine/`, so consulting works without kb-setup.

| Tool | macOS | Linux | Windows |
|---|---|---|---|
| [uv](https://docs.astral.sh/uv/) (required) | `brew install uv` or `curl -LsSf https://astral.sh/uv/install.sh \| sh` | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | `winget install --id=astral-sh.uv -e` or `powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 \| iex"` |
| Python ≥ 3.10 | provided by uv (nothing to install) | provided by uv | provided by uv |
| Claude Code | CLI or the Code tab of Claude Desktop | CLI | CLI or the Code tab of Claude Desktop |
| Node.js (only for `npx`) | `brew install node` | your distribution's package manager (e.g. `sudo apt install nodejs npm`) | `winget install OpenJS.NodeJS.LTS` |

1. **kb-setup skill** (required for curators; optional for consultants when `scripts/kb-engine/` exists):
   `npx skills add wagnerpinheiro/graphify-kb --skill kb-setup -g -a claude-code`, then open a new Claude Code session.
2. **graphify** (curators): `uv tool install --force "git+https://github.com/wagnerpinheiro/graphify-kb@v8"`, then `graphify install --platform claude`.
3. **Check:** `uv run scripts/kb-engine/kb.py --version` (workspace copy) or `uv run ~/.claude/skills/kb-setup/scripts/kb.py --version` (kb-setup installed).

Notes:
- The first run downloads the engine's Python dependencies into the uv cache, outside this folder; nothing is installed in the workspace.
- Windows (PowerShell): write `$HOME\.claude\skills\kb-setup\...` where these instructions say `~/.claude/skills/kb-setup/...`.
- OneDrive/Teams: mark this folder (at least `scripts/kb-engine/`) as "Always keep on this device" so the engine is available offline.

## Versioning
{{VERSIONING_NOTES}}
