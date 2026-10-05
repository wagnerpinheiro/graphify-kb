# SHACL shapes for the `rfi-proposal` domain ontology (kb-setup preset).
# Rendered by kb-setup at init into kb/ontology/{{PREFIX}}-shapes.ttl (the engine loads every kb/ontology/*shapes*.ttl
# after the core shapes). The core already checks source + location for core classes (kb:StatementShape),
# RACI assignments, milestones, terms, documents and wiki notes; these shapes cover the domain classes.
#
# sh:targetClass does not follow rdfs:subClassOf unless the subclass axioms are in the data graph, so every
# concrete class is listed explicitly.

@prefix {{PREFIX}}: <{{NAMESPACE}}> .
@prefix kb:      <http://kb.local/core#> .
@prefix sh:      <http://www.w3.org/ns/shacl#> .
@prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> .
@prefix xsd:     <http://www.w3.org/2001/XMLSchema#> .

# Every domain statement has a source and a location (same rule as the core StatementShape).
{{PREFIX}}:DomainStatementShape a sh:NodeShape ;
    sh:targetClass {{PREFIX}}:Requirement, {{PREFIX}}:FunctionalRequirement, {{PREFIX}}:NonFunctionalRequirement,
                   {{PREFIX}}:SecurityRequirement, {{PREFIX}}:QualityRequirement, {{PREFIX}}:ComplianceItem,
                   {{PREFIX}}:EvaluationCriterion, {{PREFIX}}:TransitionChecklistItem, kb:System, kb:Module ;
    sh:property [ sh:path kb:definedIn ; sh:minCount 1 ; sh:class kb:Source ;
                  sh:message "Domain statement without source (kb:definedIn -> Document/WikiNote)."@en ] ;
    sh:or ( [ sh:path kb:page ; sh:minCount 1 ] [ sh:path kb:originalId ; sh:minCount 1 ]
            [ sh:path kb:row ; sh:minCount 1 ] [ sh:path kb:sheet ; sh:minCount 1 ]
            [ sh:path kb:inSection ; sh:minCount 1 ] [ sh:path kb:order ; sh:minCount 1 ] ) ;
    sh:message "Domain statement without location (page, original id, row/sheet, section or order)."@en .

# A requirement must be identifiable: an id from the matrix or the literal requirement text.
{{PREFIX}}:RequirementShape a sh:NodeShape ;
    sh:targetClass {{PREFIX}}:Requirement, {{PREFIX}}:FunctionalRequirement, {{PREFIX}}:NonFunctionalRequirement,
                   {{PREFIX}}:SecurityRequirement, {{PREFIX}}:QualityRequirement, {{PREFIX}}:ComplianceItem ;
    sh:or ( [ sh:path kb:originalId ; sh:minCount 1 ] [ sh:path kb:excerpt ; sh:minCount 1 ] ) ;
    sh:message "Requirement without kb:originalId or kb:excerpt."@en .

# Compliance items come from a spreadsheet: they must be citable as "file, sheet X, row N".
{{PREFIX}}:ComplianceItemShape a sh:NodeShape ;
    sh:targetClass {{PREFIX}}:ComplianceItem ;
    sh:property [ sh:path kb:sheet ; sh:minCount 1 ;
                  sh:message "Compliance item without sheet (kb:sheet)."@en ] ;
    sh:property [ sh:path kb:row ; sh:minCount 1 ; sh:datatype xsd:integer ; sh:minInclusive 1 ;
                  sh:message "Compliance item without spreadsheet row (kb:row)."@en ] .
# No sh:maxCount on {{PREFIX}}:compliance: the same item id may appear in two sheets of the same matrix
# (e.g. requirements sheet + proposal checklist sheet) and both rows converge on one IRI.

# Transition checklist items: identifiable and citable.
{{PREFIX}}:TransitionChecklistItemShape a sh:NodeShape ;
    sh:targetClass {{PREFIX}}:TransitionChecklistItem ;
    sh:or ( [ sh:path kb:originalId ; sh:minCount 1 ] [ sh:path kb:excerpt ; sh:minCount 1 ] ) ;
    sh:message "Transition checklist item without kb:originalId or kb:excerpt."@en .

# Evaluation criteria need a human-readable label.
{{PREFIX}}:EvaluationCriterionShape a sh:NodeShape ;
    sh:targetClass {{PREFIX}}:EvaluationCriterion ;
    sh:property [ sh:path rdfs:label ; sh:minCount 1 ;
                  sh:message "Evaluation criterion without label."@en ] .
