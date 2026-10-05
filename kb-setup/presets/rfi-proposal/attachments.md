# Building the `attachments:` map (preset rfi-proposal)

A request package almost always has a **main document**: the RFI/RFP technical document and/or the tender notice. It lists its **attachments** with official numbers, and its body cites them as "Attachment N". The engine turns those citations into `kb:references` links from the citing section to the attachment's document, which is how the KB answers "what does Attachment 3 require about X?".

Real packages break the naive "Attachment N → file whose name starts with N" rule in several ways:

- the text cites the **wrong number** for an attachment (the name after the number is right);
- a file in `raw/` is **named with a different number** than the official list;
- an attachment in the official list is **missing** from `raw/`;
- a second document (e.g. the tender notice) lists attachments **without numbers**;
- an attachment is a **ZIP** that was unzipped into a folder of sub-attachments;
- the same title is spelled differently ("v2" vs. "v 2", with or without accents).

The `attachments:` block of `kb/config.yaml` fixes this. For each document family it holds the official list, and for each attachment it holds aliases (name fragments).

**Resolution order** (engine): alias found right after "Attachment N" > official number for the citing document's family > file-name number (only for families without a list). A mismatch between alias and number is recorded as "divergent numbering" in `kb:referenceText`. A listed attachment with `file: null` is recorded as "missing from raw/". Both show up in `KB query gaps`.

> Engine 2.0.0 detects citations only in the Portuguese form of "Attachment N" (see `preset.md`, Engine caveats). For English/Spanish documents, build the map anyway: it documents the package for the team and the task skills. The links appear once the engine supports the language.

## Procedure (one `general-purpose` subagent, authorized documents only)

The main context never reads the documents. Give the subagent a self-contained prompt with:

1. **Inputs:**
   - the workspace root;
   - the converted `.md` path of each main document (`raw/**/<doc>.md`, with page markers);
   - the list of files in `raw/`, from `KB status` or `ls`;
   - the family slug of each main document (the engine derives it from the normalized file name without version tokens; `KB show` on the document IRI or the manifest shows it).
2. **Tasks:**
   1. Find the **official attachment list** of each main document (usually a section titled Attachments/Annexes near the end, or in the introduction of a tender notice). Record number, title and page.
   2. Find **every citation** of "Attachment/Annex/Appendix N" (and the workspace-language equivalent) in each main document. Record page, section number, the cited number and the name that follows it.
   3. Match each list entry to a file or folder in `raw/` by title. Record files whose name number differs from the official number, and entries without a file.
   4. Propose `aliases`: 2–5 lowercase, accent-free fragments that identify the attachment in citations and are unlikely to match other attachments. Include spelling variants seen in the text.
3. **Deliverable:**
   - the YAML block below, written to a file in the scratchpad;
   - a comment table of citations (`page | section | cited number -> real attachment (ok | divergent)`);
   - counts: list size, citations, divergences, missing files.

   No document excerpts beyond attachment titles.
4. **Verification by the main context:** the YAML parses, every `file` exists (or is `null` on purpose), and every family key matches a real family. Then show the user the counts and the divergences for approval. This is part of the init checkpoint.

## YAML skeleton

```yaml
# Attachments map — <main document title> (+ <tender notice title>). Built by subagent on <YYYY-MM-DD>.
# Official list: <main document file>, section <N> "<list title>", p.<N>.
# Citations (page | section | cited number -> real attachment):
#   p<N> | <section> | Attachment <n> "<name as cited>" -> Attachment <n> (ok)
#   p<N> | <section> | Attachment <n> "<name as cited>" -> Attachment <m> (DIVERGENT: resolved by alias)
# Files named with a different number than the official list:
#   raw/.../<file name with number k> -> officially Attachment <m>
attachments:
  - id: compliance-matrix                       # stable slug, used in reports
    title: "Attachment {{N}} - {{TITLE}}"       # official title as listed
    file: "raw/{{PATH_TO_FILE}}"                # workspace-relative; a folder for unzipped ZIPs; null if missing
    aliases: ["{{alias 1}}", "{{alias 2}}"]     # lowercase, accent-free fragments seen after "Attachment N"
    numbers:
      {{MAIN_FAMILY}}: [{{N}}]                  # official number(s) in the main document's family
      {{NOTICE_FAMILY}}: []                     # listed without number in the notice (or not listed)

  - id: proposal-template
    title: "Attachment {{N}} - {{TITLE}}"
    file: "raw/{{PATH_TO_FILE}}"
    aliases: ["proposal template", "{{alias}}"]
    numbers: {{{MAIN_FAMILY}}: [{{N}}], {{NOTICE_FAMILY}}: []}

  - id: missing-attachment-example
    title: "Attachment {{N}} - {{TITLE}}"
    file: null                                  # listed but absent from raw/ -> reported as missing
    aliases: ["{{alias}}"]
    numbers: {{{MAIN_FAMILY}}: [{{N}}]}

  # Notice attachments without numbers (terms and conditions, supplier portal guide, acceptance form...)
  - id: general-terms
    title: "{{TITLE}}"
    file: "raw/{{PATH_TO_FILE}}"
    aliases: ["{{alias}}"]
    numbers: {{{MAIN_FAMILY}}: [], {{NOTICE_FAMILY}}: []}
```

Typical attachment ids in this domain are `compliance-matrix`, `proposal-template`, `quality-and-testing`, `testing-sub-attachments` (ZIP folder), `raci`, `service-level-procedure`, `security-requirements-in-contract`, `supplier-evaluation`, `transition-checklist`, `general-terms`, `specific-terms`, `technical-specification` and `supplier-portal-guide`. Use only those that exist.

## Tips

- Aliases are matched as substrings in the folded text right after the citation. Avoid generic words ("requirements", "matrix") that would match several attachments.
- One file can belong to several families with different numbers: list each family under `numbers`.
- After the next `KB update`:
  - run `KB query gaps` (unresolved, divergent and missing references);
  - spot-check 2–3 citations with `KB show <section>`.
