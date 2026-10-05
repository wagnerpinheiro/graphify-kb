# kb-setup: a local knowledge base per workspace (graph-RAG + graphify)

🇺🇸 English | 🇧🇷 [Português](README.pt-BR.md)

## What it is

`kb-setup` is a Claude Code meta skill. It creates, adopts, updates and evaluates a **local knowledge base (KB) for
each document workspace** (RFI/RFP, contracts, research, project documentation). The KB is a deterministic graph-RAG
built on **RDF/OWL + SHACL + SPARQL**: no server, no Docker, no MCP and no API key. Files are organized in the
Zettelkasten folders `raw/` (official sources), `wiki/` (team notes), `kb/` (ontology, mappings, configuration) and
`docs/` (deliverables, never indexed). Each workspace gets a `/kb` skill for querying and maintenance and, if you
approve them, a few task skills.

**graphify is required** and comes **from this fork** (`graphify-kb`). kb-setup and graphify are versioned together in
this repository. Every `init`, `adopt` and `update` installs or checks graphify and builds its graph over
code + `docs/` + `wiki/`. Documents in `raw/` are included only with per-document authorization (`raw/.graphifyignore`).

```
Claude Code ──► kb-setup skill (~/.claude/skills/kb-setup → <fork>/kb-setup)
                   │
                   ├─► engine  scripts/kb.py   (PEP 723, run with uv; nothing installed in the workspace)
                   │      └─► workspace/  raw/ wiki/ kb/ docs/  +  /kb skill  +  CLAUDE.md
                   │                      (+ optional engine copy in scripts/kb-engine/)
                   │
                   └─► graphify (uv tool installed from this fork)
                          └─► workspace/graphify-out/  (exploratory graph; kept out of git)
```

## Goal

Build, on top of this fork's graphify, a **local KB for document workspaces** that combines a usage method based on the
Zettelkasten with an **ontology-guided graph-RAG** (RDF/OWL + SHACL + SPARQL). Instead of retrieving passages that look
like the question, it answers with typed entities and structural queries, applies precedence, detects conflicts and
cites the page or spreadsheet row. It is deterministic and local. graphify remains the exploratory graph of code and
themes; the two graphs are kept separate on purpose (no data bridge, `references/graphify.md`).

### What the ontologies add

- **Types:** the `kb:` core (`assets/core/kb-core.ttl`) aligns its classes with PROV, Dublin Core and SKOS (documents
  and notes are `prov:Entity`, people are `prov:Agent`, glossary terms are `skos:Concept`). Domain presets
  (`presets/rfi-proposal`, `presets/erp-rollout-program`) add their own classes, shapes, mappings and queries.
- **Validation:** SHACL shapes (`kb-core-shapes.ttl` + the preset shapes) check the graph whenever an update changes it.
- **Provenance:** one named graph per source, and every fact points back to its source with page, or sheet and row.
- **Precedence:** a wiki note with `overrides:` wins; otherwise `raw/` wins over `wiki/`; within the same layer, the
  most recent version wins (`assets/queries/precedence.rq`).
- **Conflicts:** values consolidated per topic/fact (`topics.yaml`, `facts.yaml`) expose divergences between sources
  and inside one source (`conflicts.rq`, `internal-inconsistencies.rq`).
- **Saved SPARQL queries:** conflicts, gaps, RACI by role, deadlines, internal inconsistencies, notes due for review
  (`assets/queries/`, `presets/*/queries/`).

In the eval (one run, 12 questions, 6 documents) the KB scored 24/24 on accuracy and 24/24 on citation, against 21/24
and 18/24 for graphify alone, with a much lower build cost. The sample is small; treat it as a signal, not a benchmark.

### The Zettelkasten method

- **Folder roles:** `raw/` holds the sources, `wiki/` the team's notes, `kb/` the generated index and graph, `docs/`
  the deliverables (never indexed).
- **Notes become triples:** note types `fleeting`, `literature` and `permanent`; `[[links]]` between notes become
  `kb:linksTo`; lines such as `- Decision: …`, `- Deadline: <milestone> = YYYY-MM-DD`, `- Term: <ACRONYM> = …` and
  `- Condition: <topic> = <value>` become facts in the graph (`references/zettelkasten.md`).
- **Review:** each note carries `last_reviewed` and, optionally, `review_every`; `/kb stale` lists the overdue ones.
- **An adaptation, not the orthodox method:** there is no Folgezettel numbering and `wiki/` is flat
  (`wiki/YYYY-MM-DD-short-slug.md`); the note type lives in the header.

Note: the entry search is lexical in both systems and neither uses embeddings. graphify scores node labels by term and
then walks the graph; `KB ask` weights term matches by property. The ontology's gain comes after the search: types,
validation, structural queries, precedence, conflicts and provenance.

### Guided setup for non-technical users

Offer a guided first setup for people who just need a working KB. The skill finds out on its own whatever it can, asks
only what is essential with recommended defaults, installs and configures graphify and hands over a workspace ready to
use with `/kb`. The user does not need to understand graphify, ontologies, RDF or SPARQL.

- **Discovery before any question:** the skill inspects the folder, versioning, policies and tools without opening
  document contents (`references/discovery.md`).
- **Autonomous mode:** the first question of init. Choose it and the skill asks nothing else: it takes the recommended
  option at every decision, approves the checkpoints itself and lists every assumed decision in the closing summary.
- **Short interview:** rounds of up to 4 questions, with the recommended option first (`references/interview.md`).
- **Automatic graphify:** install from the fork and build the graph, with a safe scope by default (code + `docs/` +
  `wiki/`; `raw/` only with per-document authorization).
- **Empty workspace:** the method is explained, example notes are created and the first note is guided
  (`references/zettelkasten.md`).
- **Daily use:** only `/kb <question>` and `/kb update`.

Current limit: the ontology, mapping and rule checkpoints are still presented in technical terms. Accepting the
recommended proposal works, but a plain-language presentation is the next improvement.

## Prerequisites

- [`uv`](https://docs.astral.sh/uv/) (required; it also provides the Python the engine runs on)
- Python ≥ 3.10
- Claude Code
- git
- Node.js, only to install with `npx skills`
- Optional: OneDrive/Teams, to share the workspace with the team (`references/onedrive-teams-sync.md`)

## Installation

### Quick install with `npx skills`

Install only the meta skill, globally for Claude Code:

```bash
npx skills add wagnerpinheiro/graphify-kb --skill kb-setup -g -a claude-code
```

The skill lands in `~/.claude/skills/kb-setup`. graphify does not need to be installed beforehand: on the first
`/kb-setup init`, discovery detects that it is missing and installs it from the fork. To install it right away, use the
command in step 2 below (fallback without a clone). Check with step 4.

### Install from a clone

The commands use `REPO` for the clone path. Change the variable if you clone somewhere else.

1. **Clone the fork**

   ```bash
   REPO=~/workspaces/github/graphify-kb
   git clone git@github.com:wagnerpinheiro/graphify-kb.git "$REPO"
   ```

2. **Install graphify from the fork** as an editable uv tool (a `git pull` in the fork updates graphify too), plus the
   global `/graphify` skill:

   ```bash
   uv tool install --force -e "$REPO"
   graphify install --platform claude
   ```

   `--force` replaces a `graphifyy` previously installed from PyPI.

   **Fallback without a clone** (for people who only need graphify): install straight from GitHub. Replace `@v8` with
   a commit or tag to pin the version.

   ```bash
   uv tool install --force "git+https://github.com/wagnerpinheiro/graphify-kb@v8"
   graphify install --platform claude
   ```

   To run a one-off command without installing: `uvx --from "git+https://github.com/wagnerpinheiro/graphify-kb@v8" graphify --version`.
   This does not replace the install: the `/graphify` skill looks for the `graphifyy` uv tool and, if it is missing,
   installs the PyPI release, which is not this fork's version.

3. **Link the skill** with a symlink. If a local copy already exists at `~/.claude/skills/kb-setup`, move it
   **outside** `~/.claude/skills/` first, otherwise Claude Code loads two `kb-setup` skills:

   ```bash
   mkdir -p ~/.claude/skills
   [ -e ~/.claude/skills/kb-setup ] && mv ~/.claude/skills/kb-setup ~/kb-setup.bak-$(date +%Y%m%d)
   ln -s "$REPO/kb-setup" ~/.claude/skills/kb-setup
   ```

4. **Verify**

   ```bash
   graphify --version                                   # graphify 0.9.76
   uv run ~/.claude/skills/kb-setup/scripts/kb.py --version   # kb.py engine 2.1.0 · kb-setup 2.1.0 (central)
   uv run ~/.claude/skills/kb-setup/scripts/kb.py --help
   ```

   Then open a **new** Claude Code session and check that the `kb-setup` skill shows up in the skill list (for
   example, by typing `/kb-setup`).

## First run in a new workspace

1. **Create or open the workspace folder and start Claude Code in it.** Documents can already be there or arrive
   later.

   ```bash
   mkdir -p ~/workspaces/my-kb && cd ~/workspaces/my-kb
   claude
   ```

2. **Trigger the skill** with `/kb-setup init` or a natural-language request such as "set up a KB for this folder".

3. **What happens in each phase.** Items marked ✋ are checkpoints where you approve.
   1. **Discovery:** read-only commands. The skill inspects the folder (names, sizes, formats, duplicates), git or
      OneDrive, managed policies, `uv`/Python and graphify: expected version and fork origin. If graphify is missing
      or the version differs, it tells you and installs or upgrades it before going on. Document contents are not
      opened in this phase.
   2. ✋ **Setup mode and interview:** the first question is the mode. **Autonomous** (recommended): the interview and
      the ✋ checkpoints below are resolved with the recommended options and reviewed in the closing summary.
      **Guided:** rounds of up to 4 questions, recommended default first: purpose and preset, language,
      versioning, engine copy in the workspace, confidentiality (what Claude may read in full), version precedence, note review period, graphify
      scope (code + `docs/` + `wiki/`, and which `raw/` documents to allow) and task skills.
   3. **Zettelkasten scaffold:** `kb.py scaffold` creates `raw/ wiki/ kb/ docs/`, `kb/config.yaml` and the
      `.gitignore` block. The skill then writes `README.md`, `CLAUDE.md`, `.claude/skills/kb/SKILL.md` and
      `kb/SETUP.md`. If you chose the engine copy, `kb.py vendor` writes it to `scripts/kb-engine/`. In an empty
      workspace it creates example notes and guides you through the first permanent note.
   4. ✋ **Ontology and preset** (when there are documents): the skill proposes a preset from `presets/`
      (`rfi-proposal`, `erp-rollout-program`) or the core only, and drafts the domain ontology, shapes, spreadsheet
      mappings, topic/fact rules and saved queries. You approve before the final build.
   5. **`KB update`:** unzip, PDF/DOCX/XLSX → Markdown conversion with page markers, deterministic extraction, image
      descriptions in subagents, SHACL validation and the generated wiki.
   6. **graphify build:** writes the root `.graphifyignore` and `raw/.graphifyignore`, runs `graphify update .`
      (structural, no LLM) and, when `docs/`, `wiki/` or authorized documents hold content, runs `/graphify .` in a
      subagent.
   7. ✋ **Task skills:** the skill proposes 2 to 4 (compliance matrix, RACI, proposal section, etc.) and generates
      only the ones you approve.
   8. **Close:** readiness checklist, decisions and authorizations recorded in `kb/SETUP.md`, a summary and
      suggestions. It also offers a baseline `eval`.

4. **Expected result**

   ```
   my-kb/
   ├── raw/                     official sources (+ converted .md beside the binaries) and raw/.graphifyignore
   ├── wiki/                    team notes (fleeting / literature / permanent)
   ├── docs/                    deliverables (never indexed)
   ├── kb/
   │   ├── config.yaml          engine_version, kb_setup_version, ontology, sources, graphify.version/source/scope
   │   ├── SETUP.md             decisions, authorizations, graphify version and source
   │   ├── IMPROVEMENTS.md      improvement backlog
   │   └── ontology/ mappings/ queries/ evals/ wiki/
   ├── .claude/skills/kb/       the workspace /kb skill (+ approved task skills)
   ├── scripts/kb-engine/       optional engine copy for people without kb-setup (ENGINE.json + text files)
   ├── CLAUDE.md                KB rules and coexistence rules with graphify
   ├── README.md                the workspace method
   ├── .graphifyignore          excludes kb/, .claude/ and scripts/kb-engine/ from graphify
   ├── .gitignore               kb-setup block (binaries, kb/.lock, graphify-out/)
   └── graphify-out/            graph.json, GRAPH_REPORT.md, graph.html (kept out of git)
   ```

5. **First uses**
   - Questions about the documents and notes: `/kb <question>`. Answers cite their source (`file, p.N` or
     `file, sheet X, row N`) and apply source precedence.
   - New documents: put them in `raw/` and run `/kb update`. Only what changed is processed, and graphify is updated
     too.
   - Allowing a `raw/` document into graphify: record the authorization in `kb/SETUP.md`, remove its line from
     `raw/.graphifyignore` and run `/kb update` (or `/kb-setup graphify`).
   - Exploration (themes, communities, paths between concepts) or code: `/graphify query "..."`.

## Other modes

| Mode | Purpose | Reference |
|---|---|---|
| `adopt` | migrate an existing KB (v1 layout or local engine) | [`references/migration.md`](references/migration.md) |
| `update` | incremental update of the KB and graphify after changes in `raw/` or `wiki/` | [`references/improvements.md`](references/improvements.md) |
| `upgrade` | kb-setup, the engine or the fork's graphify changed version: changelog, migration, rebuild and engine copy refresh | [`references/migration.md`](references/migration.md) |
| `graphify` | reinstall, check the version, change the scope or rebuild graphify | [`references/graphify.md`](references/graphify.md) |
| `eval` | tokens, time and quality: no KB × graphify only × KB + graphify | [`references/evals.md`](references/evals.md) |
| `status` | health of the engine, versions, engine copy, policies and graphify | [`SKILL.md`](SKILL.md) |
| `review` | analyze usage and apply approved improvements from the backlog | [`references/improvements.md`](references/improvements.md) |
| `preset` | extract a generic preset from a workspace | [`references/presets.md`](references/presets.md) |

## Versioning and updates

kb-setup carries two versions:

| Version | Where | When it goes up |
|---|---|---|
| kb-setup (the skill) | `VERSION`, history in [`CHANGELOG.md`](CHANGELOG.md) | every change in `kb-setup/` that should reach users |
| engine | `ENGINE_VERSION` in `scripts/kb.py` | only when the engine's behavior or compatibility changes |

`uv run ~/.claude/skills/kb-setup/scripts/kb.py --version` prints both. Each workspace records them in
`kb/config.yaml` (`kb_setup_version`, `engine_version`), and the engine warns when either one is behind the installed
version in major.minor.

**What Claude checks, and when**

- At the start of every `/kb-setup` mode it runs `kb.py check-update`, which reads the published `VERSION` (3 s
  timeout). If a newer version exists, Claude shows it with the changelog link and the update command, and offers to
  run it. Offline, behind a proxy or on any error, the check is skipped without comment.
- `/kb` never goes to the network. It only repeats the engine's version warnings and suggests `/kb-setup upgrade`.

**How to update**

- Clone + symlink: `git -C "$REPO" pull`. The symlink already points to the new version, and the editable graphify
  is updated as well. If the graphify version changed, run `graphify install --platform claude` to refresh the
  `/graphify` skill.
- `npx skills`: `npx skills update kb-setup -g`. The installed copy does not update itself, which is why
  `check-update` exists.
- Then open a new Claude Code session and run `/kb-setup upgrade` in each workspace. It compares `kb_setup_version`,
  `engine_version` and `graphify.version` in `kb/config.yaml`, shows the changelog, regenerates the workspace files,
  refreshes the engine copy and rebuilds what is needed, always with confirmation.

### Engine copy in the workspace

`/kb-setup init` (and `adopt`/`upgrade`) asks whether to copy the engine into the workspace. With the copy, someone
who opens the folder without kb-setup (a teammate on OneDrive, for example) can still consult the KB with
`uv run scripts/kb-engine/kb.py`; only uv and Claude Code are needed.

- **What goes in:** `kb.py`, `kb.py.lock`, `core_renames.py`, `VERSION`, the core ontology and shapes, the core queries
  and `prompts.md`, plus `ENGINE.json` with the versions, the source, the date and a sha256 per file. Text only: the
  dependencies stay in the uv cache, outside the workspace.
- **Precedence:** the central engine (`~/.claude/skills/kb-setup`) always wins; the copy is the fallback. When neither
  exists, Claude offers to install kb-setup with `npx skills`.
- **Limits:** the copy consults and updates the KB, but it cannot `scaffold` or refresh itself, and curation
  (`/kb-setup upgrade`, `eval`, `review`, skills, ontology) still needs kb-setup.
- **Who updates it:** the curator, through `/kb-setup upgrade`. `kb.py vendor --check` reports whether the copy is
  outdated and `kb.py vendor` refreshes it.
- **When to use it:** recommended for OneDrive/Teams workspaces and for read-only consumers; unnecessary for
  individual use with git.
- It lives in `scripts/kb-engine/`, never in `scripts/kb/`, which marks a v1 workspace for `adopt`.

## Confidentiality (summary)

- Reading document content (multiple pages, Grep in `raw/`, images, extraction, graphify) happens only in
  **subagents**, which return compact results with citations. Client text stays out of the main context.
- Full reading by an LLM (prose extraction, graphify over `raw/`, eval baseline) requires **per-document
  authorization**, recorded in `kb/SETUP.md`. For graphify, the authorization is reflected in `raw/.graphifyignore`.
- **Never** run with `GEMINI_API_KEY`/`GOOGLE_API_KEY` set: with them, graphify sends content to Google. Also
  forbidden: `graphify add`, `graphify extract` with an external backend, `--mcp`, `--neo4j`, `--watch`,
  `graphify hook install` and `graphify claude install` (it creates a hook).
- `graphify-out/` (at the root and any `*/graphify-out/` cache) stays out of git and out of the KB.

## Troubleshooting

- **No wheels for the default Python** (lesson L1): a dependency may have no wheel for the newest Python. The engine
  pins its dependencies through PEP 723 + `kb.py.lock`; if `uv run` fails to install, try
  `uv run --python 3.12 ~/.claude/skills/kb-setup/scripts/kb.py --version` and report the dependency.
- **Auto mode blocks `uvx ... python -c`** (inline code): run one simple command per call. To find where graphify was
  installed from, read `$(uv tool dir)/graphifyy/uv-receipt.toml` instead of running inline Python, or approve the
  command manually.
- **The graphify version differs from the one recorded in `kb/SETUP.md` / `kb/config.yaml`:** check
  `graphify --version` and the source in `uv-receipt.toml`. If it came from PyPI, reinstall from the fork
  (`uv tool install --force -e "$REPO"`). If the fork moved to a new version, run `/kb-setup upgrade` in the workspace
  before rebuilding the graph.
- **`SKILL.md.bak` copies in `~/.claude/skills/graphify`:** any graphify command refreshes outdated copies of its global
  skill and keeps the previous one as `.bak`. Set `GRAPHIFY_NO_AUTO_REFRESH=1` to turn this off.

## Developing the skill

```
kb-setup/
├── SKILL.md            command router and principles (what Claude reads)
├── VERSION             kb-setup version (semver), read by kb.py and by check-update
├── CHANGELOG.md        one entry per version: changes, engine version, migration steps
├── README.md           this file (ignored by Claude)
├── README.pt-BR.md     Portuguese version of this file (ignored by Claude)
├── scripts/            kb.py (engine) + kb.py.lock, eval_report.py, core_renames.py
├── assets/core/        kb: core ontology and SHACL shapes
├── assets/queries/     saved core SPARQL queries
├── assets/templates/   CLAUDE.md, SETUP.md, config.yaml, README.md, /kb skill, notes, prompts, graphifyignore
├── presets/            rfi-proposal, erp-rollout-program (ontology, shapes, mappings, queries, task skills)
├── references/         step-by-step guide for each mode (discovery, interview, graphify, migration, evals, lessons…)
└── evals/evals.json    test cases for the skill itself
```

- **Version bump:** every change in `kb-setup/` that should reach users raises `VERSION` and gets a `CHANGELOG.md`
  entry naming the engine version it ships and the migration steps for existing workspaces. `ENGINE_VERSION` in
  `scripts/kb.py` goes up only when the engine's behavior or compatibility changes. `check-update` reads `VERSION`
  from the `v8` branch on GitHub, so users see a bump only after it is pushed.
- **Skill evals:** `evals/evals.json` holds the prompt, expected output and assertions for each case. Run them with
  the `skill-creator` skill, which executes the cases in subagents and grades the assertions. The corpora the cases
  use (`corpus-rfp`, `fixture-initialized`) are not in this repository.
- **`eval` mode report:** `scripts/eval_report.py` aggregates `runs.jsonl`, `grades.json` and the volume JSONs:
  `uv run ~/.claude/skills/kb-setup/scripts/eval_report.py --dir <eval folder> --out kb/evals/<date>/report.md`.
- `kb-setup/` stays **outside the `graphifyy` package**: it is not in the wheel or in pytest's `testpaths`, and
  `tools/skillgen` does not generate it. Changes here do not affect the published graphify. If you ever open a PR
  upstream, branch from upstream, without this folder.

When you change this README, update [`README.pt-BR.md`](README.pt-BR.md) as well.
