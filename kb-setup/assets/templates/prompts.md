# Subagent prompt templates (kb-setup and generated skills)

All subagents: `subagent_type: general-purpose`, self-contained prompt, workspace root given as an absolute path, one simple command per Bash call, a verifiable deliverable (file written + counts).

Note: the harness may refuse the Write tool for *report-like* files created by subagents ("Subagents should return findings as text"). Ask subagents to write data files through the engine or Bash where possible (e.g. `KB set-image`, JSON/TTL outputs) and to **return reports as text** in their final message; the orchestrator saves them. Never ask a subagent to work around a refusal. Replace `KB` by `uv run ~/.claude/skills/kb-setup/scripts/kb.py`, or by `uv run scripts/kb-engine/kb.py` when only the workspace copy of the engine exists.

## 1. Image description (batches of ~15 unique images per subagent)
> You describe images extracted from documents for a local knowledge base. Workspace root: <root>. Batch: `<md>` with assets <list> (relative to the .md folder).
> For each image: (1) `KB image-context "<md>" "<asset>"` — PNG path and text of the SAME page only; do not read the whole .md. (2) Open the PNG with Read. (3) Decorative (logo, photo without information) or a rendered page whose text is already transcribed → `KB set-image "<md>" "<asset>" --ignore "<short reason>"`. (4) Otherwise write the description to a scratch file with Write and run `KB set-image "<md>" "<asset>" --text "$(cat <file>)"` (or `< <file>`).
> Description: first line = figure type + subject; then bullets/table with ALL informative content (components with exact labels, flows source → target, legends, numbers, dates, roles, table values). Literal transcription, "[illegible]" when unreadable, no opinions, do not repeat the page text. Report low-resolution images and uncertain labels explicitly.
> Finish with `KB pending-images "<source>"` and reply with a list `asset → DESCRIBED/IGNORED + one line`.

## 2. Prose extraction (`extract-llm`, authorized documents only)
> Extract RDF (Turtle) from `<md>` following the core ontology `<core ttl>` and the domain ontology `<domain ttl>` (read them first) and the shapes. Write ONLY to `<output ttl>`.
> Prefixes: `kb: <http://kb.local/core#>`, `<prefix>: <namespace>`, rdfs, skos, dcterms, xsd. **Instances always as full IRIs in `< >`** (e.g. `<instances>req/1.01>`) — prefixed names with `/` are invalid Turtle.
> Every instance: rdf:type from the ontologies, rdfs:label, kb:definedIn <doc IRI>, kb:page N (integer, from `<!-- page: N -->`), kb:excerpt "<short literal quote>".
> Reuse existing IRIs (`KB search "<term>"`): sections `<base_section><number>`, topics `<instances>topic/<name>`.
> Focus on what the deterministic extractor misses: requirements in prose, evaluation criteria, deliverables, systems/modules, roles, deadlines tied to their milestone, clauses, kb:references / kb:contradicts. Only what the text states. Validate with `KB validate` and fix until your file has no violations. Reply with counts per class.

## 3. Eval answer key
> Build the answer key for the questions in `<questions.md>` using ONLY these authorized files: <list of .md>. Do not use kb.py, kb/, graphify-out/. Grep + Read with offset/limit. For each question: expected facts, sources (file + page or sheet + row), scoring 2/1/0, note when facts come from figure descriptions, verify negative questions by searching. Write `<answer_key.md>`; reply only "key ready" + one short line per question.

## 4. Eval answering (one question, one configuration)
> You are configuration `<baseline|graphify|kb>` of an eval. Question: "<question>". Rules: <rules for the configuration from references/evals.md>. Cite file + page or sheet + row; say "not found" instead of guessing; count your tool calls. Write the answer to `<path>` (answer, citations, tool calls). Reply only "done <Q> <calls>".

## 5. Eval grader
> Impartial grader. Files: questions, answer key, answers per run/configuration. For each answer: accuracy 0/1/2 (answer key criteria), citation 0/1/2 (2 = file + page/sheet+row correct; 1 = file only or imprecise; 0 = none/wrong), hallucination yes/no, one-line note. Write `grades.json` as a list of {run, config, question, accuracy, citation, hallucination, note}. Reply with totals per configuration.

## 6. Topics / facts / attachments survey (authorized documents only)
> Find concepts with values that appear in 2+ documents (environments, test levels, severities, horizons, validity, SLAs…), and the official attachment list with numbering divergences. Propose `topics`/`facts`/`attachments` rules in kb/config.yaml syntax (English keys), test every regex against the real text (accent-free lowercase, window search) and report hit counts and values per document — evidence as document + page + ≤20 words. Never paste longer excerpts. Write `<rules.yaml>`; reply with the rule names and per-document values.
