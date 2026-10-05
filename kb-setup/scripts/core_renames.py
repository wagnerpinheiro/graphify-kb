"""Rename map of core ontology terms: v1 (Portuguese, prefix rfi:) -> v2 core (English, prefix kb:).
Used by the engine refactor and by `kb.py migrate` when adopting a v1 workspace."""

CLASSES = {
    "Fonte": "Source", "Documento": "Document", "NotaWiki": "WikiNote", "Secao": "Section", "Pessoa": "Person",
    "Marco": "Milestone", "Prazo": "Deadline", "Fato": "Fact", "Termo": "Term", "Decisao": "Decision",
    "Hipotese": "Hypothesis", "Atividade": "Activity", "Papel": "Role", "AtribuicaoRACI": "RACIAssignment",
    "Entregavel": "Deliverable", "Processo": "Process", "Sistema": "System", "Modulo": "Module",
}
PROPERTIES = {
    "definidoEm": "definedIn", "naSecao": "inSection", "secaoPai": "parentSection", "pagina": "page", "aba": "sheet",
    "linha": "row", "trecho": "excerpt", "idOriginal": "originalId", "numero": "number", "ordem": "order",
    "totalLinhas": "rowCount", "camada": "layer", "metodoExtracao": "extractionMethod", "fonte": "graphSource",
    "familia": "family", "versao": "version", "chaveVersao": "versionKey", "sobrepoe": "overrides",
    "sobrepoeRef": "overridesRef", "substitui": "replaces", "headerInferido": "headerInferred",
    "revisarACada": "reviewEvery", "revisaoVencida": "reviewOverdue", "diasAtraso": "daysOverdue",
    "referencia": "references", "referenciaTexto": "referenceText", "mencionaId": "mentionsId", "prazo": "date",
    "duracao": "duration", "tema": "topic", "sobreTema": "aboutTopic", "valor": "value",
    "tipoHipotese": "hypothesisKind", "atividade": "activity", "papel": "role", "codigoRACI": "raciCode",
    "responsavel": "responsible", "aprovador": "accountable", "consultado": "consulted", "informado": "informed",
    "entregavel": "deliverable", "descricao": "description", "fase": "phase", "sistema": "system",
    "exige": "requires", "atende": "satisfies", "dependeDe": "dependsOn", "contradiz": "contradicts",
}
ALL = {**CLASSES, **PROPERTIES}

# config.yaml keys (v1 Portuguese -> v2 English)
CONFIG_KEYS = {"temas": "topics", "fatos": "facts", "anexos": "attachments"}
TOPIC_KEYS = {"padrao": "pattern"}
FACT_KEYS = {"padrao": "context", "valor": "value", "normalizar": "normalize", "unidade": "unit", "minimo": "min",
             "antes": "before", "depois": "after"}
FACT_NORMALIZE = {"contar": "count", "contar_distintos": "count_distinct", "meses": "months", "numero": "number",
                  "siglas": "acronyms"}
ATTACHMENT_KEYS = {"titulo": "title", "arquivo": "file", "numeros": "numbers"}
