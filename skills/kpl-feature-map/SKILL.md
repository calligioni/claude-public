# Skill: kpl-feature-map

Gera o mapa de capacidades do KPL por módulo, correlacionando telas/código com processos de negócio e mercado.

## Trigger
`/kpl-feature-map [Módulo]` — ex: `/kpl-feature-map Comercial`
`/kpl-feature-map [Módulo] --force` — regenera mesmo que já exista

## Mapeamento de Módulos → Prefixos de Código

| Módulo (input) | Prefixo Delphi MOV | Prefixo Delphi CAD | WebService .NET |
|----------------|-------------------|--------------------|-----------------|
| Comercial | COMMOV_ | COMCAD_ | AbacosWSERP, AbacosWSWMS |
| Estoque | ESTMOV_ | ESTCAD_ | AbacosWSWMS, AbacosWSERP |
| Financeiro | FINMOV_ | FINCAD_ | AbacosWSERP |
| Fiscal | FISCMOV_ | FISCCAD_ | AbacosWSERP |
| Compras | CPRMOV_ | CPRCAD_ | AbacosWSERP |
| Geral | GENMOV_ | GENCAD_ | — |

Raiz Delphi: `Aplicacoes\BackOfficeDelphi\`
Raiz WebServices: `Aplicacoes\Webservices\`
Raiz Serviços Worker: `Aplicacoes\Abacos.Net\Services\`

---

## Comportamento Esperado

### Passo 1 — Verificar idempotência
Ler `docs/feature-map/INDEX.md`.
- Se o módulo solicitado já estiver na tabela E o argumento `--force` NÃO foi passado:
  → Informar ao usuário: "O módulo [X] já foi gerado em [data]. Use `--force` para regenerar."
  → Parar.
- Caso contrário: prosseguir.

### Passo 2 — Explorar o codebase
1. **Delphi**: Glob por `{PREFIXO_MOV}*.pas` e `{PREFIXO_CAD}*.pas` no repositório.
   - Listar todos os nomes de arquivo encontrados.
   - Para cada grupo lógico identificado (ex: Pedidos, Faturamento, Separação), ler as primeiras 60 linhas do arquivo `_M` ou `_B` mais representativo para entender: campos de tela, ações disponíveis, integração com serviços.
2. **WebServices .NET**: Grep por `[WebMethod]` nos arquivos do WebService correspondente ao módulo.
   - Capturar: nome do método, parâmetros principais, SP chamada (se identificável).
3. **Workers .NET**: Grep por `BaseThread` ou `ServiceThread` em `Aplicacoes\Abacos.Net\Services\` para o módulo.

### Passo 3 — Selecionar features para o mapa
- Priorizar processos **MOV_** (operacionais) sobre **CAD_** (cadastro).
- Escolher entre 3 e 6 features que representem os principais fluxos de negócio do módulo.
- Cada feature deve ter correspondência clara em pelo menos uma camada (Delphi ou .NET).

### Passo 4 — Classificar cada feature
Para cada feature, determinar com base no código e no conhecimento de mercado:
- **Maturidade**: ver critério abaixo
- **Segmento**: ver critério abaixo

### Passo 5 — Gerar os arquivos de saída
Gerar `docs/feature-map/{Modulo}.md` e `docs/feature-map/{Modulo}.csv` conforme layouts abaixo.

### Passo 6 — Atualizar o índice
Adicionar ou atualizar linha em `docs/feature-map/INDEX.md`.

### Passo 7 — Corrigir encoding (UTF-8 com BOM)
**OBRIGATÓRIO** após escrever qualquer arquivo. Os arquivos gerados pelo Write tool são UTF-8 sem BOM, o que faz Windows/Excel interpretar errado os acentos. Execute este bloco PowerShell para adicionar BOM em todos os arquivos gerados nesta execução:

```powershell
$bom = [byte[]]@(0xEF, 0xBB, 0xBF)
$files = @(
    "docs/feature-map/{Modulo}.md",
    "docs/feature-map/{Modulo}.csv",
    "docs/feature-map/INDEX.md"
)
foreach ($path in $files) {
    $raw = [System.IO.File]::ReadAllBytes($path)
    if ($raw[0] -ne 0xEF -or $raw[1] -ne 0xBB -or $raw[2] -ne 0xBF) {
        [System.IO.File]::WriteAllBytes($path, $bom + $raw)
    }
}
```

Substitua `{Modulo}` pelo módulo gerado. Confirme que os primeiros bytes do arquivo são `EF BB BF`.

---

## Critério de Classificação

### Maturidade
| Nível | Critério |
|-------|----------|
| **Básico** | Funcionalidade presente na maioria dos ERPs do segmento; sem diferencial competitivo evidente |
| **Avançado** | Funcionalidade presente em ERPs premium; exige configuração ou especialização; acima da média do mercado SMB |
| **Diferenciado** | Funcionalidade rara ou inexistente em concorrentes diretos; ou implementação nativa que concorrentes só oferecem via módulo adicional |

### Segmento de Mercado
| Segmento | Quando aplicar |
|----------|---------------|
| **Varejo** | Features de B2C: pedido por canal, caixa, cupom, cartão presente, logística reversa para consumidor final |
| **B2B** | Features de venda para empresas: contratos, representantes, análise de crédito, pedido de compra |
| **Distribuição** | Features de movimentação de estoque em escala: separação por onda, WMS, rastreabilidade lote/série, volumes |
| **Indústria** | Features de produção ou suprimentos: pedido de compra, reserva de estoque, controle de insumos |

---

## ════════════════════════════════════════
## OUTPUT_TABLE_COLUMNS  ← EDITE AQUI para mudar o layout da tabela executiva
## ════════════════════════════════════════

Colunas da tabela executiva (Section 1 do .md e cabeçalho do .csv):

```
Feature/Tela | Processo de Negócio | Capacidade de Mercado | Concorrentes | Diferencial KPL | Maturidade | Segmento
```

Para adicionar, remover ou renomear colunas: edite a linha acima e ajuste a seção
"Ficha Técnica" abaixo para incluir/excluir o campo correspondente.

---

## Layout do Arquivo de Saída (.md)

```markdown
# KPL Feature Map — {Módulo}

> Gerado em: {DATA}  
> Fonte: codebase Abacos.DPR + AbacosService .NET  
> Features mapeadas: {N}

---

## Visão Executiva

| Feature/Tela | Processo de Negócio | Capacidade de Mercado | Concorrentes | Diferencial KPL | Maturidade | Segmento |
|---|---|---|---|---|---|---|
| ... | ... | ... | ... | ... | ... | ... |

---

## Fichas Técnicas

### {Nome da Feature}

- **Tela/Unit (Delphi)**: `XXXXXX_Y` — {descrição curta}
- **Serviço .NET**: `MetodoXxx()` em `Arquivo.asmx.cs` *(omitir se não encontrado)*
- **Stored Procedure**: `schema.pProcedure` *(omitir se não encontrado)*
- **Processo de Negócio**: {descrição do processo}
- **Capacidade de Mercado**: {categoria de mercado}
- **Maturidade**: {Básico | Avançado | Diferenciado}
- **Segmento**: {Varejo | B2B | Distribuição | Indústria — múltiplos permitidos}
- **Concorrentes**: {lista com referências de tela/módulo quando possível}
- **Diferencial KPL**: {o que o KPL faz diferente ou melhor}

---
```

## Layout do Arquivo CSV

```
Feature/Tela,Processo de Negócio,Capacidade de Mercado,Concorrentes,Diferencial KPL,Maturidade,Segmento
{linha por feature}
```

- Separador: vírgula
- Campos com vírgula interna: envolver em aspas duplas
- Encoding: UTF-8
- Múltiplos segmentos na mesma célula: separar por " / " (ex: `"Varejo / B2B"`)

---

## Layout do INDEX.md

```markdown
# KPL Feature Map — Módulos Gerados

| Módulo | Arquivo | Data | Features |
|--------|---------|------|----------|
| {Modulo} | [{Modulo}.md]({Modulo}.md) | {YYYY-MM-DD} | {N} |
```

Se o arquivo já existir, apenas adicionar/atualizar a linha do módulo gerado — não apagar outras linhas.
