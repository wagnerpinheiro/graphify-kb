# Preset `rfi-proposal`

Domain preset for workspaces that **answer a request from an issuing organization**: RFI, RFP, RFQ, tender / call for bids (pt: edital, licitação; es: licitación, pliego). The bidder's team gets a request package and must produce a proposal that:

- answers a **requirements / compliance matrix**;
- accepts or negotiates **contract terms**;
- covers **RACI / responsibility matrices**, a **transition (project → operations) checklist**, **quality / testing** and **information security** annexes;
- follows the issuer's **proposal template**.

The preset adds a domain ontology, SHACL shapes, spreadsheet mappings, deadline topics, quantitative fact rules, an attachments-map procedure, saved queries, 4 task-skill templates and an eval question set. Everything is generic. Nothing here names an institution, program, person, document id or client-specific number. All of that comes from the workspace at init.

## When to choose it

Choose it when discovery (`references/discovery.md`) finds most of these signals:

| Signal | Typical evidence (file names, `KB outline` headings, sheet headers) |
|---|---|
| A main request document with a numbered list of attachments | "Attachments" / "Annexes" section near the end; "Attachment N" references in the body |
| Requirement or compliance matrix spreadsheet | columns such as ID, category, workstream, requirement, eligibility/criticality, compliance, comments |
| RACI matrix spreadsheet(s) | an activity column followed by role columns filled with R/A/C/I |
| Transition / knowledge-transfer checklist | numbered items with applicable, status, phase and storage-location columns |
| Proposal template | a document whose headings are the sections the proposal must have |
| Contract terms | general / specific terms and conditions, draft contract |
| Tender notice | schedule (Q&A deadline, submission date), proposal validity, payment terms |

Do **not** choose it for contract management after signature, research corpora, or general project documentation. Use the core ontology there, or another preset.

## Contents

| File | Rendered to (workspace) | Notes |
|---|---|---|
| `ontology.ttl.tpl` | `kb/ontology/{{PREFIX}}.ttl` | Requirement (+ Functional, NonFunctional, Security, Quality), ComplianceItem, EvaluationCriterion, TransitionChecklistItem, ContractClause and ProposalTemplateSection (both ⊑ kb:Section), System/Module, matrix/checklist/RACI column properties |
| `shapes.ttl.tpl` | `kb/ontology/{{PREFIX}}-shapes.ttl` | source + location for domain classes; Requirement needs `kb:originalId` or `kb:excerpt`; ComplianceItem needs `kb:sheet` + `kb:row` |
| `mappings/compliance-matrix.yaml.tpl` | `kb/mappings/<file-slug>.yaml` | one or two sheets (requirements + proposal checklist), `type_by` for subclasses |
| `mappings/raci-matrix.yaml.tpl` | `kb/mappings/<file-slug>.yaml` (one per RACI file) | project RACI (phase, PMO phase, deliverable, order) and testing RACI (`fill_down`) variants |
| `mappings/transition-checklist.yaml.tpl` | `kb/mappings/<file-slug>.yaml` | header row far down, number column without header (`@B`) |
| `topics.yaml` | `topics:` block of `kb/config.yaml` | 7 deadline/condition topics, en/pt/es patterns |
| `facts.yaml` | `facts:` block of `kb/config.yaml` | 5 quantitative fact rules, en/pt/es; **test each before enabling** |
| `attachments.md` | `attachments:` block of `kb/config.yaml` | procedure (by subagent) + YAML skeleton |
| `queries/*.rq` | `kb/queries/` | requirements-by-topic, security-requirements, raci-by-role, gaps, deadlines |
| `task-skills/*/SKILL.md.tpl` | `.claude/skills/{{PROJECT}}-<name>/SKILL.md` | compliance-matrix, proposal-section, raci, transition-checklist |
| `eval-questions.md` | `kb/evals/questions.md` (instantiated) | 12 question types for `eval` |

The generic saved queries (conflicts, precedence, internal inconsistencies, note review) are not part of this preset. They belong to the core setup of every workspace.

Spreadsheets that are **templates without data rows** (for example, an effort-estimate model the bidder must fill) get a mapping with `sheets: []`. Their structure enters the graph as sections, and the text stays searchable in the converted `.md`.

## Extra interview questions (asked at init, on top of `references/interview.md`)

Ask only what discovery could not answer. Put the recommended default first and use rounds of ≤ 4 questions.

1. **Names for labels:** what are the display names of the issuing organization and the bid/program? These fill `{{CLIENT}}` and `{{PROGRAM}}` in ontology labels and skill descriptions. Default: use the names found in the main document's title page. Offer a neutral alternative ("the client", "the program") if the user prefers no names in generated files.
2. **Project prefix for task skills:** default is a short slug of the program (`{{PROJECT}}`, e.g. `acme-rfp`). Check that it does not collide with installed skills.
3. **Domain ontology prefix:** default `prop`. It must be a valid Turtle prefix and must not be `kb` or `id`.
4. **Main document(s):** which document is the request itself (its attachment list is the official one)? Is there a separate tender notice with its own list?
5. **Precedence between request documents:** by default the most recent date wins, then version within a family. Ask whether a document is contractually prevalent (e.g. the notice prevails over the technical spec). If so, record it as a wiki note with `overrides:` or document it in `kb/SETUP.md`.
6. **Answer artifacts:** which spreadsheets will the bidder fill (compliance matrix, estimates)? Drafts always go to `docs/`. The originals in `raw/` are never edited.
7. **Languages:** what language are the documents in? What language must the proposal be written in? These can differ. The proposal language drives the task skills' output, and chat answers follow the user.
8. **Our side vs. their side in the RACI:** which role columns represent the bidder? This is used by the raci task skill to say "what we must staff".
9. **Task skills:** which of the 4 templates to generate (default: all whose source material exists).
10. **Confidentiality:** which documents the LLM may read in full (prose extraction, eval answer keys, graphify). Record this per document in `kb/SETUP.md`.

## Placeholders

Two kinds of placeholder exist, and kb-setup must never confuse them:

- **UPPERCASE `{{NAME}}` are init-time placeholders.** kb-setup fills them when rendering. Optional blocks that are commented out (a second sheet, a testing-RACI variant, a second answer round) must be either filled and uncommented, or deleted. After rendering, `grep -n '{{[A-Z_]*}}'` over the rendered files must return nothing.
- **lowercase `{{name}}` in `.rq` files are runtime query parameters** (`KB query <name> --param name=value`). The engine treats every `{{word}}` left in a query as a required parameter, so kb-setup must leave these untouched and must not leave UPPERCASE ones behind.

Rendering is plain string replacement of `{{NAME}}`. Mapping templates use `"{{{COL_X}}}"` in `iri`/`label`: replacing `{{COL_X}}` leaves the engine's single-brace column reference (`{ID}`).

| Placeholder | Where | Filled from |
|---|---|---|
| `{{PREFIX}}`, `{{NAMESPACE}}` | ontology, shapes, mappings, queries, skills | interview (prefix). The namespace comes from `kb/config.yaml` `ontology.namespace` written by `KB scaffold` |
| `{{CLIENT}}`, `{{PROGRAM}}` | ontology labels/comments, skill descriptions | interview Q1 |
| `{{PROJECT}}` | task-skill names | interview Q2 |
| `{{DATE}}`, `{{ENGINE_VERSION}}`, `{{KB_SETUP_VERSION}}` | ontology, skill headers | today; `KB --version` (engine and kb-setup versions) |
| `{{SOURCE_COMPLIANCE_MATRIX}}`, `{{SOURCE_RACI_MATRIX}}`, `{{SOURCE_TRANSITION_CHECKLIST}}` | mappings | discovery: workspace-relative path of the `.xlsx` |
| `{{SHEET_*}}`, `{{HEADER_ROW_*}}` | mappings | `KB outline <file>`: sheet names and header rows |
| `{{COL_*}}` | mappings | `KB outline <file>`: exact header text (or `@<Letter>` for header-less columns) |
| `{{VAL_*}}` | mapping `type_by` | a subagent lists the distinct values of the category/workstream columns |
| `{{COMPLIANCE_MATRIX_FILE}}`, `{{PROPOSAL_TEMPLATE_FILE}}`, `{{TRANSITION_CHECKLIST_FILE}}`, `{{RACI_FILES}}` | task skills | discovery (workspace-relative paths, for the user-facing text) |
| `{{BIDDER_ROLES}}` | raci skill | interview Q8 |
| `{{PROPOSAL_LANGUAGE}}` | proposal-section and compliance-matrix skills | interview Q7 |

Suggested `section_class` entries for `kb/config.yaml`. These are globs over the path or file name. The first match wins.

```yaml
section_class:
  "{{CONTRACT_TERMS_GLOB}}": {{PREFIX}}:ContractClause            # e.g. "*Terms*Conditions*", "*Contract*"
  "{{PROPOSAL_TEMPLATE_GLOB}}": {{PREFIX}}:ProposalTemplateSection # e.g. "*Proposal*Template*"
```

## How kb-setup applies the preset (init, step 6.3–6.5)

1. Read this file, then `KB outline` (headings and spreadsheet headers only, no full text) to fill the structural placeholders.
2. Render the ontology and shapes. Remove the classes and properties the material does not need, and add the ones it shows. Never redeclare core `kb:` terms.
3. Render one mapping per spreadsheet. Run `KB extract-det <file> -v` on the draft to check rows per sheet. **Tell the user at that moment** that this is a regenerable test before approval.
4. Subagents, on authorized documents only:
   - test every `topics.yaml` pattern and every `facts.yaml` rule against the converted `.md`;
   - build the attachments map (`attachments.md`).

   They return counts, pages and normalized values, never client excerpts. Keep only the rules that fire and produce comparable values. Add the workspace-specific ones the subagents propose.
5. Copy the queries. Adapt the "mandatory" regex in `gaps.rq` and the security vocabulary in `security-requirements.rq` to the values found.
6. **Checkpoint (the user's):** present ontology, shapes, mappings, topics, facts and the attachments map in one compact summary: classes, properties per mapping, rule list with hit counts. Mass extraction (`KB update --force`), `validate` and `wiki` run only after approval. If the user changes anything, re-render and re-test.
7. Task skills: propose the templates whose source material exists. Generate only the approved ones, with a header that records the kb-setup version and preset. Instantiate `eval-questions.md` only when the user runs `eval`.

## Engine caveats (2.0.0) the preset depends on

These parts of the engine are still tuned to Portuguese text. Test them on the workspace and log what bites in `kb/IMPROVEMENTS.md`:

- **Attachment references:** "Attachment N" detection in the body text recognizes only the Portuguese word for attachment. English "Attachment/Annex/Appendix N" and the Spanish forms are not detected yet, so the attachments map has no effect on such documents.
- **Durations in deadline sentences:** only Portuguese units (days/hours/months/weeks in Portuguese) are recognized. Because of that, topics fire in English/Spanish text only when the sentence has an explicit date.
- **Fact normalization:**
  - `count` splits lists on commas and the Portuguese conjunctions only;
  - `months`/`number` know Portuguese number words and units only.

  See the comments in `facts.yaml` for the cases confirmed on synthetic sentences.
- **RACI:** the engine accepts only the letters R, A, C, I, and the core shape enforces this. A RASCI "S" needs an engine or shape change.
- **System/Module:** the v1→v2 rename map lists them as core terms, but the core ontology does not declare them. This preset declares them in the domain namespace.
