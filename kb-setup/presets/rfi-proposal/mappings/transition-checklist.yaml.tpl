# Spreadsheet -> ontology mapping: TRANSITION / KNOWLEDGE-TRANSFER CHECKLIST (preset rfi-proposal). DRAFT until approved.
# Project-to-operations (support / run) handover checklist that the proposal must cover item by item.
# Rendered by kb-setup into kb/mappings/<slug-of-the-file>.yaml. Engine syntax: see compliance-matrix.yaml.tpl.
#
# Typical layout quirks seen in real checklists (check with `KB outline <file>` and a subagent sample):
#   - a title/instructions block above the table: the header row is far down (e.g. row 8-12), set header_row;
#   - the item number column has NO header text: address it by letter ("@B") in iri, label and columns;
#   - section rows (only a heading, no item text) must be skipped with `require`;
#   - several sheets (e.g. entry checklist, exit checklist): repeat the block per sheet with a distinct iri segment.

source: "{{SOURCE_TRANSITION_CHECKLIST}}"
sheets:
  - sheet: "{{SHEET_TRANSITION}}"
    header_row: {{HEADER_ROW_TRANSITION}}
    require: ["{{COL_ITEM}}"]
    iri: "transition-checklist/{{{COL_ITEM_NUMBER}}}"        # e.g. {@B} when the number column has no header
    label: "{{{COL_ITEM_NUMBER}}}. {{{COL_ITEM}}}"
    class: {{PREFIX}}:TransitionChecklistItem
    columns:
      "{{COL_ITEM_NUMBER}}": kb:originalId                    # e.g. "@B"
      "{{COL_ITEM}}": kb:excerpt                              # literal item text
      "{{COL_APPLICABLE}}": {{PREFIX}}:applicable
      "{{COL_STATUS}}": {{PREFIX}}:status
      "{{COL_PHASE}}": kb:phase                               # phase in which the item is produced
      "{{COL_STORAGE_LOCATION}}": {{PREFIX}}:storageLocation
      "{{COL_NON_CONFORMITY_TYPE}}": {{PREFIX}}:nonConformityType
