# Build Delphi via MSBuild

## Pré-requisitos

1. Localizar arquivo `.dproj` do projeto
2. Identificar plataforma: `Win32`, `Win64`, `Android`, `iOS`, etc.
3. Identificar configuração: `Debug` ou `Release`
4. Localizar o MSBuild (tipicamente: `C:\Windows\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe`)

## Comando base

```bash
msbuild Projeto.dproj /t:Build /p:Config=Debug /p:Platform=Win32
```

## Variações de comando

```bash
# Build Release
msbuild Projeto.dproj /t:Build /p:Config=Release /p:Platform=Win32

# Clean
msbuild Projeto.dproj /t:Clean /p:Config=Debug /p:Platform=Win32

# Rebuild (Clean + Build)
msbuild Projeto.dproj /t:Rebuild /p:Config=Debug /p:Platform=Win32

# Com log detalhado
msbuild Projeto.dproj /t:Build /p:Config=Debug /p:Platform=Win32 /v:detailed

# Salvar log em arquivo
msbuild Projeto.dproj /t:Build /p:Config=Debug /p:Platform=Win32 /l:FileLogger,Microsoft.Build.Engine;logfile=build.log
```

## KPL — scripts de build existentes

O projeto KPL tem scripts em `buildProcess/project/`:
- `BuildAbacosService.bat` — build do serviço principal
- `BuildwsUnificado.bat` — build dos webservices

Verificar estes scripts antes de rodar MSBuild manualmente.

## Fluxo ao encontrar erro de compilação

1. Identificar **arquivo** com erro (linha `erro no arquivo X.pas`)
2. Identificar **linha** do erro
3. Explicar a **causa** do erro
4. Corrigir o código
5. Recompilar
6. Se erro recorrente: registrar em `error-patterns.md`

## Erros de compilação comuns

| Erro | Causa típica |
|---|---|
| `Undeclared identifier` | Unit não incluída no `uses` ou typo no nome |
| `Type mismatch` | Tipos incompatíveis na atribuição |
| `Unit not found` | Path de units não configurado no `.dproj` |
| `Duplicate identifier` | Mesmo nome declarado duas vezes |
| `Missing BEGIN` | Bloco `begin`/`end` mal formado |
| `Expected ;` | Ponto-e-vírgula faltando |

## Versões do Delphi — MSBuild path

| Delphi | Versão interna | MSBuild típico |
|---|---|---|
| Delphi 5 | 13.0 | Não usa MSBuild — usa DCC32.exe |
| Delphi XE2+ | 16.0+ | MSBuild via .dproj |
| Delphi 10.x | 20.0+ | MSBuild via .dproj |

## Delphi 5 — DCC32

Delphi 5 usa compilador direto `DCC32.exe`:
```bash
DCC32.exe Projeto.dpr
```
