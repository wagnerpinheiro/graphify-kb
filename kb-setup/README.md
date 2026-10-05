# kb-setup: base de conhecimento local por workspace (graph-RAG + graphify)

## O que é

`kb-setup` é uma meta-skill do Claude Code. Ela cria, adota, atualiza e avalia uma **base de conhecimento (KB) local
por workspace de documentos** (RFI/RFP, contratos, pesquisa, documentação de projeto). A KB é um graph-RAG
determinístico em **RDF/OWL + SHACL + SPARQL**: sem servidor, sem Docker, sem MCP e sem chave de API. Os arquivos ficam
organizados nas pastas Zettelkasten `raw/` (fontes oficiais), `wiki/` (notas do time), `kb/` (ontologia, mapeamentos,
configuração) e `docs/` (entregáveis, nunca indexados). Cada workspace ganha uma skill `/kb` para consulta e
manutenção e, se você aprovar, algumas task skills.

O **graphify é obrigatório** e vem **deste fork** (`graphify-kb`). A kb-setup e o graphify são versionados juntos neste
repositório. Toda execução de `init`, `adopt` e `update` instala ou confere o graphify e constrói o grafo sobre
código + `docs/` + `wiki/`. Documentos de `raw/` só entram com autorização por documento (`raw/.graphifyignore`).

```
Claude Code ──► skill kb-setup (~/.claude/skills/kb-setup → <fork>/kb-setup)
                   │
                   ├─► engine  scripts/kb.py   (PEP 723, roda com uv; nada instalado no workspace)
                   │      └─► workspace/  raw/ wiki/ kb/ docs/  +  /kb skill  +  CLAUDE.md
                   │
                   └─► graphify (uv tool instalado a partir deste fork)
                          └─► workspace/graphify-out/  (grafo exploratório; fora do git)
```

## Pré-requisitos

- [`uv`](https://docs.astral.sh/uv/) (obrigatório; ele também fornece o Python que o engine usa)
- Python ≥ 3.10
- Claude Code
- git
- Opcional: OneDrive/Teams, para compartilhar o workspace com o time (`references/onedrive-teams-sync.md`)

## Instalação

Os comandos usam `REPO` como o caminho do clone. Ajuste a variável se clonar em outro lugar.

1. **Clonar o fork**

   ```bash
   REPO=~/workspaces/github/graphify-kb
   git clone git@github.com:wagnerpinheiro/graphify-kb.git "$REPO"
   ```

2. **Instalar o graphify do fork** como uv tool editável (um `git pull` no fork atualiza o graphify junto) e a skill
   global `/graphify`:

   ```bash
   uv tool install --force -e "$REPO"
   graphify install --platform claude
   ```

   `--force` substitui um `graphifyy` que já tenha sido instalado do PyPI.

   **Fallback sem clone** (para quem só precisa do graphify): instale direto do GitHub. Troque `@v8` por um commit ou
   tag para fixar a versão.

   ```bash
   uv tool install --force "git+https://github.com/wagnerpinheiro/graphify-kb@v8"
   graphify install --platform claude
   ```

   Para rodar um comando avulso sem instalar: `uvx --from "git+https://github.com/wagnerpinheiro/graphify-kb@v8" graphify --version`.
   Isso não substitui a instalação: a skill `/graphify` procura o uv tool `graphifyy` e, se ele não existir, instala a
   versão do PyPI, que não é a deste fork.

3. **Ligar a skill** por symlink. Se já existir uma cópia local em `~/.claude/skills/kb-setup`, mova-a para **fora**
   de `~/.claude/skills/` antes, senão o Claude Code carrega duas skills `kb-setup`:

   ```bash
   mkdir -p ~/.claude/skills
   [ -e ~/.claude/skills/kb-setup ] && mv ~/.claude/skills/kb-setup ~/kb-setup.bak-$(date +%Y%m%d)
   ln -s "$REPO/kb-setup" ~/.claude/skills/kb-setup
   ```

4. **Verificar**

   ```bash
   graphify --version                                   # graphify 0.9.76
   uv run ~/.claude/skills/kb-setup/scripts/kb.py --version   # kb.py engine 2.0.0
   uv run ~/.claude/skills/kb-setup/scripts/kb.py --help
   ```

   Depois abra uma **nova** sessão do Claude Code e confira que a skill `kb-setup` aparece na lista de skills
   (por exemplo, digitando `/kb-setup`).

## Execução inicial em um workspace novo

1. **Criar ou abrir a pasta do workspace e iniciar o Claude Code nela.** Os documentos podem já estar lá ou chegar
   depois.

   ```bash
   mkdir -p ~/workspaces/minha-kb && cd ~/workspaces/minha-kb
   claude
   ```

2. **Disparar a skill** com `/kb-setup init` ou com um pedido em linguagem natural, por exemplo
   "set up a KB for this folder" ou "monte uma base de conhecimento para esta pasta".

3. **O que acontece em cada fase.** Os itens marcados com ✋ são checkpoints em que você aprova.
   1. **Discovery:** só comandos de leitura. A skill olha a pasta (nomes, tamanhos, formatos, duplicatas), git ou
      OneDrive, as políticas gerenciadas, `uv`/Python e o graphify: versão esperada e origem no fork. Se faltar
      graphify ou a versão divergir, ela avisa e instala ou atualiza antes de seguir. O conteúdo dos documentos não é
      aberto nessa fase.
   2. ✋ **Entrevista:** rodadas de até 4 perguntas, com o padrão recomendado em primeiro: propósito e preset, idioma,
      versionamento, confidencialidade (o que o Claude pode ler por inteiro), precedência de versões, período de
      revisão de notas, escopo do graphify (código + `docs/` + `wiki/`, e quais documentos de `raw/` liberar) e task
      skills.
   3. **Scaffold Zettelkasten:** `kb.py scaffold` cria `raw/ wiki/ kb/ docs/`, `kb/config.yaml` e o bloco do
      `.gitignore`. Em seguida a skill gera `README.md`, `CLAUDE.md`, `.claude/skills/kb/SKILL.md` e `kb/SETUP.md`. Num
      workspace vazio, ela cria notas de exemplo e guia a primeira nota permanente.
   4. ✋ **Ontologia e preset** (se houver documentos): a skill propõe um preset de `presets/` (`rfi-proposal`,
      `erp-rollout-program`) ou só o core, e monta ontologia de domínio, shapes, mapeamentos de planilhas, regras de
      tópicos/fatos e queries salvas. Você aprova antes do build final.
   5. **`KB update`:** unzip, conversão PDF/DOCX/XLSX → Markdown com marcadores de página, extração determinística,
      descrição de imagens em subagentes, validação SHACL e wiki gerada.
   6. **Build do graphify:** escreve `.graphifyignore` (raiz) e `raw/.graphifyignore`, roda `graphify update .`
      (estrutural, sem LLM) e, se houver conteúdo em `docs/`, `wiki/` ou documentos autorizados, `/graphify .` num
      subagente.
   7. ✋ **Task skills:** a skill propõe de 2 a 4 (matriz de conformidade, RACI, seção de proposta etc.) e só gera as
      que você aprovar.
   8. **Fechamento:** checklist de prontidão, decisões e autorizações registradas em `kb/SETUP.md`, resumo e
      sugestões. Ela também oferece rodar um `eval` de baseline.

4. **Resultado esperado**

   ```
   minha-kb/
   ├── raw/                     fontes oficiais (+ .md convertidos ao lado dos binários) e raw/.graphifyignore
   ├── wiki/                    notas do time (fleeting / literature / permanent)
   ├── docs/                    entregáveis (nunca indexados)
   ├── kb/
   │   ├── config.yaml          engine_version, ontologia, fontes, graphify.version/source/scope
   │   ├── SETUP.md             decisões, autorizações, versão e origem do graphify
   │   ├── IMPROVEMENTS.md      backlog de melhorias
   │   └── ontology/ mappings/ queries/ evals/ wiki/
   ├── .claude/skills/kb/       skill /kb do workspace (+ task skills aprovadas)
   ├── CLAUDE.md                regras da KB e de coexistência com o graphify
   ├── README.md                método do workspace
   ├── .graphifyignore          exclui kb/ e .claude/ do graphify
   ├── .gitignore               bloco kb-setup (binários, kb/.lock, graphify-out/)
   └── graphify-out/            graph.json, GRAPH_REPORT.md, graph.html (fora do git)
   ```

5. **Primeiros usos**
   - Perguntas sobre os documentos e as notas: `/kb <pergunta>`. As respostas vêm com citação (`arquivo, p.N` ou
     `arquivo, aba X, linha N`) e aplicam a precedência entre fontes.
   - Novos documentos: coloque-os em `raw/` e rode `/kb update`. Só o que mudou é processado, e o graphify é
     atualizado junto.
   - Liberar um documento de `raw/` para o graphify: registre a autorização em `kb/SETUP.md`, tire a linha dele de
     `raw/.graphifyignore` e rode `/kb update` (ou `/kb-setup graphify`).
   - Exploração (temas, comunidades, caminhos entre conceitos) ou código: `/graphify query "..."`.

## Outros modos

| Modo | Para quê | Referência |
|---|---|---|
| `adopt` | migrar uma KB existente (layout v1 ou engine local) | [`references/migration.md`](references/migration.md) |
| `update` | atualização incremental da KB e do graphify depois de mudanças em `raw/` ou `wiki/` | [`references/improvements.md`](references/improvements.md) |
| `upgrade` | o engine ou o graphify do fork mudou de versão: changelog, migração e rebuild | [`references/migration.md`](references/migration.md) |
| `graphify` | reinstalar, conferir versão, mudar escopo ou reconstruir o graphify | [`references/graphify.md`](references/graphify.md) |
| `eval` | tokens, tempo e qualidade: sem KB × só graphify × KB + graphify | [`references/evals.md`](references/evals.md) |
| `status` | saúde do engine, da versão, das políticas e do graphify | [`SKILL.md`](SKILL.md) |
| `review` | analisar o uso e aplicar melhorias aprovadas do backlog | [`references/improvements.md`](references/improvements.md) |
| `preset` | extrair um preset genérico de um workspace | [`references/presets.md`](references/presets.md) |

## Atualizar a skill

```bash
git -C "$REPO" pull
```

O symlink já aponta para a versão nova, e o graphify editável também é atualizado. Se a versão do graphify mudou,
rode `graphify install --platform claude` para atualizar a skill `/graphify`. Depois, em cada workspace, rode
`/kb-setup upgrade`: ele compara `engine_version` e `graphify.version` em `kb/config.yaml`, mostra o changelog e
reconstrói o que for preciso, sempre com confirmação.

## Confidencialidade (resumo)

- Leitura de conteúdo de documentos (várias páginas, Grep em `raw/`, imagens, extração, graphify) só em
  **subagentes**, que devolvem resultados compactos com citação. Texto de cliente não entra no contexto principal.
- Leitura integral por LLM (extração de prosa, graphify sobre `raw/`, baseline de eval) só com **autorização por
  documento**, registrada em `kb/SETUP.md`. Para o graphify, essa autorização se reflete em `raw/.graphifyignore`.
- **Nunca** com `GEMINI_API_KEY`/`GOOGLE_API_KEY` definidas: com elas, o graphify envia conteúdo ao Google.
  Também ficam proibidos `graphify add`, `graphify extract` com backend externo, `--mcp`, `--neo4j`, `--watch`,
  `graphify hook install` e `graphify claude install` (este cria um hook).
- `graphify-out/` (raiz e qualquer `*/graphify-out/` de cache) fica fora do git e fora da KB.

## Troubleshooting

- **Faltam wheels para o Python padrão** (lição L1): uma dependência pode não ter wheel para o Python mais novo.
  O engine fixa as dependências por PEP 723 + `kb.py.lock`; se o `uv run` falhar ao instalar, teste com
  `uv run --python 3.12 ~/.claude/skills/kb-setup/scripts/kb.py --version` e reporte a dependência.
- **O auto mode bloqueia `uvx ... python -c`** (código inline): rode um comando simples por chamada. Para descobrir
  a origem do graphify, leia `$(uv tool dir)/graphifyy/uv-receipt.toml` em vez de rodar Python inline, ou aprove o
  comando manualmente.
- **A versão do graphify diverge da registrada em `kb/SETUP.md` / `kb/config.yaml`:** confira `graphify --version`
  e a origem em `uv-receipt.toml`. Se ele veio do PyPI, reinstale do fork (`uv tool install --force -e "$REPO"`).
  Se o fork avançou de versão, rode `/kb-setup upgrade` no workspace antes de reconstruir o grafo.
- **Cópias `SKILL.md.bak` em `~/.claude/skills/graphify`:** qualquer comando do graphify atualiza cópias antigas da
  skill global e guarda a anterior como `.bak`. Para desligar, use `GRAPHIFY_NO_AUTO_REFRESH=1`.

## Desenvolvimento da skill

```
kb-setup/
├── SKILL.md            roteador de comandos e princípios (o que o Claude lê)
├── README.md           este arquivo (o Claude ignora)
├── scripts/            kb.py (engine) + kb.py.lock, eval_report.py, core_renames.py
├── assets/core/        ontologia core kb: e shapes SHACL
├── assets/queries/     queries SPARQL salvas do core
├── assets/templates/   CLAUDE.md, SETUP.md, config.yaml, README.md, skill /kb, notas, prompts, graphifyignore
├── presets/            rfi-proposal, erp-rollout-program (ontologia, shapes, mapeamentos, queries, task skills)
├── references/         passo a passo de cada modo (discovery, interview, graphify, migration, evals, lessons…)
└── evals/evals.json    casos de teste da própria skill
```

- **Evals da skill:** `evals/evals.json` traz os prompts, a saída esperada e as assertions de cada caso. Rode com a
  skill `skill-creator`, que executa os casos em subagentes e avalia as assertions. Os corpora usados nos casos
  (`corpus-rfp`, `fixture-initialized`) não ficam neste repositório.
- **Relatório do modo `eval`:** `scripts/eval_report.py` agrega `runs.jsonl`, `grades.json` e os JSONs de volume:
  `uv run ~/.claude/skills/kb-setup/scripts/eval_report.py --dir <pasta do eval> --out kb/evals/<data>/report.md`.
- `kb-setup/` fica **fora do pacote `graphifyy`**: não entra no wheel nem nos `testpaths` do pytest, e o
  `tools/skillgen` não a gera. Mudanças aqui não afetam o graphify publicado. Se um dia for enviar PR ao upstream,
  crie a branch a partir do upstream, sem esta pasta.
