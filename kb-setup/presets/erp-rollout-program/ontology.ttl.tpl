# Domain ontology for a multi-country ERP template rollout program — preset `erp-rollout-program` (kb-setup).
# Rendered by kb-setup at init into kb/ontology/{{PREFIX}}.ttl. DRAFT until the user approves it (checkpoint).
#
# Placeholders (filled at init, see preset.md):
#   {{PREFIX}}     domain prefix chosen at init (e.g. erp)
#   {{NAMESPACE}}  domain namespace (e.g. http://kb.local/<workspace-slug>/ont#)
#   {{CLIENT}}     display name of the organization running the program (only in labels/comments)
#   {{PROGRAM}}    display name of the rollout program
#   {{DATE}}       creation date (YYYY-MM-DD)
#
# Rules:
# - Core terms (sources, sections, provenance, location, RACI, deliverables, facts, deadlines, topics,
#   kb:System, kb:Module) come from the engine core ontology (prefix kb:,
#   ~/.claude/skills/kb-setup/assets/core/kb-core.ttl). Never redeclare them here.
# - This file only adds domain classes/properties. Prefer extending core classes
#   ({{PREFIX}}:StakeholderRole ⊑ kb:Role, {{PREFIX}}:SatelliteApplication ⊑ {{PREFIX}}:ApplicationSystem ⊑ kb:System).
# - pyoxigraph does no RDFS inference: saved queries must use concrete classes (or a VALUES list of them).
# - Remove what the workspace does not need; add what the material shows (e.g. a new backlog-item kind) before
#   approval. Renaming instance examples in comments below is expected — they are illustrative, not required.

@prefix {{PREFIX}}: <{{NAMESPACE}}> .
@prefix kb:      <http://kb.local/core#> .
@prefix rdf:     <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> .
@prefix owl:     <http://www.w3.org/2002/07/owl#> .
@prefix xsd:     <http://www.w3.org/2001/XMLSchema#> .
@prefix dcterms: <http://purl.org/dc/terms/> .

<{{NAMESPACE}}> a owl:Ontology ;
    rdfs:label "{{PROGRAM}} — ERP rollout program ontology"@en ;
    rdfs:comment "Domain ontology for the {{PROGRAM}} program at {{CLIENT}}. Extends the kb-setup core (kb:)."@en ;
    owl:imports <http://kb.local/core> ;
    dcterms:created "{{DATE}}"^^xsd:date ;
    owl:versionInfo "0.1 (draft, preset erp-rollout-program)" .

# ------------------------------------------------------------------ program structure

{{PREFIX}}:SubProgram a owl:Class ;
    rdfs:label "Sub-program"@en, "Sub-programa"@pt ;
    rdfs:comment "One of the delivery sub-programs the rollout is organized into (e.g. Back Office, Front Office, plus one sub-program per business line or per group of satellite applications), each with its own projects."@en .

{{PREFIX}}:ProgramPhase a owl:Class ;
    rdfs:label "Program phase"@en, "Fase do programa"@pt ;
    rdfs:comment "A stage of the program's delivery methodology (typical lifecycle: Discover, Mobilize, Design | fit-or-gap, Build, Test, Train, Migrate, Go-Live, Support, Hypercare). Order via kb:order."@en .

{{PREFIX}}:DesignSubPhase a owl:Class ; rdfs:subClassOf {{PREFIX}}:ProgramPhase ;
    rdfs:label "Design sub-phase"@en, "Subfase de design"@pt ;
    rdfs:comment "Sub-phase of the Design | fit-or-gap phase. The source engagement used readiness-assessment / template-fitment / local-adoption named steps; rename to match the adopting program's own methodology naming."@en .

{{PREFIX}}:GovernanceBody a owl:Class ;
    rdfs:label "Governance body"@en, "Instância de governança"@pt ;
    rdfs:comment "A decision-making forum in the program's governance hierarchy (e.g. a Steering Committee, a Design Authority Board that arbitrates local-vs-template gaps, a Senior Working Group, Program/Sub-program committees)."@en .

{{PREFIX}}:StakeholderRole a owl:Class ; rdfs:subClassOf kb:Role ;
    rdfs:label "Stakeholder role"@en, "Papel de stakeholder"@pt ;
    rdfs:comment "A program delivery role archetype (e.g. a technology/analytics role, a process-and-systems-owner role per function, a subject-matter-expert role, a key-user role). Rename to the adopting program's own role names."@en .

{{PREFIX}}:Vendor a owl:Class ;
    rdfs:label "Vendor"@en, "Fornecedor / parceiro"@pt ;
    rdfs:comment "A delivery/implementation partner engaged on the program."@en .

# ------------------------------------------------------------------ scope: processes, systems, platforms

{{PREFIX}}:FunctionalDomain a owl:Class ; rdfs:subClassOf kb:Process ;
    rdfs:label "Functional domain"@en, "Domínio funcional"@pt ;
    rdfs:comment "A business-process area in the functional scope maps (e.g. order-to-cash, procure-to-pay, record-to-report, trade/execution, finance)."@en .

{{PREFIX}}:ApplicationSystem a owl:Class ; rdfs:subClassOf kb:System ;
    rdfs:label "Application system"@en, "Sistema aplicativo"@pt ;
    rdfs:comment "A named application in the program's landscape (the new core ERP template and the legacy/peripheral systems it replaces or integrates with), typed by scope (e.g. front office / back office / satellite)."@en .

{{PREFIX}}:SatelliteApplication a owl:Class ; rdfs:subClassOf {{PREFIX}}:ApplicationSystem ;
    rdfs:label "Satellite application"@en, "Aplicação satélite"@pt ;
    rdfs:comment "A satellite/peripheral application tracked separately for integration/migration status."@en .

{{PREFIX}}:Platform a owl:Class ;
    rdfs:label "Platform"@en, "Plataforma"@pt ;
    rdfs:comment "A business line, region or commodity used to scope the program's work (rename the instances to the adopting organization's own segmentation)."@en .

{{PREFIX}}:LegalEntity a owl:Class ;
    rdfs:label "Legal entity"@en, "Entidade legal"@pt ;
    rdfs:comment "A legal entity (company code) explicitly listed as in-scope or out-of-scope for the rollout."@en .

{{PREFIX}}:TestCycle a owl:Class ;
    rdfs:label "Test cycle"@en, "Ciclo de teste"@pt ;
    rdfs:comment "A named test event/milestone (e.g. non-regression test, integration test, system/user acceptance test, data test load)."@en .

# ------------------------------------------------------------------ delivery backlog and tracking

{{PREFIX}}:Workshop a owl:Class ; rdfs:subClassOf kb:Activity ;
    rdfs:label "Workshop"@en, "Workshop"@pt ;
    rdfs:comment "A scheduled session where the template/core-model processes are presented and local stakeholders raise gaps or draft backlog items."@en .

{{PREFIX}}:Feature a owl:Class ; rdfs:subClassOf kb:Deliverable ;
    rdfs:label "Feature"@en, "Feature"@pt ;
    rdfs:comment "A grouping of backlog items delivered/estimated as a unit (e.g. a wave of features)."@en .

{{PREFIX}}:PBI a owl:Class ; rdfs:subClassOf kb:Deliverable ;
    rdfs:label "Product backlog item (PBI)"@en, "Item de backlog (PBI)"@pt ;
    rdfs:comment "A unit of requirement/feature backlog, tracked with a status (e.g. ready for refinement, committed, done). Ticket id via kb:originalId."@en .

{{PREFIX}}:GAP a owl:Class ;
    rdfs:label "Gap"@en, "Gap"@pt ;
    rdfs:comment "A documented deviation between a local requirement and the global template/core model, routed to governance for arbitration. Status via {{PREFIX}}:status."@en .

{{PREFIX}}:Risk a owl:Class ;
    rdfs:label "Risk"@en, "Risco"@pt ;
    rdfs:comment "A tracked program risk (ticket id via kb:originalId) with stream, assignee, due date, impact and probability."@en .

{{PREFIX}}:ChangeImpact a owl:Class ;
    rdfs:label "Change impact"@en, "Impacto de mudança"@pt ;
    rdfs:comment "A mapped organizational/process impact of the rollout on a stream or audience. Status via {{PREFIX}}:status (e.g. mapped / reviewed / cancelled)."@en .

# ------------------------------------------------------------------ domain properties

{{PREFIX}}:inSubProgram a owl:ObjectProperty ; rdfs:range {{PREFIX}}:SubProgram ;
    rdfs:label "in sub-program"@en, "no sub-programa"@pt .

{{PREFIX}}:partOfFeature a owl:ObjectProperty ; rdfs:domain {{PREFIX}}:PBI ; rdfs:range {{PREFIX}}:Feature ;
    rdfs:label "part of feature"@en, "parte da feature"@pt .

{{PREFIX}}:status a owl:DatatypeProperty ;
    rdfs:label "status"@en, "status"@pt ;
    rdfs:comment "Generic status as written in the source (GAP status, PBI status, change-impact status, risk status)."@en .

{{PREFIX}}:stream a owl:DatatypeProperty ;
    rdfs:label "stream"@en, "frente/stream"@pt ;
    rdfs:comment "Work stream or functional track a workshop, GAP, risk or change impact belongs to."@en .
