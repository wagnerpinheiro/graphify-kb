---
name: kb-setup
description: Meta skill that creates, adopts, updates, upgrades and evaluates local graph-RAG knowledge bases for document workspaces — RDF/OWL ontology + SHACL + SPARQL with a deterministic central engine (no server, no Docker, no MCP, no API key) — organized with the Zettelkasten folders raw/ wiki/ kb/ docs/, plus a generated per-workspace /kb skill, optional task skills and a required graphify graph (installed from the graphify-kb fork). Use it whenever the user wants to start or organize a workspace of documents (RFI/RFP/tender, contracts, research, project docs), "set up a KB / knowledge base / knowledge graph / second brain / Zettelkasten", index raw documents for Claude, migrate or adopt an existing KB, update the KB or graphify incrementally, upgrade the KB engine, generate workspace skills, sync a Teams/SharePoint folder with OneDrive for the team, or measure how many tokens and how much time the KB saves — even if they never say "kb-setup".
---

# kb-setup

Builds and maintains a **local knowledge base per workspace**:

- **Central engine:** `~/.claude/skills/kb-setup/scripts/kb.py` (PEP 723 script, run with `uv`; nothing is installed in the workspace). It finds the workspace root by walking up from the current directory to `kb/config.yaml`. Below, `KB` means `uv run ~/.claude/skills/kb-setup/scripts/kb.py` (always run it from the workspace root, one simple command per Bash call).
- **Core ontology** (prefix `kb:`, English) ships with the engine (`assets/core/`). Each workspace adds a **domain ontology** (`kb/ontology/<prefix>.ttl`), mappings, topics/facts and saved queries.
- **Generated skills in the workspace:** `/kb` (consult and maintain) and, if approved, 2–4 **task skills** prefixed with the project name.
- **graphify** (required), installed from the graphify-kb fork that versions this skill (`references/graphify.md`). Every init/adopt/update installs or checks it and builds its graph over code + `docs/` + `wiki/` (raw/ only per authorized document), coexisting with `/kb`.

Write workspace files in the workspace language (README, notes); generated skills and this skill are in English; **answer the user in the language they write in**.

## Principles (why they exist)

These come from a real deployment and its evals (details in `references/lessons.md`). Follow them unless the user explicitly decides otherwise for a workspace.

1. **Deterministic first.** Conversion (PDF/DOCX/XLSX → Markdown with page markers), structure, spreadsheets, topics and facts are extracted by the engine. Claude only describes images, extracts prose relations for documents the user authorizes, and answers queries. This minimizes exposure of client data and makes updates cheap and repeatable.
2. **Documents only in subagents.** Any reading of document content beyond the compact output of `KB ask/show/query` (multi-page reading, Grep in raw/, image description, prose extraction, graphify extraction, eval answer keys) runs in a `general-purpose` subagent that returns compact results with citations. This keeps client text out of the main context.
3. **Per-document authorization** for full reading by an LLM (prose extraction, graphify over raw/, token-eval baseline). Record authorizations in `kb/SETUP.md`.
4. **Respect managed policies.** Re-read them at every init/upgrade (`references/discovery.md`): no MCP, no hooks, no settings changes, no unapproved marketplaces; one simple command per Bash call so auto mode works; no external LLM keys (never Gemini for graphify).
5. **Portable between git and OneDrive/Teams.** Relative paths, content hashes (never mtime), nothing binary or `.venv` inside the workspace, per-source manifests, advisory curator lock, conflict-copy detection, read-only mode for consumers.
6. **Precedence.** The most recent document wins (date, then version within the same document family); `raw/` wins over `wiki/` unless a note lists the document/entity in `overrides:`. Overdue notes keep precedence but trigger alerts.
7. **Checkpoints belong to the user.** Ontology, mappings, topics/facts rules and task skills are proposed and approved. If you test with a draft before approval (cheap and regenerable), say so at that moment.
8. **Verify subagent work** before using it: self-contained prompts, a verifiable deliverable (file written, commands run, counts) and a re-run if a subagent returns suspiciously fast or only echoes the instruction. Subagents may be refused the Write tool for report files: have them return reports as text and save them yourself.
9. **Suggest improvements** at the end of every operation when signals appear, and log them in `kb/IMPROVEMENTS.md` (`references/improvements.md`).

## Command router

The user may say the subcommand or describe the intent. Identify it, then follow the matching section. Read the referenced files only when you reach that step.

| Command | Intent | Reference |
|---|---|---|
| `init` | new workspace (empty or with documents) | discovery, interview, zettelkasten, onedrive-teams-sync, presets/, graphify, task-skills |
| `adopt` | migrate an existing KB (v1 layout or local engine) | migration, lessons |
| `update` | incremental update of KB + graphify after raw/ or wiki/ changes | improvements, graphify |
| `upgrade` | engine version changed; migrate config/ontology | migration (changelog) |
| `graphify` | reinstall / check version / rescope / rebuild graphify (also runs inside init, adopt, update) | graphify |
| `skills` | propose, generate or regenerate task skills | task-skills |
| `eval` | tokens/time/quality: no KB × graphify only × KB + graphify | evals |
| `review` | analyze usage and propose improvements; manage the backlog | improvements |
| `preset` | extract a generalized preset from a workspace | presets |
| `status` | `KB status` + engine/version/policy/graphify health | — |

## init

1. **Discover** (`references/discovery.md`): folder contents and volume, existing `kb/`, git, OneDrive path (`~/Library/CloudStorage/OneDrive-*` or `OneDrive - <Org>`), managed policies, `uv`/Python, the graphify install (source = the fork, version = the one this skill expects) and other global skills that may compete. If `kb/` already exists → go to **adopt**.
2. **Interview** (`references/interview.md`): ask only what discovery could not answer, with recommended defaults first, using AskUserQuestion in rounds of ≤4. Key decisions: purpose/domain and preset, language, versioning (git / OneDrive-Teams / both), confidentiality and what Claude may read, document precedence/versions, review period, graphify scope (graphify itself is not optional), task skills.
3. **Versioning.** git: the engine writes the `.gitignore` block. OneDrive/Teams: walk the user through `references/onedrive-teams-sync.md` (Microsoft recommends "Add shortcut to My files"; mark the folder "Always keep on this device"; open the synced path in Claude Code) and verify each step before continuing.
4. **Scaffold:** `KB scaffold --title "<title>" --prefix <prefix> --language <lang> --versioning <git|onedrive|both>` then write, from `assets/templates/` (fill placeholders, translate prose to the workspace language): `README.md` (method), `CLAUDE.md` (rules), `.claude/skills/kb/SKILL.md` (the `/kb` skill), `kb/SETUP.md` (decisions and authorizations).
5. **Empty workspace →** follow `references/zettelkasten.md`: explain raw → literature → permanent → docs, create the example notes (removable), then guide the first note with a short interview and `KB new-note "<title>" --type permanent`. Stop here until documents arrive; the core ontology already supports notes.
6. **Workspace with documents:**
   1. `KB lock --command-name init`, then `KB update`: unzip, convert, extract, validate and wiki.
   1b. Dates and versions drive precedence: show the user a table of each source's `document_date`/`version` (frontmatter of the converted `.md`; PDF metadata can be a generation date, not the document date) and fix wrong ones in the frontmatter, listing them in `manual_fields` so reconversion keeps them.
   2. Images: `KB pending-images --json`, then subagents in batches of about 15 unique images. Use the prompt in `assets/templates/prompts.md`; duplicates propagate automatically.
   3. Ontology: choose a preset from `presets/` or start from the core. Read `presets/<name>/preset.md`, then draft `kb/ontology/<prefix>.ttl`, shapes, mappings (`KB outline` gives headings and spreadsheet headers without full text) and saved queries. Fill the placeholders with values from discovery.
   4. Subagents (authorized documents only) survey **topics**, **quantitative facts** and the **attachments map**. They must test every regex rule against the real text and report counts, never client excerpts in your context.
   5. **Checkpoint:** present the ontology, mappings and rules and get approval. Then run `KB update` again, `KB validate` and `KB wiki`, followed by `KB unlock`.
7. **graphify (required)** (`references/graphify.md`): install or verify graphify from the fork (expected version recorded in `kb/config.yaml` → `graphify.version`), write `raw/.graphifyignore` and the root `.graphifyignore`, then build the graph (code + `docs/` + `wiki/`; raw/ only authorized documents) in a subagent. Record version, source and scope in `kb/SETUP.md` and write the coexistence rules into `CLAUDE.md`. Do not close init without a built `graphify-out/graph.json`; if the build is blocked (policy, missing `uv`, GEMINI/GOOGLE key set), stop and ask.
8. **Task skills** (`references/task-skills.md`): propose 2–4 from the material found (preset templates) and generate only those the user approves.
9. **Close:** run the readiness checklist at the end of `references/lessons.md`, record the decisions in `kb/SETUP.md`, and give the user a short summary, open questions and improvement suggestions. Offer `eval` as a baseline.

## adopt

Follow `references/migration.md`. In short: work on a copy first, run `KB migrate --dry-run` and show the plan, then apply with confirmation. Remove ontology declarations now provided by the core, regenerate `/kb` and `CLAUDE.md` from the templates, `KB update --force` + `validate`, compare key answers before/after, then (with confirmation) delete the old local engine (`scripts/kb/`). graphify is required here too: install or verify it from the fork, add the `graphify:` block to `kb/config.yaml` if missing, and build or rebuild the graph (`references/graphify.md`).

## update

1. `KB status`: check the lock, overdue notes, conflict copies and the engine version warning.
2. `KB lock --command-name update`, then `KB update`: only what changed, by content hash.
3. Pending images go to subagents (see init 6.2), then `KB update` again.
4. graphify (always): check that the installed version matches `graphify.version` in `kb/config.yaml` (warn and offer `graphify` if not), then update the graph in a subagent (`references/graphify.md`, incremental mode): `graphify update .` for code, `/graphify . --update` when docs/, wiki/ or authorized raw/ files changed. Respect `.graphifyignore`.
5. `KB unlock`. Report what changed, new conflicts (`KB query conflicts`), internal inconsistencies, stale `llm` extractions, and suggestions.

## upgrade

The engine records `ENGINE_VERSION`; each workspace stores `engine_version` in `kb/config.yaml`. When they differ, the engine prints a warning. Show the changelog (`references/migration.md` → Changelog), back up `kb/config.yaml`, apply the migration steps listed for the versions in between, then run `KB update --force`, `validate`, and update `engine_version`. Never auto-upgrade without confirmation. The same applies to graphify: when the fork's version differs from `graphify.version` in `kb/config.yaml`, show the fork changelog, reinstall from the fork (`references/graphify.md`), rebuild the graph and update `graphify.version` and `kb/SETUP.md`.

## graphify, skills, eval, review, preset

- **graphify:** `references/graphify.md`.
- **skills:** `references/task-skills.md`. Templates live in `presets/<name>/task-skills/`. Regeneration shows a diff and keeps sections marked `<!-- manual -->`.
- **eval:** `references/evals.md`, with `scripts/eval_report.py` for aggregation. Default: 12 questions × 3 runs × 3 configurations, on an authorized subset, entirely in subagents. The report relates tokens, time and tool calls to data volume (`KB volume --json`), subtracts the measured fixed cost of a subagent, tests savings paired by question, and includes build cost, break-even and the "KB inline" estimate.
- **review:** `references/improvements.md`.
- **preset:** `references/presets.md`. Generalize: no institution, program or person names and no document IDs; use placeholders.

## status

Run `KB status` and `KB --version`, check that `engine_version` matches, report `.claude/skills/kb` and `CLAUDE.md` presence, graphify health (installed version vs `graphify.version`, `graphify-out/graph.json` present and its age, scope), and the open items in `kb/IMPROVEMENTS.md`.

## Answer style (for /kb and task skills you generate)

Cite every fact (`file, p.N` or `file, sheet X, row N`), say when a fact comes from a wiki note, repeat engine `ALERT`/`WARNING` lines, surface conflicts and which source wins, and say plainly when the KB has no answer.
