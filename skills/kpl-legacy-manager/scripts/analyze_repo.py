#!/usr/bin/env python3
"""
KPL Repository Analyzer
Analisa repositório legado Delphi/NET/SQL e gera inventário.
"""

import os
import re
import json
from datetime import datetime
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Tuple, Optional

# Extensões por linguagem
EXTENSIONS = {
    'delphi': ['.pas', '.dpr', '.dpk', '.dfm', '.dproj'],
    'dotnet': ['.cs', '.vb', '.csproj', '.vbproj', '.sln', '.config'],
    'sql': ['.sql', '.prc', '.trg', '.vw'],
    'other': ['.txt', '.md', '.xml', '.json', '.ini']
}

# Padrões críticos a detectar
CRITICAL_PATTERNS = {
    'delphi': {
        'bde_usage': [
            (r'\bTTable\b', 'Componente BDE TTable'),
            (r'\bTQuery\b', 'Componente BDE TQuery'),
            (r'\bTDatabase\b', 'Componente BDE TDatabase'),
            (r'\bTSession\b', 'Componente BDE TSession'),
            (r'\bTStoredProc\b', 'Componente BDE TStoredProc'),
        ],
        'memory_leak': [
            (r'\.Create\s*[;(](?!.*\btry\b)', 'Create sem try/finally'),
            (r'\bGetMem\b(?!.*\bFreeMem\b)', 'GetMem potencial sem FreeMem'),
        ],
        'security': [
            (r"SQL\.Text\s*:=\s*'[^']*'\s*\+", 'SQL dinâmico concatenado'),
        ],
        'obsolete': [
            (r'\bShortString\b', 'Uso de ShortString'),
            (r'\bPChar\b.*\bStrPas\b', 'Conversão PChar/StrPas'),
        ]
    },
    'dotnet': {
        'obsolete_api': [
            (r'\bWebClient\b', 'WebClient obsoleto'),
            (r'\bArrayList\b', 'ArrayList não tipado'),
            (r'\bHashtable\b', 'Hashtable não tipado'),
            (r'Thread\.Abort', 'Thread.Abort perigoso'),
        ],
        'async_issues': [
            (r'\.Result\b', 'Acesso síncrono a Task.Result'),
            (r'\.Wait\(\)', 'Chamada Wait() em Task'),
            (r'async\s+void\b(?!.*EventHandler)', 'async void não é event handler'),
        ],
        'security': [
            (r'"SELECT\s+.*"\s*\+', 'SQL concatenado em string'),
            (r'password\s*=\s*"[^"]+"', 'Senha hardcoded'),
        ],
        'exception': [
            (r'catch\s*\(\s*Exception\s+\w+\s*\)\s*\{\s*\}', 'Exception silenciada'),
            (r'throw\s+\w+;', 'throw ex perde stack trace'),
        ]
    },
    'sql': {
        'security': [
            (r"EXEC\s*\(\s*@", 'SQL dinâmico com EXEC'),
            (r"'[^']*'\s*\+\s*@", 'Concatenação de variável em string SQL'),
        ],
        'obsolete': [
            (r'\btext\b', 'Tipo TEXT obsoleto'),
            (r'\bntext\b', 'Tipo NTEXT obsoleto'),
            (r'\bimage\b', 'Tipo IMAGE obsoleto'),
        ],
        'performance': [
            (r'SELECT\s+\*', 'SELECT * em procedure'),
            (r'CURSOR\s+FOR(?!\s+.*FAST_FORWARD)', 'Cursor sem FAST_FORWARD'),
        ]
    }
}


def count_lines(filepath: str) -> Tuple[int, int, int]:
    """Conta linhas totais, código e comentários."""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()
    except:
        return 0, 0, 0
    
    total = len(lines)
    code = 0
    comments = 0
    in_multiline = False
    
    for line in lines:
        stripped = line.strip()
        if not stripped:
            continue
        
        # Delphi/Pascal comments
        if stripped.startswith('//') or stripped.startswith('{') or stripped.startswith('(*'):
            comments += 1
        # C# comments
        elif stripped.startswith('//') or stripped.startswith('/*'):
            comments += 1
        # SQL comments
        elif stripped.startswith('--'):
            comments += 1
        else:
            code += 1
    
    return total, code, comments


def detect_patterns(filepath: str, language: str) -> List[Dict]:
    """Detecta padrões críticos em um arquivo."""
    issues = []
    
    if language not in CRITICAL_PATTERNS:
        return issues
    
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
            lines = content.split('\n')
    except:
        return issues
    
    for category, patterns in CRITICAL_PATTERNS[language].items():
        for pattern, description in patterns:
            for i, line in enumerate(lines, 1):
                if re.search(pattern, line, re.IGNORECASE):
                    issues.append({
                        'file': filepath,
                        'line': i,
                        'category': category,
                        'description': description,
                        'code': line.strip()[:80]
                    })
    
    return issues


def analyze_delphi_project(dpr_path: str) -> Dict:
    """Analisa um projeto Delphi (.dpr)."""
    info = {
        'path': dpr_path,
        'units': [],
        'forms': [],
        'uses': []
    }
    
    try:
        with open(dpr_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # Extrair units do uses
        uses_match = re.search(r'uses\s+(.*?);', content, re.DOTALL | re.IGNORECASE)
        if uses_match:
            uses_text = uses_match.group(1)
            units = re.findall(r'\b(\w+)\b', uses_text)
            info['uses'] = units
        
        # Contar forms
        forms = re.findall(r'\{.*?\.dfm\}', content)
        info['forms'] = len(forms)
        
    except:
        pass
    
    return info


def analyze_dotnet_solution(sln_path: str) -> Dict:
    """Analisa uma solution .NET (.sln)."""
    info = {
        'path': sln_path,
        'projects': [],
        'framework': None
    }
    
    try:
        with open(sln_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # Extrair projetos
        projects = re.findall(r'Project\([^)]+\)\s*=\s*"([^"]+)",\s*"([^"]+)"', content)
        for name, path in projects:
            if path.endswith(('.csproj', '.vbproj')):
                info['projects'].append({'name': name, 'path': path})
        
    except:
        pass
    
    return info


def generate_inventory(repo_path: str) -> Dict:
    """Gera inventário completo do repositório."""
    inventory = {
        'timestamp': datetime.now().isoformat(),
        'repo_path': repo_path,
        'files': defaultdict(list),
        'metrics': {
            'total_files': 0,
            'total_lines': 0,
            'code_lines': 0,
            'by_language': {}
        },
        'projects': {
            'delphi': [],
            'dotnet': []
        },
        'issues': [],
        'critical_points': []
    }
    
    # Mapear extensão para linguagem
    ext_to_lang = {}
    for lang, exts in EXTENSIONS.items():
        for ext in exts:
            ext_to_lang[ext] = lang
    
    # Percorrer repositório
    for root, dirs, files in os.walk(repo_path):
        # Ignorar diretórios comuns
        dirs[:] = [d for d in dirs if d not in ['.git', '.svn', 'bin', 'obj', '__history', 'backup']]
        
        for filename in files:
            filepath = os.path.join(root, filename)
            ext = os.path.splitext(filename)[1].lower()
            
            if ext not in ext_to_lang:
                continue
            
            lang = ext_to_lang[ext]
            rel_path = os.path.relpath(filepath, repo_path)
            
            # Contar linhas
            total, code, comments = count_lines(filepath)
            
            file_info = {
                'path': rel_path,
                'extension': ext,
                'lines': total,
                'code_lines': code
            }
            
            inventory['files'][lang].append(file_info)
            inventory['metrics']['total_files'] += 1
            inventory['metrics']['total_lines'] += total
            inventory['metrics']['code_lines'] += code
            
            # Atualizar métricas por linguagem
            if lang not in inventory['metrics']['by_language']:
                inventory['metrics']['by_language'][lang] = {
                    'files': 0, 'lines': 0, 'code_lines': 0
                }
            inventory['metrics']['by_language'][lang]['files'] += 1
            inventory['metrics']['by_language'][lang]['lines'] += total
            inventory['metrics']['by_language'][lang]['code_lines'] += code
            
            # Detectar padrões críticos
            issues = detect_patterns(filepath, lang)
            inventory['issues'].extend(issues)
            
            # Identificar projetos
            if ext == '.dpr':
                proj_info = analyze_delphi_project(filepath)
                inventory['projects']['delphi'].append(proj_info)
            elif ext == '.sln':
                sln_info = analyze_dotnet_solution(filepath)
                inventory['projects']['dotnet'].append(sln_info)
    
    # Consolidar pontos críticos
    issue_summary = defaultdict(int)
    for issue in inventory['issues']:
        key = f"{issue['category']}:{issue['description']}"
        issue_summary[key] += 1
    
    for key, count in sorted(issue_summary.items(), key=lambda x: -x[1])[:10]:
        cat, desc = key.split(':', 1)
        risk = 'Alto' if cat in ['security', 'bde_usage', 'memory_leak'] else 'Médio'
        inventory['critical_points'].append({
            'description': f"{count}x {desc}",
            'risk': risk,
            'category': cat
        })
    
    return inventory


def format_inventory_report(inventory: Dict) -> str:
    """Formata inventário como relatório texto."""
    lines = []
    lines.append("=" * 50)
    lines.append("KPL INVENTÁRIO")
    lines.append("=" * 50)
    lines.append(f"Data: {inventory['timestamp']}")
    lines.append(f"Repositório: {inventory['repo_path']}")
    lines.append("")
    
    lines.append("📊 MÉTRICAS")
    lines.append("-" * 30)
    
    metrics = inventory['metrics']
    by_lang = metrics['by_language']
    
    if 'delphi' in by_lang:
        d = by_lang['delphi']
        lines.append(f"Arquivos Delphi: {d['files']} ({d['code_lines']:,} linhas de código)")
    
    if 'dotnet' in by_lang:
        d = by_lang['dotnet']
        lines.append(f"Arquivos .NET: {d['files']} ({d['code_lines']:,} linhas de código)")
    
    if 'sql' in by_lang:
        d = by_lang['sql']
        lines.append(f"Scripts SQL: {d['files']} ({d['code_lines']:,} linhas)")
    
    lines.append(f"\nTotal: {metrics['total_files']} arquivos, {metrics['code_lines']:,} linhas de código")
    
    # Projetos
    lines.append("")
    lines.append("📁 PROJETOS")
    lines.append("-" * 30)
    
    if inventory['projects']['delphi']:
        lines.append(f"Projetos Delphi: {len(inventory['projects']['delphi'])}")
        for proj in inventory['projects']['delphi'][:5]:
            lines.append(f"  • {os.path.basename(proj['path'])}")
    
    if inventory['projects']['dotnet']:
        lines.append(f"Solutions .NET: {len(inventory['projects']['dotnet'])}")
        for sln in inventory['projects']['dotnet'][:5]:
            lines.append(f"  • {os.path.basename(sln['path'])} ({len(sln['projects'])} projetos)")
    
    # Pontos críticos
    if inventory['critical_points']:
        lines.append("")
        lines.append("⚠️ PONTOS CRÍTICOS")
        lines.append("-" * 30)
        for i, point in enumerate(inventory['critical_points'][:5], 1):
            lines.append(f"{i}. {point['description']} - Risco: {point['risk']}")
    
    # Ações recomendadas
    lines.append("")
    lines.append("🎯 AÇÕES RECOMENDADAS")
    lines.append("-" * 30)
    
    # Gerar recomendações baseadas nos issues encontrados
    recommendations = []
    
    has_bde = any(p['category'] == 'bde_usage' for p in inventory['critical_points'])
    has_sql_injection = any('SQL' in p['description'] for p in inventory['critical_points'])
    has_memory = any(p['category'] == 'memory_leak' for p in inventory['critical_points'])
    has_obsolete = any(p['category'] == 'obsolete_api' for p in inventory['critical_points'])
    
    if has_bde:
        recommendations.append("1. Migrar componentes BDE para ADO/dbExpress (prioridade alta)")
    if has_sql_injection:
        recommendations.append("2. Parametrizar queries SQL para evitar injeção")
    if has_memory:
        recommendations.append("3. Revisar alocações de memória e adicionar try/finally")
    if has_obsolete:
        recommendations.append("4. Atualizar APIs obsoletas do .NET")
    
    if not recommendations:
        recommendations = [
            "1. Documentar arquitetura atual do sistema",
            "2. Criar testes automatizados para módulos críticos",
            "3. Refatorar código com alta complexidade"
        ]
    
    for rec in recommendations[:3]:
        lines.append(rec)
    
    return '\n'.join(lines)


if __name__ == '__main__':
    import sys
    
    if len(sys.argv) < 2:
        print("Uso: python analyze_repo.py <caminho_repositorio>")
        sys.exit(1)
    
    repo_path = sys.argv[1]
    
    if not os.path.isdir(repo_path):
        print(f"Erro: {repo_path} não é um diretório válido")
        sys.exit(1)
    
    print(f"Analisando repositório: {repo_path}")
    print("Aguarde...")
    
    inventory = generate_inventory(repo_path)
    
    # Gerar relatório
    report = format_inventory_report(inventory)
    print(report)
    
    # Salvar JSON detalhado
    output_json = os.path.join(os.path.dirname(__file__), 'inventory_result.json')
    with open(output_json, 'w', encoding='utf-8') as f:
        # Converter defaultdict para dict
        inventory['files'] = dict(inventory['files'])
        json.dump(inventory, f, indent=2, ensure_ascii=False)
    
    print(f"\nDetalhes salvos em: {output_json}")
