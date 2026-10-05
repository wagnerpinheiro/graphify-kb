# SHACL shapes for the erp-rollout-program domain ontology (kb-setup preset). Rendered by kb-setup at init into
# kb/ontology/{{PREFIX}}-shapes.ttl (the engine loads every kb/ontology/*shapes*.ttl after the core shapes).
# sh:targetClass does not follow rdfs:subClassOf unless the subclass axioms are in the data graph, so every
# concrete class is listed explicitly.

@prefix {{PREFIX}}: <{{NAMESPACE}}> .
@prefix kb:      <http://kb.local/core#> .
@prefix sh:      <http://www.w3.org/ns/shacl#> .

# Every domain statement has a source and a location (same rule as the core StatementShape).
{{PREFIX}}:DomainStatementShape a sh:NodeShape ;
    sh:targetClass {{PREFIX}}:SubProgram, {{PREFIX}}:ProgramPhase, {{PREFIX}}:DesignSubPhase, {{PREFIX}}:GovernanceBody,
                   {{PREFIX}}:StakeholderRole, {{PREFIX}}:Vendor, {{PREFIX}}:FunctionalDomain, {{PREFIX}}:ApplicationSystem,
                   {{PREFIX}}:SatelliteApplication, {{PREFIX}}:Platform, {{PREFIX}}:LegalEntity, {{PREFIX}}:TestCycle,
                   {{PREFIX}}:Workshop, {{PREFIX}}:Feature, {{PREFIX}}:PBI, {{PREFIX}}:GAP, {{PREFIX}}:Risk, {{PREFIX}}:ChangeImpact ;
    sh:property [ sh:path kb:definedIn ; sh:minCount 1 ; sh:class kb:Source ;
                  sh:message "Domain statement without source (kb:definedIn -> Document/WikiNote)."@en ] ;
    sh:or ( [ sh:path kb:page ; sh:minCount 1 ] [ sh:path kb:originalId ; sh:minCount 1 ]
            [ sh:path kb:row ; sh:minCount 1 ] [ sh:path kb:sheet ; sh:minCount 1 ]
            [ sh:path kb:inSection ; sh:minCount 1 ] [ sh:path kb:order ; sh:minCount 1 ] ) ;
    sh:message "Domain statement without location (page, original id, row/sheet, section or order)."@en .
