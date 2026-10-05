# kb-setup changelog

The meta skill version lives in `VERSION`; the engine version is `ENGINE_VERSION` in `scripts/kb.py`. Workspaces
record both in `kb/config.yaml` (`kb_setup_version`, `engine_version`). `/kb-setup upgrade` reads this file for every
version between the workspace's and the installed one and applies the listed migration steps, always with
confirmation.

## 2.1.0 (2026-10-05) · engine 2.1.0
- **Optional engine copy in the workspace** (`scripts/kb-engine/`): `KB vendor` copies `kb.py`, `kb.py.lock`,
  `core_renames.py`, `VERSION`, the core ontology/shapes, the core queries and `prompts.md`, and writes
  `ENGINE.json` (versions, source, date, sha256 per file). People without kb-setup can consult the KB with
  `uv run scripts/kb-engine/kb.py`. The central engine always takes precedence; the copy is the fallback. A copy
  cannot `scaffold` and cannot `vendor` itself. `scripts/kb/` remains the v1 marker for `adopt`.
- `KB vendor --check`: `absent`, `up to date` or `outdated (x → y)` against the running engine; writes nothing.
  `KB status` shows where the engine runs from, the kb-setup version and the copy state.
- `KB check-update`: compares `VERSION` with the published one (3 s timeout, `KB_SETUP_UPDATE_URL` overrides the URL)
  and prints the right update command (`git -C <repo> pull` for a clone, `npx skills update kb-setup -g` otherwise).
  Network failures print `update check skipped: …` and exit 0. `/kb-setup` runs it at the start of every mode; `/kb`
  never touches the network.
- `kb_setup_version` in `kb/config.yaml`; the engine warns when it is older (major.minor) than the installed skill.
  `KB --version` prints `kb.py engine X · kb-setup Y (central|workspace copy)`.
- Workspace templates: the `/kb` skill, task skills and CLAUDE.md resolve the engine central → copy → offer to install
  kb-setup with `npx skills add wagnerpinheiro/graphify-kb --skill kb-setup -g -a claude-code`. The workspace README
  gets a "Requirements and installation" section per OS (uv, Claude Code, Node.js, kb-setup, graphify). Generated
  files are stamped with the kb-setup version instead of the engine version.
- init asks first: autonomous (recommended defaults, checkpoints auto-approved and listed at the end) or guided
  (interview rounds and approval checkpoints). `kb/SETUP.md` records `Setup mode:` and marks assumed decisions.
- Interview Round 3 asks whether to copy the engine into the workspace (recommended for OneDrive/both or read-only
  consumers). The old R3.4 (note conventions) is folded into R2.4.
- **Migration from 2.0.x:**
  1. back up `kb/config.yaml`, then add `kb_setup_version: "2.1.0"` below `engine_version` and set
     `engine_version: "2.1.0"`;
  2. regenerate from the templates (keep user sections and `<!-- manual -->` blocks): the CLAUDE.md KB section,
     `.claude/skills/kb/SKILL.md`, approved task skills and the README "Requirements and installation" section;
     add the Engine line to `kb/SETUP.md` → Integrations;
  3. ask the engine-copy question (interview R3.3); if yes, `KB vendor` and add `scripts/kb-engine/` to the root
     `.graphifyignore` (vendor does it when the file exists);
  4. `KB update --force`, `KB validate`, record the upgrade in `kb/SETUP.md` → History.

## 2.0.1 (2026-10-04) · engine 2.0.0
graphify required, kb-setup versioned in the graphify-kb fork.
- kb-setup now lives in `https://github.com/wagnerpinheiro/graphify-kb` (`kb-setup/`), installed as a symlink
  `~/.claude/skills/kb-setup` → `<fork>/kb-setup`.
- graphify is required: install it as a uv tool from the fork (expected 0.9.76, no longer `graphifyy==0.9.56` from
  PyPI); scope code + docs/ + wiki/; init/adopt/update always build or update the graph.
- **Migration:** add the `graphify:` block to `kb/config.yaml`, reinstall graphify from the fork, remove any
  project-scoped `.claude/skills/graphify/`, rebuild `graphify-out/`, and record version/source in `kb/SETUP.md`.
  Regenerate the `/kb` skill and the CLAUDE.md KB section from the templates.

## 2.0.0 (2026-10-04) · engine 2.0.0
- Central engine in `~/.claude/skills/kb-setup/scripts/kb.py`; root discovered from the current directory (`--root`,
  `KB_ROOT`).
- Core ontology `kb:` in English shipped with the engine; domain prefix/namespace/instances from `kb/config.yaml`
  `ontology:`.
- English config keys (`topics`, `facts`, `attachments`; v1 keys still accepted when reading).
- Zettelkasten: note `type`, `source`, `[[links]]` (`kb:linksTo`), `new-note` names `YYYY-MM-DD-slug.md`;
  multilingual note conventions (en/pt/es).
- Quantitative `facts` with window search and normalization; `internal-inconsistencies` query; parametrized queries
  (`--param`).
- `scaffold`, `migrate`, `volume`, `log-cost`/`costs`, read-only mode (`--read-only` / `KB_READONLY=1`), engine
  version check.
- **Migration:** run `KB migrate` (see adopt in `references/migration.md`).
