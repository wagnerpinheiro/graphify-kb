# Interview (init / adopt)

Ask only what discovery could not answer. Use AskUserQuestion in rounds of up to 4 questions, recommended option first with "(Recommended)", short descriptions of the consequence of each option. Accept free-text answers ("Other") and follow what they actually say — users often refine an option (e.g. "generic presets, but without institution names"). Keep asking until there are no doubts that change what you build; record every answer and its implication in `kb/SETUP.md` (table: # | question | options | answer | implication).

## Round 0 — setup mode (init only, always the first question)
One AskUserQuestion, two options:
- **Autonomous (Recommended):** Claude follows the predefined flow without asking and takes the recommended option at every decision, including the checkpoints (ontology, mappings, topics/facts rules, task skills). Defaults are conservative, everything is recorded in `kb/SETUP.md` and listed in the closing summary for review.
- **Answer the questions:** guided mode — Rounds 1–4 below and the approval checkpoints.

Skip Rounds 1–4 in autonomous mode and use "Autonomous mode" below. Adopt does not ask Round 0.

## Round 1 — purpose and scope
1. What is the workspace for and which preset fits? (`presets/*/preset.md`; "none" = core only). Domain words become the generated `/kb` description.
2. Language of the content (README, notes, wiki pages). Answers always follow the asker.
3. Which folders are sources (default raw/ + wiki/), which must never be indexed (default docs/), and the name of the output folder (default kb/).
4. Precedence: confirm the default (most recent wins; raw/ wins over wiki/ unless `overrides:`), and how versions are named.

## Round 2 — confidentiality and processing
1. What may Claude read in full? Default: deterministic conversion only; Claude describes images/diagrams; prose extraction (`extract-llm`), graphify over raw/ and the token-eval baseline need per-document authorization.
2. Are image descriptions allowed for all documents? (they send page images to the model).
3. Spreadsheets: which ones are structured matrices worth a mapping (compliance/requirements, RACI, checklists)?
4. Wiki conventions: index notes in wiki/ with the facts conventions (Decision/Hypothesis/Deadline/Term/Condition)? Confirm the Zettelkasten defaults too: flat wiki/ with `type: fleeting|literature|permanent`, file names `YYYY-MM-DD-slug.md`, `[[links]]`.

## Round 3 — team and versioning
1. Versioning: git, OneDrive/Teams, or both (detect first; confirm). For OneDrive/Teams, offer to walk through `onedrive-teams-sync.md`.
2. Who updates the KB? Default: one curator at a time with the advisory lock; others use read-only mode (`KB_READONLY=1` or `--read-only`).
3. Copy the engine into the workspace (`scripts/kb-engine/`, about 400 KB of text) so people without the kb-setup skill can still consult the KB? Recommend **Yes** when versioning is OneDrive/Teams or both, or when there are read-only consumers; **No** for individual use with git. With a copy, consultation needs only `uv` and Claude Code; curation (update, upgrade, eval, review, skills, ontology) still needs kb-setup. The central engine wins when both exist; `/kb-setup upgrade` refreshes the copy.
4. Review period for notes (default 14d) and behavior for overdue notes (default: alert only).

## Round 4 — integrations
1. graphify is required (installed from the graphify-kb fork, not a question). Ask only about scope: default code + docs/ + wiki/ (recommended); which raw/ documents, if any, are authorized for graphify.
2. Task skills to generate (from the preset catalog and the material found) — max 4, user picks.
3. Evals: run a baseline eval now? (12 × 3 × 3 is expensive; offer a smaller first run).
4. Anything the KB must avoid or require (new policy constraints, deadlines, people to notify).

## Autonomous mode
Resolve each question without asking, in this order: what the user said in the request → discovery → the recommended default below. Never assume the limits listed in `SKILL.md` (init → "Limits of the autonomous mode").
- **R1.1** purpose/preset: infer from file and folder names; "none" (core only) if nothing matches. Title = folder name.
- **R1.2** language: guess from file names; otherwise the language the user writes in.
- **R1.3, R1.4:** the defaults above.
- **R2.1:** deterministic conversion only, no authorizations.
- **R2.2:** images described (the default).
- **R2.3:** map the spreadsheets whose headers (`KB outline`) look like a compliance matrix, RACI or checklist.
- **R2.4:** yes.
- **R3.1:** what discovery detected: git repository → git; OneDrive path → onedrive; both → both; neither → git (only the `.gitignore` block).
- **R3.2:** one curator.
- **R3.3:** the rule above (Yes for onedrive/both or read-only consumers).
- **R3.4:** 14d, alert only.
- **R4.1:** code + docs/ + wiki/, no raw/.
- **R4.2:** the preset templates whose material was found.
- **R4.3:** no eval now; offer it in the closing summary.
- **R4.4:** nothing.

Record every decision in the `kb/SETUP.md` table with the answer marked "(default — autonomous)".

## Questions specific to adopt
- Keep the existing domain prefix and instance namespace (recommended: yes — IRIs stay stable)?
- Delete the local v1 engine (`scripts/kb/`) after a successful migration?
- Copy the new engine into the workspace (R3.3)? It goes to `scripts/kb-engine/`, never back to `scripts/kb/`.
- Rename saved queries to English or keep their names?
