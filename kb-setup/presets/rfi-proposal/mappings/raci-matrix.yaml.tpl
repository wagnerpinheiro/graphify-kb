# Spreadsheet -> ontology mapping: RACI / RESPONSIBILITY MATRIX (preset rfi-proposal). DRAFT until approved.
# Rendered by kb-setup into kb/mappings/<slug-of-the-file>.yaml (one file per RACI spreadsheet; requests often
# ship more than one: a project RACI and a testing/quality RACI). Engine syntax: see compliance-matrix.yaml.tpl.
#
# What the engine does with `matrix`:
#   - every header from `from` to `to` (or to the last column) is a role -> kb:Role "id:role/<slug>";
#     the same role name in two spreadsheets converges on the same role entity (compare RACIs across files);
#   - every non-empty cell becomes a kb:RACIAssignment (kb:activity, kb:role, kb:raciCode, kb:sheet, kb:row);
#     cells like "R/A", "A,C", "R;I" are accepted; "-", "N/A", "NA" are skipped;
#   - each letter also links the activity to the role with the property in `codes`
#     (default kb:responsible / kb:accountable / kb:consulted / kb:informed — keep the defaults unless the matrix
#     uses other letters, e.g. RASCI "S" -> map it to a domain property you add to the ontology).
# `from`/`to` must be exact header texts; the engine fails if they are missing, so check `KB outline <file>` first.
# Role columns must be contiguous; columns after the last role (notes, totals) require `to`.
#
# IRIs: include the phase in the activity IRI when the same activity name repeats in different phases;
# use a distinct path segment per spreadsheet ("activity/project/...", "activity/testing/...") so two RACIs do
# not merge activities that only share a name (merging is wanted only if they are truly the same activity).

source: "{{SOURCE_RACI_MATRIX}}"
sheets:
  # Variant A — project RACI with phase, PMO phase, deliverable and execution order.
  - sheet: "{{SHEET_RACI_ACTIVITIES}}"
    header_row: {{HEADER_ROW_RACI_ACTIVITIES}}
    require: ["{{COL_ACTIVITY}}"]
    iri: "activity/project/{{{COL_PHASE_PMO}}}-{{{COL_ACTIVITY}}}"
    label: "{{{COL_ACTIVITY}}}"
    class: kb:Activity
    columns:
      "{{COL_PHASE}}": kb:phase                       # IT / delivery phase
      "{{COL_PHASE_PMO}}": {{PREFIX}}:phasePMO          # PMO phase, when the matrix has both
      "{{COL_DELIVERABLE_TYPE}}": {{PREFIX}}:deliverableType
      "{{COL_ORDER}}": {prop: kb:order, type: int}      # execution order
      "{{COL_DESCRIPTION}}": kb:description
      "{{COL_DELIVERABLE}}": {prop: kb:deliverable, type: iri, iri: "deliverable/{{{COL_DELIVERABLE}}}", class: kb:Deliverable}
    matrix:
      from: "{{COL_FIRST_ROLE}}"      # first role column (e.g. the sponsor); all columns up to `to` are roles
      # to: "{{COL_LAST_ROLE}}"       # uncomment when non-role columns follow the roles
      codes: {R: kb:responsible, A: kb:accountable, C: kb:consulted, I: kb:informed}

  # Variant B — testing / quality RACI where one phase cell spans several activity rows (cell merge).
  # Usually a separate spreadsheet: move this block to its own mapping file with its own `source`.
  # - sheet: "{{SHEET_RACI_TESTING}}"
  #   header_row: {{HEADER_ROW_RACI_TESTING}}
  #   require: ["{{COL_ACTIVITY}}"]
  #   fill_down: ["{{COL_TEST_PHASE}}"]           # cell merges: repeat the last phase downwards
  #   iri: "activity/testing/{{{COL_ACTIVITY}}}"
  #   label: "{{{COL_ACTIVITY}}}"
  #   class: kb:Activity
  #   columns:
  #     "{{COL_TEST_PHASE}}": kb:phase
  #   matrix:
  #     from: "{{COL_FIRST_ROLE}}"
  #     codes: {R: kb:responsible, A: kb:accountable, C: kb:consulted, I: kb:informed}
