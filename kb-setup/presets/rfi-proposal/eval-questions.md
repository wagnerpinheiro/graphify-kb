# Eval question types (preset rfi-proposal)

Template for the `eval` command (`references/evals.md`). It defines **12 question types**. They cover what a proposal team asks a KB, plus the failure modes seen in the first real evaluation:

- divergent values between documents not detected;
- the same document contradicting itself;
- attachments cited with the wrong number;
- figures summarized too briefly.

Instantiate one question per type for each workspace, on the **authorized subset** of documents.

## How to instantiate (all in subagents)

1. **Candidates.** A subagent uses the KB to find candidate material for each type. It returns entity ids, files and pages, never excerpts:
   - `KB query requirements-by-topic`, `raci-by-role`, `deadlines`, `gaps`;
   - the conflicts and internal-inconsistencies queries;
   - `KB outline`.
2. **Answer key from the sources, not from the KB.** Another subagent reads the cited pages or rows directly (`KB page-text`, or the spreadsheet). It writes the expected answer, the exact citation(s) and the grading notes (what counts as correct, partially correct or wrong). Building the key from the KB would be circular.
3. **Store:**
   - full answer keys and answers in the session scratchpad only;
   - in `kb/evals/`, only the question, a short expected answer (a value, a list or yes/no), the citation and the type. No long document excerpts.
4. **Grade with an impartial grader subagent:**
   - correctness 0–2;
   - citation 0–2 (right file and page/row);
   - hallucination yes/no.
5. **Record cost:** tool calls, tokens and time per question for each configuration (no KB × graphify only × KB + graphify).
6. **Rotate questions** between eval runs so they do not get overfitted. Keep the type mix.

Placeholders in angle brackets are filled per workspace: `<ROLE>`, `<ACTIVITY>`, `<ID>`, `<DOC>`, `<TOPIC>`... Write the questions in the workspace language. The phrasing patterns below are in English.

## The 12 types

| # | Type | What it tests | Phrasing patterns | Where candidates come from | Expected KB path |
|---|---|---|---|---|---|
| 1 | **Lookup** (structured row) | exact retrieval from a matrix row, with sheet and row | "In the responsibility matrix, who is accountable (A) for `<ACTIVITY>`?" · "What eligibility does requirement `<ID>` have?" | `raci-by-role`, `requirements-by-topic` | `show <ID>` or one `query` |
| 2 | **Point fact** | a single value stated in prose | "How many days must the proposal remain valid according to `<DOC>`?" · "What is the payment term?" | `deadlines`, facts (`kb:Fact`) | `ask` |
| 3 | **Cross-document** | combining two documents (request + attachment) | "Which attachment details the testing requirements cited in section `<N>` of `<DOC>`, and what test levels does it define?" | sections with `kb:references` to attachments | `ask` + `show` |
| 4 | **Figure content** | information only present in an image (diagram, RACI picture, timeline) | "According to the `<diagram>` on page `<N>` of `<DOC>`, which systems integrate with `<SYSTEM>`?" | image descriptions in the converted `.md` (pages with figures) | `ask` (image description text) |
| 5 | **Document metadata** | version, date, number of attachments, authorship | "What version of `<DOC>` is in the workspace and how many attachments does it list?" | document entities (`kb:version`, `dcterms:modified`), attachments map | `show <doc>` |
| 6 | **Aggregation** | counting or grouping over many entities | "How many mandatory requirements does the `<WORKSTREAM>` workstream have?" · "How many activities is `<ROLE>` responsible for?" | `requirements-by-topic`, `raci-by-role` | one `query` (or an inline COUNT) |
| 7 | **Relation** | following a link between entities | "Which deliverables are produced by activities where `<ROLE>` is responsible?" · "Which requirements reference attachment `<X>`?" | RACI + `kb:deliverable`; `kb:references` | `query` |
| 8 | **Negative** | correctly saying "not in the documents" | "Does `<DOC>` set a penalty for `<EVENT>`?" (when it does not) · "Is attachment `<N>` available in the workspace?" (when it is missing) | `gaps` (missing attachments), absence checked by the answer-key subagent | `ask` says there is no answer in the KB |
| 9 | **Exploratory** | a synthesized overview with citations | "Summarize what the request requires about `<THEME>` (e.g. environments, observability, data migration) across all documents." | `requirements-by-topic` with a theme regex | `query requirements-by-topic` + 1–2 `show` |
| 10 | **Conflicting values** | the same condition with different values in two documents, and which one prevails | "What is the proposal validity? Do the documents agree?" · "How many environments are required?" | the conflicts query, `deadlines` (topics), facts | `ask`/`show id:topic/<TOPIC>`: both values + winner + rule |
| 11 | **Internal inconsistency** | one document stating two values for the same fact | "Does `<DOC>` state a single TCO horizon?" · "Is the number of environments consistent within `<DOC>`?" | the internal-inconsistencies query | `query` internal inconsistencies |
| 12 | **Deadline** | dates and durations of the process or contract | "What is the deadline for clarification questions?" · "How long is the assisted operation (hypercare) period?" · "When is the proposal due?" | `deadlines`, milestones | `query deadlines` or `ask` |

## Grading notes per type

- **1, 6, 7:** an exact value or count is required. Citation is correct only with file + sheet + row, or file + page.
- **2, 12:** the value and its unit must match. If the KB shows a conflict, the answer must mention it (otherwise correctness ≤ 1).
- **3:** both documents must be cited. If the attachment is cited with divergent numbering, a correct answer names the real attachment.
- **4:** penalize answers that only paraphrase the caption. If the source figure is low-resolution, the answer key notes the uncertainty and the answer should too.
- **5:** if there are duplicate copies of a document, the answer should not count them twice.
- **8:** correct means saying it is absent, plus where it was searched or which attachment is missing. Any invented value is a hallucination.
- **9:** grade coverage of the answer-key points (≥ 70% = 2) and citation density.
- **10, 11:** both values with their sources are required. For 10, the winner and the precedence reason (date, version, override) are also required.

## Minimum set when time is short

For a quick check (for example after `upgrade` or an ontology change), use types 1, 2, 3, 8, 10 and 12. Each is one question and one run.
