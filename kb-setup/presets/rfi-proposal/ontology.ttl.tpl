# Domain ontology for responding to an RFI / RFP / tender — preset `rfi-proposal` (kb-setup).
# Rendered by kb-setup at init into kb/ontology/{{PREFIX}}.ttl. DRAFT until the user approves it (checkpoint).
#
# Placeholders (filled at init, see preset.md):
#   {{PREFIX}}     domain prefix chosen at init (e.g. prop)
#   {{NAMESPACE}}  domain namespace (e.g. http://kb.local/<workspace-slug>/ont#)
#   {{CLIENT}}     display name of the issuing organization (only in labels/comments)
#   {{PROGRAM}}    display name of the program / bid being answered
#   {{DATE}}       creation date (YYYY-MM-DD)
#
# Rules:
# - Core terms (sources, sections, provenance, location, RACI, deliverables, facts, deadlines, topics) come from the
#   engine core ontology (prefix kb:, ~/.claude/skills/kb-setup/assets/core/kb-core.ttl). Never redeclare them here.
# - This file only adds domain classes/properties. Prefer extending core classes (ContractClause ⊑ kb:Section).
# - pyoxigraph does no RDFS inference: saved queries must use concrete classes (or a VALUES list of them).
# - Remove what the workspace does not need; add what the material shows (e.g. new requirement kinds) before approval.

@prefix {{PREFIX}}: <{{NAMESPACE}}> .
@prefix kb:      <http://kb.local/core#> .
@prefix rdf:     <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> .
@prefix owl:     <http://www.w3.org/2002/07/owl#> .
@prefix xsd:     <http://www.w3.org/2001/XMLSchema#> .
@prefix dcterms: <http://purl.org/dc/terms/> .
@prefix skos:    <http://www.w3.org/2004/02/skos/core#> .

<{{NAMESPACE}}> a owl:Ontology ;
    rdfs:label "{{PROGRAM}} — proposal knowledge base ontology"@en ;
    rdfs:comment "Domain ontology for answering the {{CLIENT}} request ({{PROGRAM}}). Extends the kb-setup core (kb:)."@en ;
    owl:imports <http://kb.local/core> ;
    dcterms:created "{{DATE}}"^^xsd:date ;
    owl:versionInfo "0.1 (draft, preset rfi-proposal)" .

# ------------------------------------------------------------------ requirements and compliance

{{PREFIX}}:Requirement a owl:Class ;
    rdfs:label "Requirement"@en, "Requisito"@pt, "Requisito"@es ;
    rdfs:comment "Something the issuing organization ({{CLIENT}}) requires from the bidder: a row of a requirement/compliance matrix or a requirement stated in the request document."@en .

{{PREFIX}}:FunctionalRequirement a owl:Class ; rdfs:subClassOf {{PREFIX}}:Requirement ;
    rdfs:label "Functional requirement"@en, "Requisito funcional"@pt, "Requisito funcional"@es .

{{PREFIX}}:NonFunctionalRequirement a owl:Class ; rdfs:subClassOf {{PREFIX}}:Requirement ;
    rdfs:label "Non-functional requirement"@en, "Requisito não funcional"@pt, "Requisito no funcional"@es .

{{PREFIX}}:SecurityRequirement a owl:Class ; rdfs:subClassOf {{PREFIX}}:Requirement ;
    rdfs:label "Information security requirement"@en, "Requisito de segurança da informação"@pt, "Requisito de seguridad de la información"@es .

{{PREFIX}}:QualityRequirement a owl:Class ; rdfs:subClassOf {{PREFIX}}:Requirement ;
    rdfs:label "Quality and testing requirement"@en, "Requisito de qualidade e testes"@pt, "Requisito de calidad y pruebas"@es .

{{PREFIX}}:ComplianceItem a owl:Class ; rdfs:subClassOf {{PREFIX}}:Requirement ;
    rdfs:label "Compliance matrix item"@en, "Item da matriz de conformidade"@pt, "Ítem de la matriz de cumplimiento"@es ;
    rdfs:comment "Row of the compliance / requirements matrix that the bidder must answer (compliance, fulfillment mode, effort, comments). Extracted deterministically from the spreadsheet mapping."@en .

{{PREFIX}}:EvaluationCriterion a owl:Class ;
    rdfs:label "Evaluation criterion"@en, "Critério de avaliação"@pt, "Criterio de evaluación"@es ;
    rdfs:comment "Criterion used by the issuer to score or qualify proposals (technical, commercial, eligibility)."@en .

# ------------------------------------------------------------------ transition, contract, systems

{{PREFIX}}:TransitionChecklistItem a owl:Class ;
    rdfs:label "Transition checklist item"@en, "Item do checklist de transição"@pt, "Ítem del checklist de transición"@es ;
    rdfs:comment "Item of the project-to-operations (support / run) transition or knowledge-transfer checklist."@en .

{{PREFIX}}:ContractClause a owl:Class ; rdfs:subClassOf kb:Section ;
    rdfs:label "Contract clause"@en, "Cláusula contratual"@pt, "Cláusula contractual"@es ;
    rdfs:comment "Section of a contractual instrument (general or specific terms and conditions). Assigned through config `section_class` (glob over the file path)."@en .

{{PREFIX}}:ProposalTemplateSection a owl:Class ; rdfs:subClassOf kb:Section ;
    rdfs:label "Proposal template section"@en, "Seção do modelo de proposta"@pt, "Sección de la plantilla de propuesta"@es ;
    rdfs:comment "Section of the issuer's proposal template (the structure the technical/commercial proposal must follow). Assigned through config `section_class`."@en .

# Systems/modules in scope use the core terms kb:System, kb:Module and kb:system (engine >= 2.0.0).

# ------------------------------------------------------------------ compliance matrix columns

{{PREFIX}}:category a owl:DatatypeProperty ;
    rdfs:label "category"@en, "categoria"@pt, "categoría"@es ;
    rdfs:comment "Requirement category as written in the matrix (e.g. functional / non-functional)."@en .

{{PREFIX}}:deploymentScope a owl:DatatypeProperty ;
    rdfs:label "deployment scope"@en, "escopo de implantação"@pt, "alcance de despliegue"@es ;
    rdfs:comment "Matrix section by deployment model (e.g. general, on-premises, IaaS/PaaS, SaaS)."@en .

{{PREFIX}}:workstream a owl:DatatypeProperty ;
    rdfs:label "workstream"@en, "frente"@pt, "frente de trabajo"@es ;
    rdfs:comment "Work front / tower the requirement belongs to (e.g. architecture, security, quality, infrastructure, support)."@en .

{{PREFIX}}:grouping a owl:DatatypeProperty ;
    rdfs:label "grouping"@en, "agrupador"@pt, "agrupador"@es .

{{PREFIX}}:macroRequirement a owl:DatatypeProperty ;
    rdfs:label "macro requirement"@en, "macro requisito"@pt, "macro requisito"@es .

{{PREFIX}}:eligibility a owl:DatatypeProperty ;
    rdfs:label "eligibility / criticality"@en, "elegibilidade"@pt, "elegibilidad"@es ;
    rdfs:comment "How mandatory the requirement is (e.g. mandatory / important / desirable)."@en .

{{PREFIX}}:compliance a owl:DatatypeProperty ;
    rdfs:label "compliance (answer)"@en, "conformidade (resposta)"@pt, "cumplimiento (respuesta)"@es ;
    rdfs:comment "Bidder answer: complies / partially / does not comply (wording as in the matrix)."@en .

{{PREFIX}}:fulfillmentMode a owl:DatatypeProperty ;
    rdfs:label "fulfillment mode"@en, "modo de atendimento"@pt, "modo de cumplimiento"@es ;
    rdfs:comment "How the requirement is met (native, configuration, customization, third party, roadmap...)."@en .

{{PREFIX}}:effort a owl:DatatypeProperty ;
    rdfs:label "effort"@en, "esforço"@pt, "esfuerzo"@es .

{{PREFIX}}:bidderComment a owl:DatatypeProperty ;
    rdfs:label "bidder comment"@en, "comentário do proponente"@pt, "comentario del oferente"@es .

{{PREFIX}}:clientComment a owl:DatatypeProperty ;
    rdfs:label "client comment"@en, "comentário do cliente"@pt, "comentario del cliente"@es ;
    rdfs:comment "Comment column filled by the issuing organization ({{CLIENT}})."@en .

{{PREFIX}}:priority a owl:DatatypeProperty ;
    rdfs:label "priority"@en, "prioridade"@pt, "prioridad"@es .

{{PREFIX}}:weight a owl:DatatypeProperty ;
    rdfs:label "weight"@en, "peso"@pt, "peso"@es ;
    rdfs:comment "Weight or score of an evaluation criterion, as stated by the issuer."@en .

# ------------------------------------------------------------------ RACI / project governance columns
# Core already has kb:Activity, kb:Role, kb:RACIAssignment, kb:Deliverable, kb:phase, kb:order, kb:description,
# kb:deliverable and the R/A/C/I properties. Only the extra columns live here.

{{PREFIX}}:phasePMO a owl:DatatypeProperty ;
    rdfs:label "PMO phase"@en, "fase PMO"@pt, "fase PMO"@es ;
    rdfs:comment "Project-management phase, when the RACI matrix has both an IT phase (kb:phase) and a PMO phase."@en .

{{PREFIX}}:deliverableType a owl:DatatypeProperty ;
    rdfs:label "deliverable type"@en, "tipo de entregável"@pt, "tipo de entregable"@es .

# ------------------------------------------------------------------ transition checklist columns

{{PREFIX}}:applicable a owl:DatatypeProperty ;
    rdfs:label "applicable"@en, "aplicável"@pt, "aplicable"@es .

{{PREFIX}}:status a owl:DatatypeProperty ;
    rdfs:label "status"@en, "status"@pt, "estado"@es .

{{PREFIX}}:storageLocation a owl:DatatypeProperty ;
    rdfs:label "file / storage location"@en, "arquivo / local de armazenamento"@pt, "archivo / ubicación de almacenamiento"@es .

{{PREFIX}}:nonConformityType a owl:DatatypeProperty ;
    rdfs:label "non-conformity type"@en, "tipo de não conformidade"@pt, "tipo de no conformidad"@es .
