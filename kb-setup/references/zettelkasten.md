# Zettelkasten workspace (empty or new workspaces)

## The method, mapped to folders
| Folder | Zettelkasten role | Who writes | Indexed |
|---|---|---|---|
| `raw/` | **Sources** (the "literature" itself): client/vendor/partner documents, as received. Binaries get a deterministic `.md` beside them. | team drops files | yes (layer raw) |
| `wiki/` | **Notes**: `fleeting` (quick capture, meeting minutes, ideas), `literature` (your reading notes about one source in raw/, in your own words, with `source:`), `permanent` (atomic, reusable ideas/decisions linked with `[[links]]`). | team | yes (layer wiki) |
| `kb/` | **Index / knowledge graph** (generated): ontology, triples, manifests, generated wiki pages, evals, improvement backlog. | engine + curator | — |
| `docs/` | **Outputs** produced from the notes and the KB (proposal drafts, reports). Dynamic, never indexed. | team / task skills | never |

Flow to explain to the user: capture in `fleeting` → when reading a source, write a `literature` note pointing to it → distill durable ideas into `permanent` notes, one idea per note, linked to others → write deliverables in `docs/` citing notes and sources. Revisit notes when the review period expires (`/kb stale`).

## Note header (R2) and conventions
```yaml
---
title: Kickoff meeting with the client
type: fleeting            # fleeting | literature | permanent
source: raw/client/RFP.pdf   # literature notes only
last_reviewed: 2026-10-04
reviewed_by: Full Name
review_every: 14d         # optional; default in kb/config.yaml
overrides: []             # raw/ paths or id:topic/<name> this note explicitly overrides
---
```
- File names: `wiki/YYYY-MM-DD-short-slug.md` (`KB new-note "<title>" --type permanent`).
- Links: `[[note-title-or-file-stem]]` between notes (become `kb:linksTo`), `[text](../raw/...)` to sources (become references).
- Facts extracted to the graph (one per line, any of en/pt/es keywords): `- Decision: …`, `- Hypothesis: …`, `- Assumption: …`, `- Deadline: <milestone> = YYYY-MM-DD`, `- Term: <ACRONYM> = <definition>`, `- Condition: <topic> = <value>`.
- Missing/incomplete header: the note is still indexed with a fallback (git author/date or mtime + "unknown") and flagged "header inferred".

## Init steps for an empty workspace
1. `KB scaffold ...` (creates raw/ wiki/ kb/ docs/, config, backlog, .gitignore block if git).
2. Write `README.md` from `assets/templates/README.md` in the workspace language (method + folders + header + precedence + how to use /kb).
3. Create the three example notes from `assets/templates/notes/` (fleeting, literature, permanent) dated today, clearly marked "example — delete when you have your own notes".
4. Guided first note: ask (AskUserQuestion or short free text) for the workspace objective, context, stakeholders, known deadlines, open questions; then `KB new-note "<objective title>" --type permanent` and fill it with the answers using the conventions above (Decision/Hypothesis/Deadline lines) — this seeds the graph.
5. `KB update` (indexes the notes; core ontology suffices) and `KB ask "<objective keyword>"` to show the user it works.
6. Explain how to add the first documents to raw/ and run `/kb update` (or `/kb-setup update`); the domain ontology will be proposed then.
