# Preset `erp-rollout-program`

Domain preset for workspaces that track a **multi-country / multi-business-line ERP template rollout program**
(a central team runs kickoffs and weekly/periodic status reports as a new ERP template is deployed to one
country or business unit at a time; local teams raise gaps against the global template through a governance
body). Extracted from a real engagement's kickoff decks and weekly status report, generalized: nothing here
names an institution, program, person, document id, legacy/target system name or client-specific number. All
of that comes from the workspace at init.

The preset adds a domain ontology, SHACL shapes, deadline/condition topics, quantitative fact rules and 3 saved
queries. It does **not** include spreadsheet mappings, task skills or an eval question set (the source
engagement's raw/ was all PDF kickoff/status decks, no spreadsheets, and neither task skills nor an eval had
been run yet when this preset was extracted) — add those later with `/kb-setup skills` / `/kb-setup eval` if the
adopting workspace has spreadsheets or wants task skills.

## When to choose it

Choose it when discovery (`references/discovery.md`) finds most of these signals:

| Signal | Typical evidence (file names, `KB outline` headings) |
|---|---|
| Kickoff / town-hall deck | "Program scope", "Who is who", "Governance", "Methodology" sections |
| Recurring status report | a weekly/periodic PDF or deck with GAP counts, PBI/backlog counts, risk tables |
| Sub-program structure | the program is explicitly split into sub-programs (e.g. back office / front office / by business line) |
| Template vs. local gap process | wording like "Design Authority Board", "fit or gap", "Core Model", "lock the scope" |
| Legacy system decommission | a named legacy system (ERP, AS/400-class system) being retired on a stated date |
| Backlog tracked as PBIs/features | counts of PBIs, features, "Ready for Refinement", wave-based delivery |

Do **not** choose it for a single-country/single-system implementation with no sub-program structure, for
contract/RFI response work (use `rfi-proposal`), or for general project documentation. Use the core ontology
there.

## Contents

| File | Rendered to (workspace) | Notes |
|---|---|---|
| `ontology.ttl.tpl` | `kb/ontology/{{PREFIX}}.ttl` | 17 classes: SubProgram, ProgramPhase (+ DesignSubPhase), GovernanceBody, StakeholderRole (⊑ kb:Role), Vendor, FunctionalDomain (⊑ kb:Process), ApplicationSystem (⊑ kb:System) + SatelliteApplication, Platform, LegalEntity, TestCycle, Workshop (⊑ kb:Activity), Feature + PBI (⊑ kb:Deliverable), GAP, Risk, ChangeImpact; properties `inSubProgram`, `partOfFeature`, `status`, `stream` |
| `shapes.ttl.tpl` | `kb/ontology/{{PREFIX}}-shapes.ttl` | source + location required on every domain class (same pattern as the core StatementShape) |
| `topics.yaml` | `topics:` block of `kb/config.yaml` | 7 deadline/condition topics (legacy decommission date, go-live big bang, lock-the-scope, rollout model, full program scope, go-live strategy, cutover) |
| `facts.yaml` | `facts:` block of `kb/config.yaml` | 6 quantitative fact rules (business case value, sub-program count, app-rationalization target, sprint duration, satellite app count, legacy RPA count); **test each before enabling**, see lessons in the file |
| `queries/*.rq` | `kb/queries/` | methodology-phases, roles-by-subprogram, gaps-by-status |

The generic saved queries (conflicts, precedence, internal inconsistencies, note review, deadlines) are not part
of this preset. They belong to the core setup of every workspace.

## Extra interview questions (asked at init, on top of `references/interview.md`)

1. **Names for labels:** display name of the organization running the program and of the program itself. Fill
   `{{CLIENT}}` / `{{PROGRAM}}`. Default: use the names found in the kickoff deck's title page. Offer a neutral
   alternative ("the organization", "the program") if the user prefers no names in generated files.
2. **Domain ontology prefix:** default `erp`. Must be a valid Turtle prefix, not `kb` or `id`.
3. **Sub-program list:** what are this program's actual sub-programs? Used to seed example `{{PREFIX}}:SubProgram`
   instances and to sanity-check the `subprograms-count` fact.
4. **Legacy system(s) being decommissioned:** names (replaces the source engagement's "ECC"/"AS/400" example in
   `legacy-decommission-date`).
5. **Methodology phase names:** does the program use its own named lifecycle/phase vocabulary (the source
   engagement had a branded methodology with named design sub-phases)? Rename `{{PREFIX}}:ProgramPhase` /
   `{{PREFIX}}:DesignSubPhase` instance labels accordingly, keep the classes.
6. **Role archetype names:** does the program use its own stakeholder-role vocabulary (the source engagement had
   a technology/analytics role, a process-and-systems-owner role per function, an SME role, a key-user role)?
   Rename `{{PREFIX}}:StakeholderRole` instance labels accordingly.
7. **Confidentiality:** which documents the LLM may read in full (ontology mining, prose extraction, eval
   answer keys). Record per document in `kb/SETUP.md` — entity population for PBI/GAP/Risk/Workshop/ChangeImpact
   requires this, the topics/facts regex rules do not (they run deterministically over already-converted text).

## Placeholders

Same two kinds as every kb-setup preset — see `references/presets.md` and the `rfi-proposal` preset.md for the
full rule. In short: UPPERCASE `{{NAME}}` are init-time placeholders kb-setup fills when rendering (after
rendering, `grep -n '{{[A-Z_]*}}'` over the rendered files must return nothing); lowercase `{{name}}` left in a
`.rq` file is a runtime `KB query <name> --param name=value` parameter and must be left untouched.

| Placeholder | Where | Filled from |
|---|---|---|
| `{{PREFIX}}`, `{{NAMESPACE}}` | ontology, shapes, queries | interview (prefix). Namespace comes from `kb/config.yaml` `ontology.namespace` written by `KB scaffold` |
| `{{CLIENT}}`, `{{PROGRAM}}` | ontology labels/comments | interview Q1 |
| `{{DATE}}` | ontology header | today |

## How kb-setup applies the preset (init, step 6.3–6.5)

1. Read this file, then `KB outline` (headings only — on a dense slide deck the heading-size heuristic can still
   pull in body text; treat `outline` output as potentially sensitive on this document type and keep it to a
   quick structural scan, not a substitute for the subagent step below).
2. Render the ontology and shapes with `{{PREFIX}}`/`{{NAMESPACE}}`/`{{CLIENT}}`/`{{PROGRAM}}`/`{{DATE}}`. Remove
   classes the material does not need; add ones it shows (e.g. a new backlog-item kind). Never redeclare core
   `kb:` terms.
3. A subagent, on authorized documents only, mines the material to confirm/adjust the class list and tests every
   `topics.yaml` pattern and `facts.yaml` rule against the converted `.md`, reporting hit counts and sample
   values per document/page — never client excerpts in the main context.
4. Copy the 3 queries, substituting `{{PREFIX}}`/`{{NAMESPACE}}`.
5. **Checkpoint (the user's):** present ontology, shapes, topics and facts (with hit counts) in one compact
   summary. Run `KB update --force`, `validate` and `wiki` only after approval.
6. **Verify, don't just trust the proposal:** after `KB update --force`, query the actual extracted `kb:Fact`
   values (`KB query` with a small inline SPARQL, or `KB show id:topic/<name>`) before declaring the checkpoint
   done. The source engagement's first pass had 3 facts quietly producing wrong/noisy values that only showed up
   once the real extracted values were inspected (see the lessons in `facts.yaml`) — a subagent's regex test
   against raw text is not a substitute for checking what the engine's own windowed extraction actually stored.

## Engine caveats (2.0.0) confirmed on the source engagement

- **`KB outline` heading detection** (`pdf.heading_size_ratio`, default 1.15) can classify most of a dense slide
  deck's body text as "headings" when many text boxes share one font size, exposing more than titles in the
  main context. Treat `outline` output from this document type as needing the same care as full document text.
- **`facts:` `value` regex uses only capture group 1** (`fact_value(vm.group(1), fc)` in `kb.py`) — a rule
  written to capture a range ("from X to Y") silently keeps only X; anchor on the one number you need.
- **Conflict-copy false positive:** `CONFLICT_RE` matches a trailing `-PC` (meant for `-DESKTOP`/`-MBP`-style
  OneDrive sync suffixes) case-insensitively, so a `facts:`/`topics:` key ending in `-pct` (e.g. a "percent"
  abbreviation) is flagged as a fake "OneDrive conflict copy". Avoid `-pct`; use `-percent`.
- **Topics need a date/duration in the same sentence as the keyword.** Dense kickoff-deck bullets often state a
  date-bearing fact without a full prose sentence around it; a topic can legitimately have zero hits on kickoff
  decks and only start firing once status reports use fuller sentences. Don't treat zero hits alone as proof the
  pattern is wrong — check whether the source text has a matching sentence shape at all.
