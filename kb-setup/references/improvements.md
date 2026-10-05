# Improvements: signals, suggestions and the backlog

Both kb-setup and the generated skills must notice signals during work and turn them into concrete suggestions. Mention them in a short **Suggestions** section at the end of the answer/operation (only when something relevant happened), and append them to `kb/IMPROVEMENTS.md` (id, date, origin, signal/evidence without document excerpts, suggestion, status `open`). `/kb-setup review` reads the backlog plus fresh signals, proposes a plan, and applies only what the user approves (then marks `done`/`rejected`).

## Signal → suggestion catalog
| Signal (how to notice) | Suggestion |
|---|---|
| Answering one topic took > 3 `ask`/`query` calls, or several asks with loose terms | saved query (parametrized `.rq` with `{{param}}`), or a `topics`/`facts` rule; add domain words to `ask.text_props` |
| `AVISO/WARNING: no entity covers all terms` or `NO ANSWER IN KB` for a question the documents do answer (confirmed by a subagent) | missing mapping, topic/fact rule, section class, or prose extraction (`extract-llm`) for that document (needs authorization) |
| User/other session found a contradiction the KB did not flag | `facts` rule (concept + value) or `topics` rule; test it by subagent; check `internal-inconsistencies` |
| `conflicts` shows unresolved ties (same date and version) | set `version` (+ `manual_fields`) in the converted .md frontmatter, or a `families` entry, or a note with `overrides:` |
| Many notes overdue (`stale`) or "header inferred" | remind reviewers; fix headers; adjust `review_every` |
| Pending images keep reappearing / decorative images described | tune `images.*` thresholds (min size, repeated pages ratio) |
| Converted text has tables swallowed, broken headings, repeated headers | tune `pdf.*` (frame_table_ratio, heading_size_ratio, repeated lines); bump converter only via engine upgrade |
| References "Attachment N" unresolved or divergent | build/extend the `attachments` map (subagent), report numbering divergences to the user (they may matter for the deliverable) |
| Spreadsheet without mapping (`status` alert) | propose `kb/mappings/<name>.yaml` from `outline` headers; user approves |
| Duplicate binaries | extract prose only once; consider removing the copy |
| graphify answered a source question / routing ambiguity | strengthen CLAUDE.md routing rule; check `graphify-out/` presence |
| Subagent returned too fast or echoed the instruction | re-run with explicit "execute now"; prefer general-purpose over fork |
| Eval: a configuration loses accuracy on a question type, or is slow there | targeted fix (rule/query/mapping) and re-run that slice |
| Same helper reasoning repeated across sessions | new saved query, new task skill, or a preset update (`/kb-setup preset`) |

## Review flow (`/kb-setup review`)
1. `KB status`, `KB query conflicts`, `KB query internal-inconsistencies`, `KB query gaps` (if present), `KB stale`, `KB pending-images`, latest `kb/evals/*/summary.json`, `kb/IMPROVEMENTS.md` open items.
2. Group findings by impact (wrong/missing answers > cost > hygiene). Propose ≤ 7 actions with effort and expected gain.
3. Apply approved ones (rules/queries/mappings/skills), `KB update`, `KB validate`, re-test the affected questions, update the backlog.
