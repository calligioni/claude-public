# Claude Code - Setup Completo para Windows

## O que este setup faz

Este repositorio automatiza a configuracao completa do Claude Code em maquinas Windows, incluindo:

- **Claude CLI** (`~/.claude/`) - agents, skills, MCP servers, hooks, regras
- **Claude Desktop** (`%APPDATA%\Claude\`) - MCP servers com credenciais
- **Auto-sync** - sincronizacao automatica via git a cada 3 minutos
- **Credenciais seguras** - API keys no Windows Credential Manager (nao no codigo)

Apos a instalacao, qualquer mudanca em agents, skills ou configs e sincronizada automaticamente entre maquinas.

---

## Cenario A: Instalacao do Zero (maquina nova sem nada)

### Passo 1: Instalar ferramentas base

Abra o PowerShell como **administrador** e execute:

```powershell
# Instalar Git, GitHub CLI, Node.js e jq
winget install Git.Git
winget install GitHub.cli
winget install OpenJS.NodeJS
winget install jqlang.jq
```

Feche e reabra o PowerShell para que os novos comandos fiquem disponiveis no PATH.

**Habilitar Developer Mode** (necessario para symlinks de arquivo):
1. Abra **Configuracoes do Windows** (Win+I)
2. Va em **Sistema > Para Desenvolvedores**
3. Ative **Modo de Desenvolvedor**

**Configurar Execution Policy** (permite rodar scripts PowerShell):
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Verificar tudo instalado:**
```powershell
git --version      # Git 2.x+
gh --version       # GitHub CLI 2.x+
node --version     # Node.js 18+
npm --version      # npm 9+
jq --version       # jq 1.6+
```

### Passo 2: Instalar Claude Code CLI

```powershell
npm install -g @anthropic-ai/claude-code
claude --version
```

Se `claude` nao for encontrado, feche e reabra o terminal.

### Passo 3: Instalar Claude Desktop (opcional)

Baixe e instale o Claude Desktop de [claude.ai/download](https://claude.ai/download).

O instalador vai configurar automaticamente o `%APPDATA%\Claude\` onde ficam as configs do Desktop.

### Passo 4: Clonar o repositorio

```powershell
# Autenticar no GitHub (necessario para repos privados)
gh auth login

# Clonar o repo para ~/.claude-setup
gh repo clone <seu-usuario>/<seu-repo> $env:USERPROFILE\.claude-setup

# Entrar na pasta
cd $env:USERPROFILE\.claude-setup
```

### Passo 5: Rodar o instalador

```powershell
.\windows\install.ps1
```

O instalador executa 9 etapas automaticamente:

| Etapa | O que faz |
|---|---|
| 1. Prerequisites | Verifica git, gh, node, npm, jq |
| 2. GitHub Auth | Confirma autenticacao no GitHub |
| 3. Repository | Atualiza o repo ou clona se necessario |
| 4. Symlinks | Cria junctions de `~/.claude/` → repo |
| 5. MCP Servers | Instala dependencias dos MCP servers |
| 6. Credentials | Verifica quais credenciais estao configuradas |
| 7. Shell Profile | Configura `$PROFILE` do PowerShell |
| 8. Task Scheduler | Registra auto-sync a cada 3 minutos |
| 9. Claude Desktop | Gera config do Desktop com MCP servers |

### Passo 6: Configurar credenciais

```powershell
# Setup interativo - pergunta cada secret
.\windows\setup-credentials.ps1
```

O script pergunta interativamente cada credencial e armazena no Windows Credential Manager.

**Credenciais obrigatorias:**
- `GITHUB_TOKEN` - Token do GitHub (necessario para GitHub CLI)
- `BRAVE_API_KEY` - Chave da Brave Search API

**Credenciais opcionais** (configure conforme necessidade):
- `ANTHROPIC_API_KEY` - Claude API
- `AZURE_DEVOPS_PAT` - Azure DevOps
- `SQLSERVER_PASSWORD` - SQL Server (MCP)
- `DESKMANAGER_API_KEY` / `DESKMANAGER_PUBLIC_KEY` - Desk Manager (MCP)
- `OBSIDIAN_API_KEY` - Obsidian (MCP)
- `SLACK_BOT_TOKEN` / `SLACK_TEAM_ID` - Slack
- `NOTION_API_KEY` - Notion
- `RESEND_API_KEY` - Resend (email)
- `DIGITALOCEAN_TOKEN` - DigitalOcean
- `FIRECRAWL_API_KEY` - Firecrawl

### Passo 7: Verificar instalacao

Execute cada comando e confirme o resultado esperado:

```powershell
# 1. Symlinks criados?
Get-ChildItem $env:USERPROFILE\.claude | Where-Object { $_.LinkType } | Format-Table Name, LinkType, Target

# 2. Credenciais salvas?
cmdkey /list:claude-code-github-token
cmdkey /list:claude-code-brave-api-key

# 3. Task Scheduler rodando?
Get-ScheduledTask -TaskName "ClaudeSetupSync" | Format-List TaskName, State

# 4. Profile configurado?
Select-String "load-secrets" $PROFILE

# 5. Claude Desktop config existe?
Test-Path "$env:APPDATA\Claude\claude_desktop_config.json"

# 6. Testar Claude Code
claude --version
```

Se tudo passou, reinicie o terminal e o Claude Desktop, depois rode `claude` para comecar.

---

## Cenario B: Ja tenho Claude Code configurado

Se voce ja usa o Claude Code e tem agents, skills ou MCP servers customizados em `~/.claude/`, siga este fluxo:

### Passo 1: Entenda o que vai acontecer

O instalador:
- **FAZ backup** automatico de `~/.claude/` para `~/.claude-backup-<timestamp>/`
- **Substitui** pastas (agents, skills, mcp-servers, etc.) por junctions apontando para o repo
- **NAO toca** em arquivos auto-gerados (history.jsonl, sessions/, cache/, etc.)

Seus agents e skills **ja devem estar** neste repositorio antes de rodar o instalador. Se voce tem itens customizados que ainda nao estao aqui, copie-os primeiro:

```powershell
# Exemplo: copiar um agent customizado para o repo
Copy-Item "$env:USERPROFILE\.claude\agents\meu-agent.md" ".\agents\"

# Exemplo: copiar uma skill customizada para o repo
Copy-Item -Recurse "$env:USERPROFILE\.claude\skills\minha-skill\" ".\skills\"
```

### Passo 2: Clonar o repo (se ainda nao fez)

```powershell
gh auth login
gh repo clone <seu-usuario>/<seu-repo> $env:USERPROFILE\.claude-setup
cd $env:USERPROFILE\.claude-setup
```

### Passo 3: Rodar o instalador

```powershell
.\windows\install.ps1
```

O backup e criado automaticamente em `~/.claude-backup-<timestamp>/`.

### Passo 4: Conferir que tudo esta disponivel

```powershell
# Listar agents disponiveis
Get-ChildItem "$env:USERPROFILE\.claude\agents\*.md" | Select-Object Name

# Listar skills disponiveis
Get-ChildItem "$env:USERPROFILE\.claude\skills\" -Directory | Select-Object Name

# Listar MCP servers
Get-ChildItem "$env:USERPROFILE\.claude\mcp-servers\" | Select-Object Name

# Verificar settings.json
Get-Content "$env:USERPROFILE\.claude\settings.json" | ConvertFrom-Json | Format-List
```

### Passo 5: Restaurar se algo deu errado

```powershell
# Restaura do backup mais recente
.\windows\setup-symlinks.ps1 -Restore
```

Isso remove todas as junctions e restaura os arquivos originais do backup.

---

## O que cada script faz

| Script | Descricao | Uso |
|---|---|---|
| `install.ps1` | **Instalador principal** - executa todas as 9 etapas | `.\windows\install.ps1` |
| `helpers.ps1` | Funcoes compartilhadas: log, CredManager (P/Invoke), junctions | Dot-sourced pelos outros scripts |
| `setup-symlinks.ps1` | Cria junctions/symlinks de `~/.claude/` → repo. Instala `claude-sync` | `.\windows\setup-symlinks.ps1` |
| `setup-credentials.ps1` | Setup interativo de 17 credenciais no Credential Manager | `.\windows\setup-credentials.ps1` |
| `load-secrets.ps1` | Carrega secrets do Credential Manager como env vars | Dot-sourced pelo `$PROFILE` |
| `setup-mcp-servers.ps1` | `npm install` + build dos MCP servers locais | `.\windows\setup-mcp-servers.ps1` |
| `setup-task-scheduler.ps1` | Registra auto-sync no Task Scheduler (3 min) | `.\windows\setup-task-scheduler.ps1` |
| `setup-desktop.ps1` | Gera `claude_desktop_config.json` a partir do template | `.\windows\setup-desktop.ps1` |
| `claude-auto-sync.ps1` | Script de sync executado pelo Task Scheduler | Automatico (nao rodar manualmente) |

---

## Credenciais e Secrets

Todas as credenciais ficam no **Windows Credential Manager** — nunca no codigo.

### Lista completa

| Credencial | Variavel de Ambiente | Obrigatoria | Usado por |
|---|---|---|---|
| `claude-code-github-token` | GITHUB_TOKEN | Sim | GitHub CLI, MCP Git |
| `claude-code-brave-api-key` | BRAVE_API_KEY | Sim | Brave Search MCP |
| `claude-code-anthropic-api-key` | ANTHROPIC_API_KEY | Nao | Claude API direta |
| `claude-code-azure-devops-pat` | AZURE_DEVOPS_PAT | Nao | Azure DevOps MCP |
| `claude-code-sqlserver-host` | SQLSERVER_HOST | Nao | SQL Server MCP |
| `claude-code-sqlserver-user` | SQLSERVER_USER | Nao | SQL Server MCP |
| `claude-code-sqlserver-password` | SQLSERVER_PASSWORD | Nao | SQL Server MCP |
| `claude-code-sqlserver-database` | SQLSERVER_DATABASE | Nao | SQL Server MCP |
| `claude-code-deskmanager-api-key` | DESKMANAGER_API_KEY | Nao | Deskmanager MCP |
| `claude-code-deskmanager-public-key` | DESKMANAGER_PUBLIC_KEY | Nao | Deskmanager MCP |
| `claude-code-obsidian-api-key` | OBSIDIAN_API_KEY | Nao | Obsidian MCP |
| `claude-code-slack-bot-token` | SLACK_BOT_TOKEN | Nao | Slack MCP |
| `claude-code-slack-team-id` | SLACK_TEAM_ID | Nao | Slack MCP |
| `claude-code-notion-api-key` | NOTION_API_KEY | Nao | Notion MCP |
| `claude-code-resend-api-key` | RESEND_API_KEY | Nao | Resend (email) MCP |
| `claude-code-digitalocean-token` | DIGITALOCEAN_TOKEN | Nao | DigitalOcean MCP |
| `claude-code-firecrawl-api-key` | FIRECRAWL_API_KEY | Nao | Firecrawl MCP |

### Gerenciamento

```powershell
# Configurar interativamente
.\windows\setup-credentials.ps1

# Apenas verificar status (nao pede valores)
.\windows\setup-credentials.ps1 -Check

# Ver credenciais no Credential Manager
cmdkey /list:claude-code-*

# Adicionar manualmente
cmdkey /generic:claude-code-github-token /user:claude /pass:ghp_xxxxxxxxxxxx

# Remover uma credencial
cmdkey /delete:claude-code-github-token
```

### Como funciona o carregamento

1. O `$PROFILE` do PowerShell faz `. load-secrets.ps1` ao abrir um terminal
2. `load-secrets.ps1` le cada credencial do Credential Manager via P/Invoke
3. Define `$env:GITHUB_TOKEN`, `$env:BRAVE_API_KEY`, etc.
4. Claude Code e MCP servers usam essas variaveis automaticamente

---

## Claude CLI vs Claude Desktop

### Claude CLI (`~/.claude/`)

O CLI usa a pasta `~/.claude/` para tudo. Apos o setup, ela contem:

```
~/.claude/
├── agents/        → Junction → repo/agents/
├── skills/        → Junction → repo/skills/
├── mcp-servers/   → Junction → repo/mcp-servers/
├── commands/      → Junction → repo/commands/    (se existir)
├── hooks/         → Junction → repo/hooks/       (se existir)
├── rules/         → Junction → repo/rules/       (se existir)
├── settings.json  → Symlink/Copy → repo/windows/settings.json
├── logs/          (criado pelo setup)
├── projects/      (criado pelo setup)
├── cache/         (criado pelo setup)
└── ... (arquivos auto-gerados pelo Claude Code)
```

**settings.json** inclui:
- Permissions: git, dotnet, npm, python, curl, etc.
- Plugins: frontend-design, context7, superpowers, code-review, skill-creator
- Env: `CLAUDE_CODE_USE_POWERSHELL_TOOL=1`

### Claude Desktop (`%APPDATA%\Claude\`)

O Desktop usa um arquivo `claude_desktop_config.json` separado com MCP servers:

| MCP Server | Funcao |
|---|---|
| `sqlserver` | Acesso direto ao SQL Server via MCP |
| `azure-devops` | Projetos, PRs, work items do Azure DevOps |
| `memory` | Knowledge graph persistente |
| `deskmanager` | Chamados e integracao Desk Manager |
| `mcp-obsidian` | Acesso ao vault do Obsidian |

O `setup-desktop.ps1` gera esse arquivo a partir do template em `windows/claude_desktop_config.template.json`, substituindo placeholders `{{VARIAVEL}}` por valores do Credential Manager.

Para atualizar o config do Desktop:
```powershell
.\windows\setup-desktop.ps1
# Reinicie o Claude Desktop apos alterar
```

---

## Sincronizacao

### Auto-sync (Task Scheduler)

Uma tarefa agendada roda a cada **3 minutos**:
1. Verifica se ha mudancas locais (agents, skills, configs editados)
2. Se houver: `git add -A` + `git commit`
3. `git pull --rebase` (pega mudancas remotas)
4. `git push` (envia mudancas locais)

```powershell
# Ver status da tarefa
Get-ScheduledTask -TaskName "ClaudeSetupSync"

# Ver log do ultimo sync
Get-Content $env:TEMP\claude-setup-sync.log

# Remover auto-sync
.\windows\setup-task-scheduler.ps1 -Remove

# Reinstalar auto-sync
.\windows\setup-task-scheduler.ps1
```

### Sync manual (claude-sync)

O comando `claude-sync` e instalado em `~/.local/bin/`:

```powershell
claude-sync status          # Ver mudancas pendentes + ultimos commits
claude-sync push            # Commit + push manual
claude-sync pull            # Pull manual
claude-sync pull-upstream   # Merge do repo original (seus arquivos prevalecem)
```

### Sync com repositorio upstream

Se este repo e um fork do original (`escotilha/claude-public`):

```powershell
# Incorporar novidades do repo original
claude-sync pull-upstream
```

Isso faz `git merge upstream/main --strategy-option ours`:
- **Novos** agents/skills do upstream sao adicionados automaticamente
- Seus arquivos **nunca sao sobrescritos** — em caso de conflito, a versao LOCAL prevalece
- E um merge manual e consciente (nao automatico)

---

## Estrutura de pastas

```
~/.claude-setup/                          ← Este repositorio
├── agents/                               ← Definicoes de agentes (.md)
│   ├── api-agent.md
│   ├── backend-agent.md
│   ├── claude-config-helper.md
│   ├── database-agent.md
│   ├── devops-agent.md
│   ├── frontend-agent.md
│   ├── fulltesting-agent.md
│   ├── orchestrator-fullstack.md
│   ├── performance-agent.md
│   ├── project-orchestrator.md
│   ├── security-agent.md
│   └── review/code-review-agent.md
├── skills/                               ← Skills invocaveis (~50)
│   ├── kpl-estimativa/
│   ├── kpl-legacy-manager/
│   ├── website-design/
│   ├── deep-research/
│   └── ... (mais ~45 skills)
├── mcp-servers/                          ← MCP servers locais
│   ├── deskmanager-mcp.js
│   └── package.json
├── windows/                              ← Scripts de setup Windows
│   ├── install.ps1
│   ├── helpers.ps1
│   ├── setup-symlinks.ps1
│   ├── setup-credentials.ps1
│   ├── load-secrets.ps1
│   ├── setup-mcp-servers.ps1
│   ├── setup-task-scheduler.ps1
│   ├── setup-desktop.ps1
│   ├── claude-auto-sync.ps1
│   ├── settings.json
│   ├── claude_desktop_config.template.json
│   └── README.md                         ← Este arquivo
├── .github/workflows/                    ← CI/CD
├── install.sh                            ← Instalador Mac (referencia)
├── setup-*.sh                            ← Scripts Mac (referencia)
└── .gitignore
```

---

## Troubleshooting

### "Running scripts is disabled on this system"

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Symlinks nao funcionam para settings.json

O `settings.json` e um **arquivo** (nao diretorio). Symlinks de arquivo precisam de Developer Mode.

**Solucao:** Ative Developer Mode em Configuracoes > Sistema > Para Desenvolvedores.

Sem Developer Mode, o `settings.json` sera **copiado** (nao linkado). Mudancas no repo nao refletirao automaticamente — rode `.\windows\install.ps1` novamente para atualizar.

### Junctions nao aparecem no Explorer

Junctions NTFS sao transparentes para o Explorer — voce navega normalmente em `~/.claude/agents/` e ve os arquivos do repo. Para confirmar que sao junctions:

```powershell
Get-Item "$env:USERPROFILE\.claude\agents" | Select-Object Name, LinkType, Target
```

### Task Scheduler nao esta rodando

```powershell
# Verificar
Get-ScheduledTask -TaskName "ClaudeSetupSync" | Format-List

# Se nao existir, reinstalar
.\windows\setup-task-scheduler.ps1

# Se existir mas nao rodar, verificar log
Get-Content $env:TEMP\claude-setup-sync.log -Tail 20
```

### Credenciais nao carregam ao abrir terminal

Verifique se o `$PROFILE` existe e tem a linha de load-secrets:

```powershell
# Verificar
Test-Path $PROFILE
Select-String "load-secrets" $PROFILE

# Se nao tiver, adicionar manualmente
Add-Content $PROFILE '. "$env:USERPROFILE\.claude-setup\windows\load-secrets.ps1"'
```

### Claude Desktop MCP servers com erro

1. Reconfigure credenciais: `.\windows\setup-credentials.ps1`
2. Regere o config: `.\windows\setup-desktop.ps1`
3. Reinicie o Claude Desktop

### "git is not recognized" no Task Scheduler

O Task Scheduler roda em ambiente limpo. O script `claude-auto-sync.ps1` ja adiciona paths comuns do Git ao PATH, mas se o Git estiver em local nao-padrao:

```powershell
# Encontrar onde o Git esta
Get-Command git | Select-Object Source
```

Se necessario, edite `claude-auto-sync.ps1` e adicione o caminho.

### Restaurar tudo ao estado anterior

```powershell
# Remove junctions e restaura backup
.\windows\setup-symlinks.ps1 -Restore

# Remove tarefa agendada
.\windows\setup-task-scheduler.ps1 -Remove

# Remover linhas do $PROFILE manualmente se necessario
notepad $PROFILE
```

---

## Referencia rapida

```powershell
# === Setup ===
.\windows\install.ps1                    # Instalacao completa (9 etapas)
.\windows\setup-credentials.ps1          # Configurar secrets
.\windows\setup-credentials.ps1 -Check   # Verificar secrets
.\windows\setup-desktop.ps1              # Atualizar config do Claude Desktop

# === Sync ===
claude-sync status                        # Ver mudancas pendentes
claude-sync push                          # Enviar mudancas
claude-sync pull                          # Puxar mudancas
claude-sync pull-upstream                 # Merge do repo original

# === Verificacao ===
Get-ScheduledTask -TaskName "ClaudeSetupSync"    # Task Scheduler
cmdkey /list:claude-code-*                        # Credenciais
Get-Content $env:TEMP\claude-setup-sync.log       # Log do sync

# === Recuperacao ===
.\windows\setup-symlinks.ps1 -Restore    # Restaurar backup
.\windows\setup-task-scheduler.ps1 -Remove # Remover auto-sync
```

## Comparacao Mac vs Windows

| Funcionalidade | Mac | Windows |
|---|---|---|
| Secrets | macOS Keychain + iCloud Keychain | Windows Credential Manager |
| Auto-sync | launchd plist (3 min) | Task Scheduler (3 min) |
| Symlinks (dirs) | `ln -s` | NTFS Junctions |
| Symlinks (files) | `ln -s` | Symlink (Developer Mode) ou Copy |
| Cloud sync | iCloud Drive | Git-only (push/pull) |
| Notificacoes | osascript | System.Windows.Forms |
| Shell profile | .zshrc / .bashrc | PowerShell `$PROFILE` |
| Package manager | brew | winget |
| Instalador | `install.sh` | `install.ps1` |
