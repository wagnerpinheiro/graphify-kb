# adopt (migrate an existing KB) and upgrade (kb-setup and engine versions)

## adopt: v1 workspace → engine 2.x
A v1 workspace has a local `scripts/kb/kb.py`, Portuguese core terms under the domain prefix (e.g. `rfi:definidoEm`), Portuguese config keys (`temas`, `fatos`, `anexos`) and no `engine_version`.

1. **Copy first.** `rsync -a --exclude .git --exclude graphify-out --exclude 'raw/graphify-out' <ws>/ <scratch>/adopt-test/` and run every step there before touching the real workspace.
2. `KB migrate --title "<title>" --language <lang> --dry-run` (from the copy) → shows the detected prefix/namespace and the files to rewrite. Keep the existing domain prefix and instance namespace so IRIs stay stable.
3. Apply on the copy: `KB migrate --title ... --language ...`, then `KB update`, `KB validate`, and compare key answers before/after with the old engine (`uv run scripts/kb/kb.py ask ...` on the original vs `KB ask ...` on the copy): precedence winners, RACI, topics/facts, attachments, counts per class (`KB query "SELECT ?c (COUNT(DISTINCT ?s) AS ?n) WHERE { GRAPH ?g { ?s a ?c } } GROUP BY ?c"`).
4. Domain ontology cleanup: remove from `kb/ontology/<prefix>.ttl` declarations of terms now in the core (`kb:Document`, `kb:Section`, `kb:definedIn`, …) and duplicated shapes (core shapes already cover statement source/location, notes, RACI, milestones, terms). Validate again.
5. Regenerate from templates: `.claude/skills/kb/SKILL.md`, `CLAUDE.md` KB section (keep user-written sections), README KB section. Saved queries keep their names unless the user wants English names (then also update references in skills/README).
5b. graphify (required): install or verify it from the graphify-kb fork (`graphify.md`), add the `graphify:` block from `assets/templates/config.yaml` to `kb/config.yaml` if missing, write the root `.graphifyignore` and `raw/.graphifyignore` (keep any existing authorizations), remove an old project-scoped `.claude/skills/graphify/` copy, and build the graph in a subagent.
5c. Engine copy (adopt question in `interview.md`): if the user wants it, `KB vendor` writes `scripts/kb-engine/` with `ENGINE.json`. Do not confuse it with the v1 local engine `scripts/kb/`, which step 6 deletes: the v1 folder has `kb.py` and no `ENGINE.json`.
6. Show the user the results of the copy, get confirmation, then repeat 2–5c on the real workspace (lock first). Finally, with confirmation, delete the local engine (`scripts/kb/`) and its lock file, and record the migration in `kb/SETUP.md`.
7. Readiness checklist (`lessons.md`).

Rename map used by `migrate`: `scripts/core_renames.py` (classes, properties, config keys, fact normalize values). Instance path segments also change (`secao/`→`section/`, `condicao/`→`topic/`, `marco/`→`milestone/`, `termo/`→`term/`, `nota/`→`note/`, `papel/`→`role/`, `pessoa/`→`person/`); notes that reference `id:condicao/...` in `overrides:` are rewritten.

## upgrade: kb-setup or engine version changes
- Two versions, compared separately: `kb_setup_version` (the skill, `VERSION`; it generated README, CLAUDE.md, the
  `/kb` skill and task skills) and `engine_version` (`ENGINE_VERSION` in `kb.py`; config and ontology compatibility).
  `KB --version` prints both; the engine warns when either is behind in major.minor. A workspace without
  `kb_setup_version` predates 2.1.0.
- Read `CHANGELOG.md` (skill root) for every version between the workspace's and the installed one, apply the listed
  migration steps (config edits, ontology changes, template regeneration), then `KB update --force`, `KB validate`,
  spot-check answers, and set `engine_version` and `kb_setup_version`.
- When `kb_setup_version` changed, regenerate the workspace files from `assets/templates/` (keep user sections and
  `<!-- manual -->` blocks; show a diff first).
- Engine copy: if `scripts/kb-engine/ENGINE.json` exists, run `KB vendor --check`; when it is `outdated`, refresh it
  with `KB vendor` (from the central engine). If there is no copy, ask the engine-copy question (interview R3.3).
- OneDrive/both: `KB inventory` is the last engine command of the upgrade (after graphify and `KB vendor`), so
  consumers can `KB audit` their copy.
- Never upgrade automatically; show the changelog and ask.

## Changelog
Moved to `CHANGELOG.md` at the skill root (one entry per kb-setup version, each naming the engine version it ships).
