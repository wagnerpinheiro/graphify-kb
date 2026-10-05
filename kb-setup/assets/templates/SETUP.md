# KB setup record — {{TITLE}}

Created by kb-setup {{KB_SETUP_VERSION}} (engine {{ENGINE_VERSION}}) on {{DATE}} by {{USER}}. Update this file on adopt/upgrade/review decisions.

## Discovery
{{DISCOVERY_SUMMARY}}

## Decisions (interview)
| # | Question | Options | Answer | Implication |
|---|---|---|---|---|

## Authorizations (full reading by an LLM)
| date | document(s) | purpose (extract-llm / graphify / eval) | authorized by |
|---|---|---|---|

## Preset and domain
- Preset: {{PRESET}} · domain prefix: {{PREFIX}} · namespace: {{NAMESPACE}}
- Ontology approved on: … · mappings approved on: … · topics/facts rules approved on: …

## Integrations
- Versioning: {{VERSIONING}}
- Engine: {{ENGINE_LOCATION}} (central `~/.claude/skills/kb-setup/scripts/kb.py` | copy in `scripts/kb-engine/`, refreshed by `/kb-setup upgrade`)
- graphify (required): version {{GRAPHIFY_VERSION}} · source {{GRAPHIFY_SOURCE}} (fork checkout path or `git+https://github.com/wagnerpinheiro/graphify-kb@<ref>`) · installed on {{GRAPHIFY_INSTALLED}} · scope {{GRAPHIFY_SCOPE}} · last build {{GRAPHIFY_BUILT}}
- Task skills: {{TASK_SKILLS}}

## History
| date | operation | notes |
|---|---|---|
