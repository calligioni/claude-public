---
name: sync-agenda
description: Sincroniza a planilha de 1:1 do SharePoint com o calendario Outlook Web. Le a planilha, compara com eventos existentes e cria/atualiza/mantem conforme necessario.
trigger: /sync-agenda
tools: mcp__plugin_playwright_playwright__browser_navigate, mcp__plugin_playwright_playwright__browser_snapshot, mcp__plugin_playwright_playwright__browser_take_screenshot, mcp__plugin_playwright_playwright__browser_click, mcp__plugin_playwright_playwright__browser_run_code, mcp__plugin_playwright_playwright__browser_press_key, mcp__plugin_playwright_playwright__browser_type, mcp__plugin_playwright_playwright__browser_evaluate, Bash, Read
---

# Sync Agenda 1:1 - SharePoint -> Outlook

Voce e um agente que sincroniza compromissos 1:1 de uma planilha Excel no SharePoint com o calendario do Outlook Web.

## URL da planilha (fixa)

```
https://onclicksistemas-my.sharepoint.com/:x:/g/personal/andre_rosa_onclick_com_br/IQBF67z7_uPkTKGPpD_4zs0gAexfMm1C49COoxGBstOUUqY?e=nVNLaL
```

## Estrutura da planilha

| Coluna A | Coluna B | Coluna C |
|----------|----------|----------|
| Data (dd/mm) | Horario (HH:MM-HH:MM) | Nome |

- Linhas sem Nome na coluna C devem ser **ignoradas**
- **Eventos passados devem ser ignorados**: antes de processar cada linha, compare a data+hora de inicio com a data/hora atual. Se o horario de inicio ja passou, ignore o evento (nao criar, nao atualizar). Reporte como "Ignorados (passados)" no resumo final.
- O ano e sempre o ano corrente (2026)
- O horario contem inicio e fim separados por hifen (ex: `10:00-10:45`)

## Formato dos eventos no Outlook

- **Titulo**: `1:1 - [Nome]` (ex: `1:1 - Adrienne Prado`)
- **Duracao**: definida pelo horario da planilha (inicio-fim)
- **Lembrete**: 15 minutos

## Fluxo de execucao

### PASSO 1: Ler a planilha

1. Navegue ate a URL da planilha usando Playwright
2. Aguarde carregar completamente (2-3 segundos)
3. Tire um screenshot para visualizar os dados
4. Tente extrair os dados via uma das estrategias abaixo (em ordem de preferencia):

**Estrategia A - Download como CSV:**
- Clique em Arquivo > Salvar Como > Baixar uma Copia
- Leia o arquivo baixado

**Estrategia B - Copiar via teclado:**
- Clique na celula A1
- Pressione Ctrl+Shift+End para selecionar tudo
- Pressione Ctrl+C para copiar
- Cole em algum lugar para extrair o texto

**Estrategia C - Leitura visual (fallback):**
- Tire screenshots da planilha completa (scrollando se necessario)
- Leia os dados visualmente dos screenshots
- Monte a lista de compromissos a partir do que ve

5. Monte uma lista de objetos com: `{ nome, data (YYYY-MM-DD), horaInicio (HH:MM), horaFim (HH:MM) }`
6. Filtre apenas os que tem Nome preenchido

### PASSO 2: Verificar eventos existentes no Outlook

1. Navegue para `https://outlook.office365.com/calendar/view/month`
2. Para cada data unica na lista, navegue ate o dia e verifique se existem eventos com titulo `1:1 - [Nome]`
3. Monte uma lista de eventos existentes com: `{ nome, data, horaInicio, horaFim }`

**NOTA**: Se a verificacao individual for muito lenta, pode pular este passo e ir direto para o Passo 3 usando a abordagem simplificada (criar todos, o Outlook nao duplica se o horario for identico).

### PASSO 3: Sincronizar (Nome como chave primaria)

Para cada pessoa na planilha:

1. **Se o nome ja existe no Outlook com o mesmo horario** -> MANTER (nao fazer nada)
2. **Se o nome ja existe mas com horario diferente** -> ATUALIZAR (abrir o evento existente e alterar o horario, ou deletar e recriar)
3. **Se o nome nao existe** -> CRIAR via deeplink:

```
https://outlook.office365.com/calendar/0/deeplink/compose?subject=1%3A1%20-%20[NOME_ENCODED]&startdt=[YYYY-MM-DD]T[HH:MM]:00&enddt=[YYYY-MM-DD]T[HH:MM]:00&path=%2Fcalendar%2Faction%2Fcompose
```

Ao abrir o deeplink:
- Aguarde o formulario carregar (2-3 segundos)
- Clique no botao "Salvar"
- Aguarde salvar (2 segundos)

### PASSO 4: Reportar resultado

Ao final, exiba um resumo:

```
Sync Agenda 1:1 - Resultado:
- Lidos da planilha: X compromissos
- Mantidos (sem alteracao): Y
- Atualizados (horario mudou): Z
- Criados (novos): W
- Ignorados (sem nome): N
- Ignorados (passados): P

Detalhes:
[lista de cada acao tomada]
```

## Observacoes importantes

- O usuario ja esta logado no SharePoint e Outlook (mesma conta Microsoft)
- Se o login expirar, avise o usuario para re-logar manualmente
- Use `encodeURIComponent()` para codificar o nome na URL do deeplink
- O ano dos eventos e 2026 (ano corrente)
- Datas no formato dd/mm na planilha devem ser convertidas para YYYY-MM-DD
- Se a planilha tiver mais de uma aba, use apenas a primeira (Planilha1)
