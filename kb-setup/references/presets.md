# Presets: choosing, filling and extracting

A preset packages domain knowledge that worked in a past workspace — without anything identifying that workspace. Location: `presets/<name>/` with `preset.md` (purpose, extra interview questions, placeholders, checkpoints), `ontology.ttl.tpl`, `shapes.ttl.tpl`, `mappings/*.yaml.tpl`, `topics.yaml`, `facts.yaml`, `attachments.md`, `queries/*.rq`, `task-skills/`, `eval-questions.md`.

## Choosing (init)
List presets with one line each (from `preset.md`). If none fits, start from the core ontology only and grow the domain ontology from the documents (outline → draft → approval).

## Filling placeholders
- `{{PREFIX}}`, `{{NAMESPACE}}` — from `kb/config.yaml` `ontology:`.
- `{{CLIENT}}`, `{{PROGRAM}}` — from discovery/interview (never hard-code them back into the preset).
- `{{SHEET_*}}`, `{{COL_*}}`, header rows — from `KB outline "<xlsx>"` (headers only).
- topics/facts regexes — keep the multilingual defaults, then have a subagent test each rule against the authorized documents and report hit counts per document; disable rules with 0 hits; add rules for concepts the subagent finds in 2+ documents.
- Validate: parse `.ttl` (the engine's `validate`), dry-run queries (`KB query <name> --param ...`).

## Extracting a new preset (`/kb-setup preset`)
1. Source workspace must be working (validate ok). Copy its ontology, shapes, mappings, config `topics/facts/attachments`, saved queries, task skills and eval question types into a scratch folder.
2. Generalize: replace institution/program/person names, document IDs, client-specific numbers and file names with placeholders or generic wording; translate identifiers to English (labels may keep pt/es); remove client-specific rules that would not transfer, keeping their *experience* as comments ("tuned on Portuguese phrasing like …" without client text).
3. Grep the result (case-insensitive) for every client/program/person name and ID found in the source workspace; must return nothing.
4. Show the user the preset tree and the grep result; save to `~/.claude/skills/kb-setup/presets/<name>/` only after approval.
