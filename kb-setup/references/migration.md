# adopt (migrate an existing KB) and upgrade (engine versions)

## adopt: v1 workspace → engine 2.x
A v1 workspace has a local `scripts/kb/kb.py`, Portuguese core terms under the domain prefix (e.g. `rfi:definidoEm`), Portuguese config keys (`temas`, `fatos`, `anexos`) and no `engine_version`.

1. **Copy first.** `rsync -a --exclude .git --exclude graphify-out --exclude 'raw/graphify-out' <ws>/ <scratch>/adopt-test/` and run every step there before touching the real workspace.
2. `KB migrate --title "<title>" --language <lang> --dry-run` (from the copy) → shows the detected prefix/namespace and the files to rewrite. Keep the existing domain prefix and instance namespace so IRIs stay stable.
3. Apply on the copy: `KB migrate --title ... --language ...`, then `KB update`, `KB validate`, and compare key answers before/after with the old engine (`uv run scripts/kb/kb.py ask ...` on the original vs `KB ask ...` on the copy): precedence winners, RACI, topics/facts, attachments, counts per class (`KB query "SELECT ?c (COUNT(DISTINCT ?s) AS ?n) WHERE { GRAPH ?g { ?s a ?c } } GROUP BY ?c"`).
4. Domain ontology cleanup: remove from `kb/ontology/<prefix>.ttl` declarations of terms now in the core (`kb:Document`, `kb:Section`, `kb:definedIn`, …) and duplicated shapes (core shapes already cover statement source/location, notes, RACI, milestones, terms). Validate again.
5. Regenerate from templates: `.claude/skills/kb/SKILL.md`, `CLAUDE.md` KB section (keep user-written sections), README KB section. Saved queries keep their names unless the user wants English names (then also update references in skills/README).
5b. graphify (required): install or verify it from the graphify-kb fork (`graphify.md`), add the `graphify:` block from `assets/templates/config.yaml` to `kb/config.yaml` if missing, write the root `.graphifyignore` and `raw/.graphifyignore` (keep any existing authorizations), remove an old project-scoped `.claude/skills/graphify/` copy, and build the graph in a subagent.
6. Show the user the results of the copy, get confirmation, then repeat 2–5b on the real workspace (lock first). Finally, with confirmation, delete the local engine (`scripts/kb/`) and its lock file, and record the migration in `kb/SETUP.md`.
7. Readiness checklist (`lessons.md`).

Rename map used by `migrate`: `scripts/core_renames.py` (classes, properties, config keys, fact normalize values). Instance path segments also change (`secao/`→`section/`, `condicao/`→`topic/`, `marco/`→`milestone/`, `termo/`→`term/`, `nota/`→`note/`, `papel/`→`role/`, `pessoa/`→`person/`); notes that reference `id:condicao/...` in `overrides:` are rewritten.

## upgrade: engine version changes
- `KB --version` vs `engine_version` in `kb/config.yaml`; the engine warns when major.minor differ.
- Read the changelog below for every version between the two, apply the listed migration steps (config edits, ontology changes), then `KB update --force`, `KB validate`, spot-check answers, set `engine_version`.
- Never upgrade automatically; show the changelog and ask.

## Changelog
### graphify required, kb-setup versioned in the graphify-kb fork (2026-10-04, engine still 2.0.0)
- kb-setup now lives in `https://github.com/wagnerpinheiro/graphify-kb` (`kb-setup/`), installed as a symlink `~/.claude/skills/kb-setup` → `<fork>/kb-setup`.
- graphify is required: install it as a uv tool from the fork (expected 0.9.76, no longer `graphifyy==0.9.56` from PyPI); scope code + docs/ + wiki/; init/adopt/update always build or update the graph.
- Migration for existing workspaces: add the `graphify:` block to `kb/config.yaml`, reinstall graphify from the fork, remove any project-scoped `.claude/skills/graphify/`, rebuild `graphify-out/`, and record version/source in `kb/SETUP.md`. Regenerate the `/kb` skill and the CLAUDE.md KB section from the templates.

### 2.0.0 (2026-10-04)
- Central engine in `~/.claude/skills/kb-setup/scripts/kb.py`; root discovered from the current directory (`--root`, `KB_ROOT`).
- Core ontology `kb:` in English shipped with the engine; domain prefix/namespace/instances from `kb/config.yaml` `ontology:`.
- English config keys (`topics`, `facts`, `attachments`; v1 keys still accepted when reading).
- Zettelkasten: note `type`, `source`, `[[links]]` (`kb:linksTo`), `new-note` names `YYYY-MM-DD-slug.md`; multilingual note conventions (en/pt/es).
- Quantitative `facts` with window search and normalization; `internal-inconsistencies` query; parametrized queries (`--param`).
- `scaffold`, `migrate`, `volume`, `log-cost`/`costs`, read-only mode (`--read-only` / `KB_READONLY=1`), engine version check.
- Migration: run `KB migrate` (see adopt).
