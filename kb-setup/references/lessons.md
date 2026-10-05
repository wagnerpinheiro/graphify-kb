# Lessons learned (load during init / adopt / review)

These lessons come from building the first KB and from later real use of it. Each one is a pitfall
that has already happened. Apply them before you hit them again.

Engine prefix used below: `KB="uv run ~/.claude/skills/kb-setup/scripts/kb.py"`. In practice, write the
full prefix in each call (one command per call, so auto mode can approve it). Saved query names
(`conflicts`, `internal-inconsistencies`, `precedence`, `requirements-by-topic`) refer to files in
`kb/queries/`. If a workspace still uses older or localized file names, use those names instead.

## Contents
1. [Environment and dependencies](#1-environment-and-dependencies)
2. [PDF / DOCX / XLSX conversion](#2-pdf--docx--xlsx-conversion)
3. [File names and Unicode](#3-file-names-and-unicode)
4. [Images and subagents](#4-images-and-subagents)
5. [Ontology, IRIs and precedence](#5-ontology-iris-and-precedence)
6. [SPARQL pitfalls](#6-sparql-pitfalls)
7. [Turtle written by LLMs](#7-turtle-written-by-llms)
8. [Topics and quantitative facts](#8-topics-and-quantitative-facts)
9. [Attachment numbering](#9-attachment-numbering)
10. [Query latency](#10-query-latency)
11. [Coexistence with graphify](#11-coexistence-with-graphify)
12. [Evals](#12-evals)
13. [Process](#13-process)
14. [OneDrive / Teams and team use](#14-onedrive--teams-and-team-use)
15. [Checklist before declaring a KB ready](#15-checklist-before-declaring-a-kb-ready)

---

## 1. Environment and dependencies

**L1. Check that wheels exist for the machine's default Python before you pick a package.**
— *Why it matters:* `markitdown` depends on `magika`, which depends on `onnxruntime`, and `onnxruntime` had no wheel for the newest Python. Install failed.
— *How to apply:* For DOCX, use `mammoth` + `markdownify` directly (this is markitdown's own internal pipeline). For XLSX, use `openpyxl`. Before you add any dependency, test it with `uv run --python <default>`.

**L2. Use your own XLSX reader, not pandas or markitdown.**
— *Why it matters:* pandas-based conversion produces `NaN` and `Unnamed: n` cells, which pollute the triples and the citations.
— *How to apply:* Keep the engine's `openpyxl` path (`read_only=True, data_only=True`) and set `xlsx.max_empty_rows` in `config.yaml`.

**L3. Use PEP 723 inline scripts with no `.venv` or `pyproject` in the workspace.**
— *Why it matters:* A `.venv` inside a synced folder (OneDrive) breaks the sync and is tied to one platform.
— *How to apply:* Run the engine only through `uv run` (with `uv lock --script`). Run `$KB status` first: it validates the environment.

**L4. Re-read the managed policies on every init and upgrade.**
— *Why it matters:* Enterprise policies can forbid MCP, hooks, settings changes or bypass mode. If you don't know them, you design something the user cannot run.
— *How to apply:* Read `~/.claude/remote-settings.json`, `~/.claude/policy-limits.json` and `/Library/Application Support/ClaudeCode/managed-settings.json`. Check `allowedMcpServers`, `allowManagedHooksOnly`, `strictKnownMarketplaces`, `permissions.*` (pip/uv/docker/curl), `disableBypassPermissionsMode` and `availableModels`.

**L5. Don't ask to change settings to reduce permission prompts.**
— *Why it matters:* Managed environments may not allow it. Auto mode already approves simple commands.
— *How to apply:* Use one simple command per call, with no pipes or chains, and no hooks, MCP or settings edits.

**L6. Assume no LLM API key.**
— *Why it matters:* Tools that need an `LLM_API_KEY` (OpenKB, GraphRAG, LightRAG, Graphiti, Cognee) cannot be the extractor. The subscription OAuth via LiteLLM is broken.
— *How to apply:* Claude Code subagents are the only LLM extractor. Do the rest deterministically with `pyoxigraph` in memory: no server, no Docker.

## 2. PDF / DOCX / XLSX conversion

**L7. Page frames get detected as tables.**
— *Why it matters:* Corporate templates draw the header and footer as a grid. pdfplumber then sees one page-sized "table" that swallows all the text.
— *How to apply:* Keep `pdf.frame_table_ratio: 0.5`, which drops any table larger than 50% of the page. If a converted page looks like one giant table, lower it.

**L8. Table cells that wrap without a horizontal rule become sparse rows.**
— *Why it matters:* A requirement gets split across rows with empty IDs, and the facts break apart.
— *How to apply:* Merge each continuation row into the previous row. To spot-check, compare `$KB page-text <md> <page>` against the original page.

**L9. Multi-line headings and repeated headers/footers need explicit handling.**
— *Why it matters:* "Page N of M" lines and split titles pollute sections and search.
— *How to apply:* Set `pdf.strip_repeated_lines: true` and `pdf.repeated_line_ratio`. Normalize digits before you detect repeats. Tune `pdf.heading_size_ratio` per corpus.

**L10. Client spreadsheets have columns without headers and placeholder rows.**
— *Why it matters:* A row with an ID but no text becomes an empty requirement, and a column without a header cannot be mapped by name.
— *How to apply:* In the sheet mapping, use letter references (`{@C}`) and `require:` the key text columns. Have the user approve the mappings before bulk extraction.

**L11. Extract deadlines by sentence, and require a deadline keyword.**
— *Why it matters:* Matching on lines, with no keyword, turned citations of legal acts ("Decree-Law of 01/05/19xx") into deadlines.
— *How to apply:* Join the lines of each paragraph into sentences. Keep the deadline keyword list in `config.yaml`, in the language of the content.

## 3. File names and Unicode

**L12. Never use `Path.with_suffix` on source names.**
— *Why it matters:* Names that contain dots (`I.T`, `v1.1.0`) produced truncated `.md` names.
— *How to apply:* Build derived names by concatenation: `name + ".md"` and `name + ".assets"`.

**L13. Normalize everything to NFC.**
— *Why it matters:* On macOS, names that come from downloads or zips are NFD (decomposed accents). Image markers, version detection ("6th Version") and mappings silently failed to match, and subagents' `set-image` calls failed.
— *How to apply:* Apply `unicodedata.normalize("NFC", ...)` to every path and every string you compare. Test with an accented file name in the synthetic corpus.

**L14. Decode zips without the UTF-8 flag as cp437.**
— *Why it matters:* Without this, attachment names come out as mojibake and break citations and families.
— *How to apply:* `$KB unzip` re-decodes cp437 to UTF-8 and extracts into a sibling folder. Check the names after unzipping.

**L15. Check for duplicates by hash during discovery.**
— *Why it matters:* Two copies of the main document were byte-identical, and this only showed up after the first conversion.
— *How to apply:* Hash all sources before you convert. Early in the interview, ask about the version naming convention. `$KB status` warns about duplicates.

## 4. Images and subagents

**L16. Decorative images dominate.**
— *Why it matters:* Almost every page has a logo. Without filtering, you pay subagent time on noise. About 16 documents left only about 58 unique images after filtering.
— *How to apply:* Set `images.min_width/min_height/min_area` and `images.repeated_min_pages/repeated_page_ratio` (same hash on N+ pages means decoration).

**L17. Forms drawn with rectangles trigger the vector-page threshold.**
— *Why it matters:* These pages get rendered as images even though their text is already transcribed.
— *How to apply:* Tune `images.vector_threshold`. The image prompt tells subagents to run `$KB set-image <md> <asset> --ignore "text already transcribed"`.

**L18. Run image subagents in parallel and write through a locked writer.**
— *Why it matters:* 5 subagents with batches of 10–15 described 58 images in about 3 minutes. Without a lock, they race on the same `.md`.
— *How to apply:* Batch by document and page. Subagents write only through `$KB set-image` (`flock` per file). Use `$KB pending-images --json` to plan the batches.

**L19. Propagate descriptions by hash automatically.**
— *Why it matters:* Duplicate documents and repeated figures would otherwise be described again, or left pending.
— *How to apply:* `convert`/`update` reuse the description of any already described image with the same hash. Afterwards, `$KB pending-images` should list only truly new images.

**L20. Ask subagents to report uncertainty.**
— *Why it matters:* Low-resolution RACI matrices and process diagrams gave uncertain transcriptions. The subagents' reports also exposed the NFD bug.
— *How to apply:* The prompt requires an "uncertain: low resolution / illegible labels" note. Relay these notes to the user, who should check the original when a figure is a source of facts.

**L21. Confidentiality: the subagent sees only the image's page.**
— *Why it matters:* Each read of a client document is exposure. Image description must not turn into reading the whole document.
— *How to apply:* Give the subagent only `$KB image-context <md> <asset>` (plus `page-text` if needed). Prose extraction (`llm-context`/`llm-done`) requires the user's authorization for each document.

## 5. Ontology, IRIs and precedence

**L22. Mint IRIs from natural keys.**
— *Why it matters:* When the same fact comes from different sources, it must land on the same subject, so that precedence can act on it.
— *How to apply:* Use matrix ID, milestone name, or document family + section number, not source path or row index. Check convergence with `$KB show <id>`: it should list several sources.

**L23. Use version families only to break ties within the same document family.**
— *Why it matters:* Flagging "documents without a version" as fragile was a false alarm. Across different documents, the date decides.
— *How to apply:* Use `families:` in `config.yaml` (the default groups by common normalized name prefix). Warn only for families with more than one document.

**L24. Keep precedence in SPARQL and in Python in sync.**
— *Why it matters:* `ask`/`show` use Python, and saved queries use SPARQL. If the two diverge, the same question gets different answers.
— *How to apply:* Test both on the same cases: raw beats wiki without `overrides`; a note with `overrides` wins; a stale note keeps its precedence but raises a warning. Compare `$KB query precedence` with `$KB show <id>`.

**L25. Stale or headerless notes warn but don't lose precedence.**
— *Why it matters:* If precedence changed silently, an answer could flip just because a review date passed.
— *How to apply:* `$KB stale` lists stale notes. Headerless notes fall back to git log or mtime and are flagged as inferred.

**L26. Test the draft ontology with deterministic extraction before final approval, and tell the user.**
— *Why it matters:* Deterministic triples are cheap to regenerate, and the test reveals gaps (for example, DOCX has no page numbers, so it needs an order locator).
— *How to apply:* Say "I will test with the draft; it is regenerable" before you run `$KB extract-det`. Then ask for approval of the ontology and the mappings.

## 6. SPARQL pitfalls

**L27. pyoxigraph does no RDFS inference.**
— *Why it matters:* `?x a dom:Requirement` does not match instances of subclasses, and the query silently returns too little.
— *How to apply:* List the concrete classes (`VALUES ?c { ... }`) in saved queries. Document this in the generated `/kb` skill.

**L28. Use `SELECT DISTINCT` on the union graph.**
— *Why it matters:* With `use_default_graph_as_union`, the same triple from two sources appears twice.
— *How to apply:* Every saved `.rq` uses `DISTINCT`. Rows that differ only by source come from per-source queries.

**L29. Detect conflicts by comparing sets of values per source.**
— *Why it matters:* Comparing value by value turns multi-valued properties into false conflicts.
— *How to apply:* Group values per (subject, property, source), then compare the sets. Check with `$KB query conflicts`: every row should be a real divergence.

**L30. Write parameterized queries for thematic surveys.**
— *Why it matters:* A thematic survey cost about 28 calls before a parameterized query did it in 1.
— *How to apply:* Use `{{name}}` placeholders in the `.rq`, and run `$KB query requirements-by-topic --param front=... --param section=...`.

## 7. Turtle written by LLMs

**L31. Prefixed names that contain `/` are invalid Turtle.**
— *Why it matters:* `id:req/1.01` makes the parser fail. One bad file used to break the whole load.
— *How to apply:* The extraction prompt requires full IRIs in `<...>`. The loader and `$KB validate` report the invalid file and keep going.

**L32. Validate every LLM batch with SHACL before you accept it.**
— *Why it matters:* LLM triples drift: wrong classes, missing provenance.
— *How to apply:* Run `$KB validate` after each `llm-done`. Reject the batch and re-run it if there are violations.

## 8. Topics and quantitative facts

**L33. Divergent deadlines don't collide unless they share a topic subject.**
— *Why it matters:* Proposal validity was 60 days in one document and 90 in another, and neither system detected it. Each deadline was its own occurrence entity.
— *How to apply:* Add `topics:` regexes in `config.yaml` so that matches converge in `id:topic/<topic>`. Then precedence and `conflicts` act on them.

**L34. Quantitative facts are the most dangerous kind of divergence.**
— *Why it matters:* The main document asked for 4–5 environments and an annex asked for 3–4. Topics fired only on sentences with a deadline, so this was missed.
— *How to apply:* Use `facts:` with `context` + `value` regexes searched in a window, and `normalize` (`count`, `count_distinct`, `months`, `number`, `acronyms`). During init, a subagent proposes and tests rules for numeric concepts that appear in more than one document.

**L35. Folding must keep dashes and newlines.**
— *Why it matters:* An accent-free fold that also stripped dashes and newlines broke `^`-anchored, per-line rules, and broke the offsets used to cite the literal snippet.
— *How to apply:* Use `fold_keep` (same length, indices preserved). Write rules against folded lowercase text.

**L36. Rules that count list items need a minimum.**
— *Why it matters:* "from development to production" was counted as an enumeration of environments.
— *How to apply:* Set `min: 2` (or higher) on `count` / `count_distinct` facts.

**L37. Drop rules whose values are not comparable.**
— *Why it matters:* Penalty percentages had different events and bases, so every "conflict" was noise.
— *How to apply:* Before you keep a rule, check its hits in `$KB query conflicts`. Remove it if the values differ in meaning, not only in number.

**L38. Comparing across sources misses inconsistencies inside one document.**
— *Why it matters:* One document said both 5 and 10 years for the cost horizon, and 4 and 5 environments.
— *How to apply:* Ship the `internal-inconsistencies` query and run `$KB query internal-inconsistencies` at every review.

## 9. Attachment numbering

**L39. A document's own attachment numbering may not match the file names.**
— *Why it matters:* The main document cited a security annex as "Attachment 6", and used "Attachment 7" for another file. Naive "Attachment N" linking created wrong references.
— *How to apply:* In `attachments:` in `config.yaml`, list the official attachments per family, with `aliases`, `numbers` and `file`. Resolution order: alias after "Attachment N", then official number, then file name. Have a subagent build this list during init.

**L40. Flag cited attachments that are missing from raw/.**
— *Why it matters:* An answer must not imply that the KB covers an annex it never received.
— *How to apply:* `$KB status` and the attachments report list cited-but-absent attachments, plus a "numbering diverges" note.

## 10. Query latency

**L41. Latency comes from model rounds, not from the graph.**
— *Why it matters:* Engine commands took 0.13–0.23 s (about 17k triples load in about 50 ms), but the flow "read ontology → search → query → show → page-text" took 4–6 rounds.
— *How to apply:* Don't add a persistent cache or index. Count calls per question first.

**L42. Ship a single answer command and an inline schema summary.**
— *Why it matters:* `ask` (search + ranking + precedence + citation) answers in 1 call. A schema summary in SKILL.md avoids reading the `.ttl` files.
— *How to apply:* Generate both by default. Tune `ask --fonte` filters, snippet width and ranking bonuses (topics, exact label). `ask` prints a warning when no entity covers all terms, and `NO ANSWER IN KB` when nothing matches.

## 11. Coexistence with graphify

**L43. Routing is ambiguous when `graphify-out/` exists.**
— *Why it matters:* graphify's description claims "any question about the project content". A neutral subagent picked `/kb` only because of CLAUDE.md, and it still noticed the ambiguity.
— *How to apply:* Write an explicit rule in the project CLAUDE.md: questions about sources go to `/kb`; graphify runs only when asked explicitly, or for code and `docs/`.

**L44. graphify writes its cache inside the scanned directory.**
— *Why it matters:* `raw/graphify-out/` holds content extracted from client documents. It leaks through git and pollutes indexing.
— *How to apply:* Add `graphify-out/` to `.gitignore` and to `sources.never_index` (the engine skips it at any depth). Cover it in the confidentiality rule.

**L45. graphify on documents is full-text LLM reading.**
— *Why it matters:* Its subagents read entire files (about 296k tokens for 6 documents). That is the same exposure as `extract-llm`.
— *How to apply:* Default scope is code + `docs/`. Allow raw/ only per authorized document, through `raw/.graphifyignore`.

**L46. Block Gemini for client data.**
— *Why it matters:* If `GEMINI_API_KEY` or `GOOGLE_API_KEY` is set, graphify sends content to Google.
— *How to apply:* Check the environment before any graphify run on documents. Refuse, or unset the key, for confidential material.

**L47. `graphify add <url>` writes into `./raw`.**
— *Why it matters:* raw/ holds the official sources. Downloads would mix with them and gain precedence.
— *How to apply:* Never use `add` in KB workspaces. `--mcp`, `--neo4j` and `--falkordb` conflict with the policies as well.

**L48. graphify respects `.gitignore`.**
— *Why it matters:* It sees the converted `.md` files but not the binaries, so its coverage differs from the KB's.
— *How to apply:* Install the tested version as a uv tool from the graphify-kb fork (`references/graphify.md`) and record it in `kb/config.yaml` → `graphify.version`. Don't build a data bridge into the KB by default.

## 12. Evals

**L49. Use a design that separates roles and stays in subagents.**
— *Why it matters:* If the answerer or grader has seen the answer key, or if documents enter the main context, the eval is invalid.
— *How to apply:* Use an authorized subset; 12 questions across types (RACI, point fact, cross-document, figure, metadata, aggregation, relation, negative, exploratory). One subagent builds the answer key from the sources, one answerer runs per system, and a blind grader scores correctness 0–2, citation 0–2 and hallucination.

**L50. Reference result (KB vs graphify, 1 round).**
— *Why it matters:* It sets expectations. The KB won on correctness (24/24 vs 21/24) and citation (24/24 vs 18/24), with 0 hallucinations on both sides. graphify used fewer calls (19 vs 27), and the KB's build cost was far lower (deterministic, LLM only for images).
— *How to apply:* The KB is strong on figures, cross-document questions and page-level citations. graphify is strong on single-call aggregation, negative and relation questions. Neither system caught a divergence between documents until topics/facts existed.

**L51. State the caveats in every eval report.**
— *Why it matters:* n is small, the grader is from the same model family, and the answer key is LLM-generated.
— *How to apply:* For the token/time eval, run 3 configurations (none / graphify only / KB + graphify), 12 questions × 3 rounds. Relate costs to volume (files, pages, words, MB). Write `kb/evals/` without long snippets; full answers stay in the scratchpad.
— *Token-eval result (4 documents, 44k words, 1 round):* baseline (grep in a subagent) and KB tied at 24/24 with ~36.6k tokens/question; graphify 15/24 (no page in `source_location`, misses tables and figures). A subagent costs ~20k tokens before doing anything, so measure that fixed cost and report *context added*. The KB's saving shows up when its compact output is read in the main context (≈ 2.2× fewer tokens than a baseline subagent), which the "documents only in subagents" rule allows for KB output but not for raw text. Say so plainly instead of claiming cheaper retrieval.

## 13. Process

**L52. Measure before you optimize.**
— *Why it matters:* A complaint about slowness looked like it needed a cache. Measuring showed the bottleneck was model rounds.
— *How to apply:* Record the time per engine command and the calls per question before you change any design.

**L53. Checkpoints belong to the user.**
— *Why it matters:* Testing with a draft is fine, but if the user learns about it only from the final report, their control is gone.
— *How to apply:* Announce each test or draft at the moment you run it. Get explicit approval for the ontology, the mappings and task skills before bulk extraction.

**L54. Never test in the real workspace.**
— *Why it matters:* Test notes and sources (precedence, review headers) added to raw/ or wiki/ and "cleaned up later" risk contaminating the KB.
— *How to apply:* `rsync -a --exclude .git <ws>/ <scratchpad>/ws-copy/` and test there, with `--root`.

**L55. Verify subagent output.**
— *Why it matters:* A fork came back quickly having only restated its instructions, with no work done.
— *How to apply:* Use `general-purpose` subagents with self-contained prompts and a checkable deliverable (for example, `pending-images` drops to 0). Re-run the subagent if it returns too fast.

**L56. Process documents only in subagents.**
— *Why it matters:* This keeps client content and bulk text out of the main context. It applies to the meta skill, the generated skills and graphify.
— *How to apply:* Full reads, prose extraction, image description, rule discovery and answer keys run in subagents that return compact results.

**L57. Check for conflicts between global skills.**
— *Why it matters:* Overlapping descriptions (graphify, other graph or KB skills) cause the wrong skill to trigger.
— *How to apply:* During discovery, compare installed skill descriptions with the planned `/kb`. Give generated skills a project prefix and non-overlapping descriptions, and record the routing in CLAUDE.md.

**L58. Ask early about duplicates, versions and confidentiality.**
— *Why it matters:* These answers decide families, precedence, and whether the LLM may read prose at all.
— *How to apply:* Put them in the first interview round, together with source and never-index folders and the versioning mode.

**L59. Validate the Desktop Code tab manually.**
— *Why it matters:* Only the CLI was validated automatically. The Desktop tab uses the same runtime, but the user must confirm it.
— *How to apply:* List it as a manual check in the init report.

## 14. OneDrive / Teams and team use

**L60. Use an advisory curator lock.**
— *Why it matters:* Two people updating at once corrupt the manifest and the triples.
— *How to apply:* Writing commands take `kb/.lock` (reentrant for the same user and machine, with `lock_timeout`). `$KB unlock --force` is for stale locks only, after confirming with the owner.

**L61. Detect conflict copies.**
— *Why it matters:* OneDrive creates `name-MACHINE.ext` or "(conflicted copy)" files that would be indexed as new sources.
— *How to apply:* `$KB status` and `update` list conflict copies and never index them. The user resolves them following `references/onedrive-teams-sync.md`.

**L62. Don't trust mtime; detect changes by content hash.**
— *Why it matters:* Sync and copy operations change mtime without changing content, which would trigger reprocessing.
— *How to apply:* The per-source manifest stores hashes, with separate hashes for body and frontmatter on notes. `touch` on a source must not cause any work.

**L63. Use relative paths, and keep nothing binary or machine-specific in kb/.**
— *Why it matters:* The workspace has to work on any machine and in a copy without `.git`.
— *How to apply:* Keep the store in memory and keep only text artifacts in kb/. Extracted `.assets/` stay out of git, but live in the shared folder.

**L64. Give teammates a read-only mode.**
— *Why it matters:* Consumers should query without taking the lock or triggering an update.
— *How to apply:* Use `$KB --read-only ask "..."` or `KB_READONLY=1`. Writing commands then abort with a "ask the curator" message.

**L65. Use the recommended OneDrive setup.**
— *Why it matters:* A synced library behaves worse than a shortcut, and files that are online-only break hashing.
— *How to apply:* Use "Add shortcut to My files" and "Always keep on this device". See `references/onedrive-teams-sync.md`.

---

## 15. Checklist before declaring a KB ready

Run these in the workspace, or in a scratchpad copy for the destructive checks. All must pass.

| # | Check | Command / method | Expected |
|---|---|---|---|
| 1 | Environment and engine version | `$KB --version` then `$KB status` | Runs without creating `.venv`. Engine version matches `config.yaml` |
| 2 | Managed policies re-read | Read the 3 policy files (L4) | No MCP, hook or settings dependency in the generated skills |
| 3 | Duplicates and families | `$KB status` | Byte-identical copies are flagged. Families group only versions of the same document |
| 4 | Conversion sanity | `$KB outline` + spot-check `$KB page-text <md> <n>` against the original | No page-sized frame tables, no `NaN`/`Unnamed`, no truncated `.md` names |
| 5 | Unicode | `$KB status` on a corpus with accented and dotted names | NFC names, no mojibake from zips |
| 6 | Images complete | `$KB pending-images` | 0 pending. Uncertain transcriptions relayed to the user |
| 7 | SHACL | `$KB validate` | 0 violations. Invalid files reported by name |
| 8 | Precedence | `$KB query precedence` vs `$KB show <id>` | Same winner in SPARQL and Python. Stale-note warning shown |
| 9 | Conflicts | `$KB query conflicts` | Only real divergences (set-based). Known divergences are present |
| 10 | Internal inconsistencies | `$KB query internal-inconsistencies` | Runs. Every hit is real |
| 11 | Facts and topics | `$KB ask "<known numeric question>"` | Per-source values with ✓/✗ by precedence. No count with fewer than `min` items |
| 12 | Attachments | `$KB status` / `$KB show <attachment id>` | Official numbering resolved. Missing attachments flagged |
| 13 | Idempotent update | `$KB update` twice | Second run prints nothing to process |
| 14 | Touch does not reprocess | `touch raw/<file>` then `$KB update` | Nothing to process (hash unchanged) |
| 15 | Portable copy | `rsync -a --exclude .git` to scratchpad, `$KB --root <copy> status` and `ask` | Works without git (mtime fallback for notes) |
| 16 | Foreign lock aborts | In the copy, write a `kb/.lock` owned by another user/host, then `$KB update` | Aborts with the lock owner shown |
| 17 | Conflict copy detected | In the copy, create `<name>-LAPTOP.md` / `(conflicted copy)`, then `$KB status` | Listed as a conflict copy and not indexed |
| 18 | Read-only mode | `$KB --read-only update` | Refused. `--read-only ask` works |
| 19 | One-call answer | `$KB ask "<known question>"` | Correct answer with file + page/sheet-row citation in 1 call. `NO ANSWER IN KB` for a negative question |
| 20 | Routing with graphify-out present | Neutral subagent, CLAUDE.md loaded, `graphify-out/` present, asks a source question | Picks `/kb`. `graphify-out/` is ignored by git and by the engine |
| 21 | graphify from the fork | `graphify --version`, `<uv tool dir>/graphifyy/uv-receipt.toml`, `ls graphify-out/graph.json` | Version equals `graphify.version` in `kb/config.yaml`, installed from the fork (not PyPI). Graph built; no unauthorized raw/ file in the detect list |
