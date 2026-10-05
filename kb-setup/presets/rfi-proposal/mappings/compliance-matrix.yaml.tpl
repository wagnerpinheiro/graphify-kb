# Spreadsheet -> ontology mapping: COMPLIANCE / REQUIREMENTS MATRIX (preset rfi-proposal). DRAFT until approved.
# Rendered by kb-setup into kb/mappings/<slug-of-the-file>.yaml; read by `kb.py extract-det`.
#
# How kb-setup fills it (never by reading the whole spreadsheet in the main context):
#   1. `KB outline <file>` lists sheets and header cells; pick the header row (1-based) per sheet.
#   2. Map each real header text to the placeholder below ({{COL_*}} = exact header text, accents included;
#      header text with leading/trailing spaces is trimmed by the engine).
#   3. Delete column lines that do not exist in the file; add lines for extra columns (string by default).
#   4. Repeated headers in the same sheet (e.g. two "Bidder comments" columns for answer rounds 1 and 2) can map
#      to the same property: both values are kept.
#   5. Run `KB extract-det <file> -v` on the draft, check row counts per sheet, tell the user it is a regenerable
#      test, then present the mapping for approval (checkpoint) before the full update.
#
# Engine syntax (keep exactly):
#   source            workspace-relative path of the .xlsx
#   sheets[]          sheet: name | header_row: 1-based row of the header (omit = auto-detect)
#                     require: [columns that must be non-empty]  -> skips placeholder/heading rows
#                       (typical: rows that carry only an id/category such as "1.00", "1.01" with no requirement text)
#                     iri: instance path template ({Column} or {@Letter}); values are slugified
#                     label: rdfs:label template ({Column} or {@Letter}); values kept literal
#                     class: one class or a list | type_by: [{column, map: {cell value: class}}] adds classes
#                     columns: {Column: prop | {prop, type: str|int|date|iri, iri: template, class: class}}
#                     fill_down: [columns repeated from the last non-empty cell (cell merges)]
#                     matrix: {from: first role column, to: last role column (optional), codes: {R: prop, ...}}
#   Columns without a header are addressed by letter: "@B".
#   Terms: kb: = engine core (location/provenance/text), {{PREFIX}}: = domain ontology of this workspace.
#
# Same item id on two sheets -> same IRI ("requirement/{id}"): values from both rows converge on one entity
# (useful when a proposal checklist repeats ids of the main sheet; use different iri prefixes if ids collide
# but mean different things).

source: "{{SOURCE_COMPLIANCE_MATRIX}}"
sheets:
  # Main requirements sheet.
  - sheet: "{{SHEET_REQUIREMENTS}}"
    header_row: {{HEADER_ROW_REQUIREMENTS}}
    require: ["{{COL_REQUIREMENT}}"]
    iri: "requirement/{{{COL_ID}}}"
    label: "{{{COL_ID}}} {{{COL_MACRO_REQUIREMENT}}}"
    class: {{PREFIX}}:ComplianceItem
    type_by:
      # Extra class by category. Use the exact cell values found in the file (kb-setup lists the distinct values
      # of the column in a subagent and shows them). Delete the block if there is no such column.
      - column: "{{COL_CATEGORY}}"
        map:
          "{{VAL_FUNCTIONAL}}": {{PREFIX}}:FunctionalRequirement
          "{{VAL_NON_FUNCTIONAL}}": {{PREFIX}}:NonFunctionalRequirement
      # Extra class by workstream (security and quality get their own classes for the saved queries).
      - column: "{{COL_WORKSTREAM}}"
        map:
          "{{VAL_WORKSTREAM_SECURITY}}": {{PREFIX}}:SecurityRequirement
          "{{VAL_WORKSTREAM_QUALITY}}": {{PREFIX}}:QualityRequirement
    columns:
      "{{COL_ID}}": kb:originalId
      "{{COL_CATEGORY}}": {{PREFIX}}:category
      "{{COL_DEPLOYMENT_SCOPE}}": {{PREFIX}}:deploymentScope      # e.g. general / on-premises / IaaS-PaaS / SaaS
      "{{COL_WORKSTREAM}}": {{PREFIX}}:workstream
      "{{COL_GROUPING}}": {{PREFIX}}:grouping
      "{{COL_MACRO_REQUIREMENT}}": {{PREFIX}}:macroRequirement
      "{{COL_REQUIREMENT}}": kb:excerpt                           # literal requirement text
      "{{COL_ELIGIBILITY}}": {{PREFIX}}:eligibility                # mandatory / important / desirable
      "{{COL_PRIORITY}}": {{PREFIX}}:priority
      "{{COL_COMPLIANCE}}": {{PREFIX}}:compliance                  # bidder answer column (often empty in the issued file)
      "{{COL_FULFILLMENT_MODE}}": {{PREFIX}}:fulfillmentMode
      "{{COL_EFFORT}}": {{PREFIX}}:effort
      "{{COL_BIDDER_COMMENT}}": {{PREFIX}}:bidderComment
      "{{COL_CLIENT_COMMENT}}": {{PREFIX}}:clientComment
      # Second answer round, if the matrix has numbered comment columns:
      # "{{COL_BIDDER_COMMENT_2}}": {{PREFIX}}:bidderComment
      # "{{COL_CLIENT_COMMENT_2}}": {{PREFIX}}:clientComment

  # Optional second sheet: proposal checklist that reuses the matrix layout with fewer columns.
  # Delete this block if the matrix has a single requirements sheet.
  - sheet: "{{SHEET_PROPOSAL_CHECKLIST}}"
    header_row: {{HEADER_ROW_PROPOSAL_CHECKLIST}}
    require: ["{{COL_REQUIREMENT}}"]
    iri: "requirement/{{{COL_ID}}}"
    label: "{{{COL_ID}}} {{{COL_REQUIREMENT}}}"
    class: {{PREFIX}}:ComplianceItem
    type_by:
      - column: "{{COL_CATEGORY}}"
        map:
          "{{VAL_FUNCTIONAL}}": {{PREFIX}}:FunctionalRequirement
          "{{VAL_NON_FUNCTIONAL}}": {{PREFIX}}:NonFunctionalRequirement
    columns:
      "{{COL_ID}}": kb:originalId
      "{{COL_CATEGORY}}": {{PREFIX}}:category
      "{{COL_WORKSTREAM}}": {{PREFIX}}:workstream
      "{{COL_MACRO_REQUIREMENT}}": {{PREFIX}}:macroRequirement
      "{{COL_REQUIREMENT}}": kb:excerpt
      "{{COL_ELIGIBILITY}}": {{PREFIX}}:eligibility
      "{{COL_COMPLIANCE}}": {{PREFIX}}:compliance
      "{{COL_CLIENT_COMMENT}}": {{PREFIX}}:clientComment
