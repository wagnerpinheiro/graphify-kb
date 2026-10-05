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
- Requirements: the **kb-setup** skill installed in `~/.claude/skills/kb-setup/` and `uv`.

## Versioning
{{VERSIONING_NOTES}}
