# kb-setup changelog

The meta skill version lives in `VERSION`; the engine version is `ENGINE_VERSION` in `scripts/kb.py`. Workspaces
record both in `kb/config.yaml` (`kb_setup_version`, `engine_version`). `/kb-setup upgrade` reads this file for every
version between the workspace's and the installed one and applies the listed migration steps, always with
confirmation.

## 2.2.0 (2026-10-05) · engine 2.2.0
File inventory and `KB audit`, so consumers on OneDrive/Teams can tell whether their copy is complete.
- **`kb/inventory.json`** (OneDrive/both): path (NFC), size and sha256 of every file a consumer needs: the whole
  workspace, hidden files included (`.claude/skills/`, `.graphifyignore`), except `.git/`, `docs/`, the subfolders of
  `graphify-out/` (only its top-level files), the inventory itself, the curator lock, conflict copies and OS/Office
  junk. Configurable in `kb/config.yaml` → `inventory.exclude`. Written at the end of `update`/`ingest`, by `unlock`
  (covers graphify, which runs after update) and by the new `KB inventory`. Unchanged files keep the file and its
  `generated` date as they were. Hashes are reused from a per-machine cache outside the workspace
  (`~/.cache/kb-setup/`, keyed by size + mtime_ns); machines are compared by content only. With git,
  `KB inventory` explains that git already does this job (`--force` writes it anyway).
- **`WILL NOT SYNC (OneDrive): <path> — <reason>`** when the inventory is written and in `KB status`: invalid
  characters (`" * : < > ? \ |`), reserved names (`CON`, `PRN`, `AUX`, `NUL`, `COM0-9`, `LPT0-9`, `.lock`,
  `desktop.ini`), `_vti_`, `~$` prefix, leading/trailing space, trailing dot, local paths over 400 characters, names
  that differ only in case, symbolic links. `KB status` also warns `NO INVENTORY` on OneDrive/both.
- **`KB audit [path] [--quick] [--json]`**, read-only (works with `--read-only` and in `scripts/kb-engine/`): shows who
  generated the inventory, when and with which version, then lists MISSING (with the probable OneDrive cause),
  DIFFERENT (sha256, or size with `--quick`) and EXTRA files, and `audit: N files ok · M missing · D different · E extra`.
  Exit 0 when complete, 1 on MISSING/DIFFERENT (EXTRA only warns), 2 without an inventory. The full check downloads
  online-only files; `--quick` checks existence and size only.
- **Curator lock renamed** to `kb/curator-lock.json`: `kb/.lock` is an invalid OneDrive name, so it never synced and
  other curators never saw it. The engine still honors an old `kb/.lock`, and `unlock` removes both. The `.gitignore`
  block lists both names.
- Source ids longer than 200 characters are shortened with a hash suffix (very deep paths made
  `kb/manifest/<id>.json` exceed the 255-byte file name limit and crashed `update`). Shorter ids do not change.
- Skill: init (close), adopt and upgrade end with `KB inventory` on OneDrive/both; `status` runs `KB audit --quick`.
  The `/kb` skill runs `KB audit --quick` once per session for OneDrive readers before the first answer and warns
  when answers may be incomplete. CLAUDE.md, the workspace README and `references/onedrive-teams-sync.md`
  (checklist step 14b) mention `KB audit`.
- **Migration from 2.1.x:**
  1. set `engine_version: "2.2.0"` and `kb_setup_version: "2.2.0"` in `kb/config.yaml`;
  2. git/both: add `kb/curator-lock.json` to the `# --- kb-setup ---` block of `.gitignore`, beside `kb/.lock`;
  3. regenerate from the templates (keep user sections and `<!-- manual -->` blocks): `.claude/skills/kb/SKILL.md`,
     the CLAUDE.md KB section and the README "Using it" section;
  4. refresh the engine copy if there is one (`KB vendor`);
  5. OneDrive/both: `KB update` (or `KB inventory`) writes `kb/inventory.json`; fix any `WILL NOT SYNC` file, then
     ask each teammate to run `KB audit`.

## 2.1.1 (2026-10-05) · engine 2.1.0
Autonomous setup mode for init. Skill files only; the engine is unchanged.
- init asks first: **autonomous** (recommended) or **guided**. Autonomous takes the recommended default at every
  decision (`references/interview.md` → "Autonomous mode"), approves the ontology/mappings/rules and task skills
  checkpoints itself, records them in `kb/SETUP.md` and lists them in the closing summary. It never assumes
  per-document LLM authorizations, policy/`uv`/API-key blockers, manual OneDrive/Teams steps or overwriting user
  content. Guided keeps the interview rounds and approval checkpoints. Adopt is unchanged.
- `kb/SETUP.md` template: `Setup mode: autonomous | guided`; assumed decisions are marked "(default — autonomous)".
- **Migration from 2.1.0:** set `kb_setup_version: "2.1.1"` in `kb/config.yaml` and add
  `Setup mode: guided` below the "Created by…" line of `kb/SETUP.md`. Nothing else to regenerate.

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
