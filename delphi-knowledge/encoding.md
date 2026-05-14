# Encoding Delphi

## Regras obrigatórias

1. **Preservar o encoding original do arquivo** — nunca alterar sem necessidade
2. Se o projeto usa UTF-8 com BOM, manter UTF-8 com BOM
3. Preservar quebras de linha **CRLF** (Windows: `\r\n`)
4. Depois de alterar arquivos com acentos, verificar se os caracteres foram corrompidos
5. Nunca substituir acentos por texto sem acento para evitar erro — corrigir o encoding

## Delphi 5 — encoding legado

- Delphi 5 usa **ANSI/Latin-1** por padrão
- Strings são `AnsiString` — não suportam Unicode nativo
- Arquivos `.pas` e `.dfm` tipicamente em **ISO-8859-1** (Latin-1)
- Cuidado: ferramentas modernas podem converter para UTF-8 quebrando o projeto

## KPL/Abacos — regra crítica

Os arquivos SQL e .pas do KPL estão em **ISO-8859-1 (Latin-1)**.
- NUNCA usar as ferramentas Edit/Write padrão para editar esses arquivos
- Usar `sed` via Bash para edições pontuais
- Verificar encoding antes e depois com `file --mime-encoding`

## Verificação de encoding

```bash
# Verificar encoding de um arquivo
file --mime-encoding arquivo.pas

# Resultado esperado para Delphi 5:
# arquivo.pas: iso-8859-1
```

## Identificação de BOM UTF-8

UTF-8 com BOM começa com bytes `EF BB BF`.

```bash
# Verificar se tem BOM
hexdump -C arquivo.pas | head -1
```

## Quando usar cada ferramenta de edição

| Encoding | Ferramenta |
|---|---|
| UTF-8 | Edit/Write (ferramentas padrão) |
| ISO-8859-1 / Latin-1 | Bash + sed |
| UTF-8 com BOM | Edit/Write com cuidado — verificar BOM |

## Quebras de linha

Delphi no Windows usa **CRLF** (`\r\n`).
Nunca gravar arquivo `.pas` ou `.dfm` com apenas LF (`\n`) — pode causar problemas no IDE.
