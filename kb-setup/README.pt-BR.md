# kb-setup: base de conhecimento local por workspace (graph-RAG + graphify)

🇺🇸 [English](README.md) | 🇧🇷 Português

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
                   │                      (+ cópia opcional do engine em scripts/kb-engine/)
                   │
                   └─► graphify (uv tool instalado a partir deste fork)
                          └─► workspace/graphify-out/  (grafo exploratório; fora do git)
```

## Objetivo

Construir, sobre o graphify deste fork, uma **KB local para workspaces de documentos** que combina um método de uso
baseado no Zettelkasten com um **graph-RAG guiado por ontologia** (RDF/OWL + SHACL + SPARQL). Em vez de recuperar
trechos parecidos com a pergunta, ela responde com entidades tipadas e consultas estruturais, aplica precedência,
detecta conflitos e cita a página ou a linha da planilha. É determinística e local. O graphify continua como grafo
exploratório de código e temas; os dois grafos ficam separados de propósito (sem ponte de dados,
`references/graphify.md`).

### O que as ontologias acrescentam

- **Tipos:** o core `kb:` (`assets/core/kb-core.ttl`) alinha suas classes a PROV, Dublin Core e SKOS (documentos e
  notas são `prov:Entity`, pessoas são `prov:Agent`, termos do glossário são `skos:Concept`). Os presets de domínio
  (`presets/rfi-proposal`, `presets/erp-rollout-program`) acrescentam classes, shapes, mapeamentos e queries próprios.
- **Validação:** shapes SHACL (`kb-core-shapes.ttl` + as shapes do preset) verificam o grafo sempre que uma atualização o altera.
- **Proveniência:** um named graph por fonte, e cada fato aponta para a fonte com página, ou aba e linha.
- **Precedência:** uma nota do wiki com `overrides:` vence; fora isso, `raw/` vence `wiki/`; na mesma camada, vence a
  versão mais recente (`assets/queries/precedence.rq`).
- **Conflitos:** os valores consolidados por tema/fato (`topics.yaml`, `facts.yaml`) expõem divergências entre fontes e
  dentro de uma mesma fonte (`conflicts.rq`, `internal-inconsistencies.rq`).
- **Queries SPARQL salvas:** conflitos, lacunas, RACI por papel, prazos, inconsistências internas, notas com revisão
  vencida (`assets/queries/`, `presets/*/queries/`).

No eval (uma rodada, 12 perguntas, 6 documentos), a KB fez 24/24 em acurácia e 24/24 em citação, contra 21/24 e 18/24
do graphify sozinho, com custo de build bem menor. A amostra é pequena; vale como sinal, não como benchmark.

### O método Zettelkasten

- **Papéis das pastas:** `raw/` guarda as fontes, `wiki/` as notas do time, `kb/` o índice e o grafo gerados, `docs/`
  os entregáveis (nunca indexados).
- **Notas viram triplas:** tipos de nota `fleeting`, `literature` e `permanent`; `[[links]]` entre notas viram
  `kb:linksTo`; linhas como `- Decision: …`, `- Deadline: <marco> = AAAA-MM-DD`, `- Term: <SIGLA> = …` e
  `- Condition: <tema> = <valor>` viram fatos no grafo (`references/zettelkasten.md`).
- **Revisão:** cada nota traz `last_reviewed` e, se quiser, `review_every`; `/kb stale` lista as vencidas.
- **Uma adaptação, não o método ortodoxo:** não há numeração Folgezettel e a `wiki/` é plana
  (`wiki/AAAA-MM-DD-slug-curto.md`); o tipo da nota fica no cabeçalho.

Nota: a busca de entrada é lexical nos dois sistemas e nenhum usa embeddings. O graphify pontua os rótulos dos nós por
termo e depois percorre o grafo; o `KB ask` pondera os acertos de termo por propriedade. O ganho da ontologia vem
depois da busca: tipos, validação, consultas estruturais, precedência, conflitos e proveniência.

### Configuração guiada para usuários não técnicos

Oferecer uma configuração inicial guiada para quem só precisa de uma KB funcionando. A skill descobre sozinha o que
puder, pergunta só o essencial com padrões recomendados, instala e configura o graphify e entrega o workspace pronto
para usar com `/kb`. O usuário não precisa entender graphify, ontologias, RDF ou SPARQL.

- **Discovery antes de qualquer pergunta:** a skill inspeciona a pasta, o versionamento, as políticas e as ferramentas
  sem abrir o conteúdo dos documentos (`references/discovery.md`).
- **Modo autônomo:** a primeira pergunta do init. Escolhido esse modo, a skill não pergunta mais nada: assume a opção
  recomendada em cada decisão, aprova os checkpoints sozinha e lista no resumo final todas as decisões assumidas.
- **Entrevista curta:** rodadas de até 4 perguntas, com a opção recomendada primeiro (`references/interview.md`).
- **graphify automático:** instalação a partir do fork e build do grafo, com escopo seguro por padrão (código +
  `docs/` + `wiki/`; `raw/` só com autorização por documento).
- **Workspace vazio:** o método é explicado, notas de exemplo são criadas e a primeira nota é guiada
  (`references/zettelkasten.md`).
- **Uso diário:** só `/kb <pergunta>` e `/kb update`.

Limite atual: os checkpoints de ontologia, mapeamentos e regras ainda são apresentados em termos técnicos. Aceitar a
proposta recomendada funciona, mas uma apresentação em linguagem simples é a próxima melhoria.

## Pré-requisitos

- [`uv`](https://docs.astral.sh/uv/) (obrigatório; ele também fornece o Python que o engine usa)
- Python ≥ 3.10
- Claude Code
- git
- Node.js, só para instalar com `npx skills`
- Opcional: OneDrive/Teams, para compartilhar o workspace com o time (`references/onedrive-teams-sync.md`)

## Instalação

### Instalação rápida com `npx skills`

Instale só a meta-skill, global para o Claude Code:

```bash
npx skills add wagnerpinheiro/graphify-kb --skill kb-setup -g -a claude-code
```

A skill fica em `~/.claude/skills/kb-setup`. O graphify não precisa ser instalado antes: no primeiro
`/kb-setup init`, o discovery detecta que ele falta e instala a partir do fork. Para instalar já, use o comando do
passo 2 abaixo (fallback sem clone). Confira com o passo 4.

### Instalação a partir de um clone

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
   uv run ~/.claude/skills/kb-setup/scripts/kb.py --version   # kb.py engine 2.1.0 · kb-setup 2.1.0 (central)
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
   2. ✋ **Modo de configuração e entrevista:** a primeira pergunta é o modo. **Autônomo** (recomendado): a entrevista
      e os checkpoints ✋ abaixo são resolvidos com as opções recomendadas e revistos no resumo final.
      **Guiado:** rodadas de até 4 perguntas, com o padrão recomendado em primeiro: propósito e preset, idioma,
      versionamento, cópia do engine no workspace, confidencialidade (o que o Claude pode ler por inteiro), precedência de versões, período de
      revisão de notas, escopo do graphify (código + `docs/` + `wiki/`, e quais documentos de `raw/` liberar) e task
      skills.
   3. **Scaffold Zettelkasten:** `kb.py scaffold` cria `raw/ wiki/ kb/ docs/`, `kb/config.yaml` e o bloco do
      `.gitignore`. Em seguida a skill gera `README.md`, `CLAUDE.md`, `.claude/skills/kb/SKILL.md` e `kb/SETUP.md`. Se você
      escolheu a cópia do engine, `kb.py vendor` a grava em `scripts/kb-engine/`. Num workspace vazio, ela cria notas
      de exemplo e guia a primeira nota permanente.
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
   │   ├── config.yaml          engine_version, kb_setup_version, ontologia, fontes, graphify.version/source/scope
   │   ├── SETUP.md             decisões, autorizações, versão e origem do graphify
   │   ├── IMPROVEMENTS.md      backlog de melhorias
   │   └── ontology/ mappings/ queries/ evals/ wiki/
   ├── .claude/skills/kb/       skill /kb do workspace (+ task skills aprovadas)
   ├── scripts/kb-engine/       cópia opcional do engine para quem não tem a kb-setup (ENGINE.json + arquivos texto)
   ├── CLAUDE.md                regras da KB e de coexistência com o graphify
   ├── README.md                método do workspace
   ├── .graphifyignore          exclui kb/, .claude/ e scripts/kb-engine/ do graphify
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
| `upgrade` | a kb-setup, o engine ou o graphify do fork mudou de versão: changelog, migração, rebuild e atualização da cópia do engine | [`references/migration.md`](references/migration.md) |
| `graphify` | reinstalar, conferir versão, mudar escopo ou reconstruir o graphify | [`references/graphify.md`](references/graphify.md) |
| `eval` | tokens, tempo e qualidade: sem KB × só graphify × KB + graphify | [`references/evals.md`](references/evals.md) |
| `status` | saúde do engine, das versões, da cópia do engine, das políticas e do graphify | [`SKILL.md`](SKILL.md) |
| `review` | analisar o uso e aplicar melhorias aprovadas do backlog | [`references/improvements.md`](references/improvements.md) |
| `preset` | extrair um preset genérico de um workspace | [`references/presets.md`](references/presets.md) |

## Versionamento e atualizações

A kb-setup tem duas versões:

| Versão | Onde | Quando sobe |
|---|---|---|
| kb-setup (a skill) | `VERSION`, com o histórico em [`CHANGELOG.md`](CHANGELOG.md) | a cada mudança em `kb-setup/` que deva chegar aos usuários |
| engine | `ENGINE_VERSION` em `scripts/kb.py` | só quando muda o comportamento ou a compatibilidade do engine |

`uv run ~/.claude/skills/kb-setup/scripts/kb.py --version` mostra as duas. Cada workspace registra ambas em
`kb/config.yaml` (`kb_setup_version`, `engine_version`), e o engine avisa quando alguma está atrás da instalada em
major.minor.

**O que o Claude verifica, e quando**

- No início de cada modo `/kb-setup`, ele roda `kb.py check-update`, que lê o `VERSION` publicado (timeout de 3 s).
  Se houver versão nova, o Claude mostra a versão, o link do changelog e o comando de atualização, e oferece rodá-lo.
  Sem rede, atrás de proxy ou em qualquer erro, a checagem é pulada sem comentário.
- O `/kb` nunca acessa a rede. Ele só repete os avisos de versão do engine e sugere `/kb-setup upgrade`.

**Como atualizar**

- Clone + symlink: `git -C "$REPO" pull`. O symlink já aponta para a versão nova, e o graphify editável também é
  atualizado. Se a versão do graphify mudou, rode `graphify install --platform claude` para atualizar a skill
  `/graphify`.
- `npx skills`: `npx skills update kb-setup -g`. A cópia instalada não se atualiza sozinha; é para isso que existe o
  `check-update`.
- Depois abra uma sessão nova do Claude Code e rode `/kb-setup upgrade` em cada workspace. Ele compara
  `kb_setup_version`, `engine_version` e `graphify.version` em `kb/config.yaml`, mostra o changelog, regenera os
  arquivos do workspace, atualiza a cópia do engine e reconstrói o que for preciso, sempre com confirmação.

### Cópia do engine no workspace

O `/kb-setup init` (e também `adopt`/`upgrade`) pergunta se o engine deve ser copiado para o workspace. Com a cópia,
quem abre a pasta sem a kb-setup (um colega via OneDrive, por exemplo) ainda consegue consultar a KB com
`uv run scripts/kb-engine/kb.py`; basta ter uv e Claude Code.

- **O que vai na cópia:** `kb.py`, `kb.py.lock`, `core_renames.py`, `VERSION`, a ontologia e as shapes do core, as
  queries do core e o `prompts.md`, além de um `ENGINE.json` com as versões, a origem, a data e o sha256 de cada
  arquivo. Só texto: as dependências ficam no cache do uv, fora do workspace.
- **Precedência:** o engine central (`~/.claude/skills/kb-setup`) vem sempre primeiro; a cópia é o fallback. Quando
  nenhum dos dois existe, o Claude oferece instalar a kb-setup via `npx skills`.
- **Limites:** a cópia consulta e atualiza a KB, mas não faz `scaffold` nem se atualiza, e a curadoria
  (`/kb-setup upgrade`, `eval`, `review`, skills, ontologia) continua exigindo a kb-setup.
- **Quem atualiza:** o curador, pelo `/kb-setup upgrade`. `kb.py vendor --check` diz se a cópia está desatualizada e
  `kb.py vendor` a atualiza.
- **Quando usar:** recomendada para workspaces no OneDrive/Teams e para quem só consulta; desnecessária no uso
  individual com git.
- Ela fica em `scripts/kb-engine/`, nunca em `scripts/kb/`, que marca um workspace v1 para o `adopt`.

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
├── VERSION             versão da kb-setup (semver), lida pelo kb.py e pelo check-update
├── CHANGELOG.md        uma entrada por versão: mudanças, versão do engine, passos de migração
├── README.md           documentação em inglês (o Claude ignora)
├── README.pt-BR.md     este arquivo (o Claude ignora)
├── scripts/            kb.py (engine) + kb.py.lock, eval_report.py, core_renames.py
├── assets/core/        ontologia core kb: e shapes SHACL
├── assets/queries/     queries SPARQL salvas do core
├── assets/templates/   CLAUDE.md, SETUP.md, config.yaml, README.md, skill /kb, notas, prompts, graphifyignore
├── presets/            rfi-proposal, erp-rollout-program (ontologia, shapes, mapeamentos, queries, task skills)
├── references/         passo a passo de cada modo (discovery, interview, graphify, migration, evals, lessons…)
└── evals/evals.json    casos de teste da própria skill
```

- **Bump de versão:** toda mudança em `kb-setup/` que deva chegar aos usuários sobe o `VERSION` e ganha uma entrada
  no `CHANGELOG.md`, com a versão do engine que a acompanha e os passos de migração para workspaces existentes.
  `ENGINE_VERSION` em `scripts/kb.py` só sobe quando muda o comportamento ou a compatibilidade do engine. O
  `check-update` lê o `VERSION` da branch `v8` no GitHub, então os usuários só veem o bump depois do push.
- **Evals da skill:** `evals/evals.json` traz os prompts, a saída esperada e as assertions de cada caso. Rode com a
  skill `skill-creator`, que executa os casos em subagentes e avalia as assertions. Os corpora usados nos casos
  (`corpus-rfp`, `fixture-initialized`) não ficam neste repositório.
- **Relatório do modo `eval`:** `scripts/eval_report.py` agrega `runs.jsonl`, `grades.json` e os JSONs de volume:
  `uv run ~/.claude/skills/kb-setup/scripts/eval_report.py --dir <pasta do eval> --out kb/evals/<data>/report.md`.
- `kb-setup/` fica **fora do pacote `graphifyy`**: não entra no wheel nem nos `testpaths` do pytest, e o
  `tools/skillgen` não a gera. Mudanças aqui não afetam o graphify publicado. Se um dia for enviar PR ao upstream,
  crie a branch a partir do upstream, sem esta pasta.
