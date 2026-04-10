#!/usr/bin/env python3
"""
KPL Database Schema Analyzer
Extrai schema e analisa problemas em banco SQL Server.
Requer: pyodbc ou conexão via MCP server.
"""

import json
from datetime import datetime
from typing import Dict, List, Optional
from dataclasses import dataclass, asdict
from collections import defaultdict

@dataclass
class Column:
    name: str
    data_type: str
    max_length: Optional[int]
    is_nullable: bool
    is_identity: bool
    has_default: bool

@dataclass
class Table:
    schema: str
    name: str
    columns: List[Column]
    row_count: int
    has_pk: bool
    pk_columns: List[str]
    foreign_keys: List[dict]
    indexes: List[dict]

@dataclass
class Issue:
    category: str
    severity: str  # 'critical', 'high', 'medium', 'low'
    object_type: str
    object_name: str
    description: str
    recommendation: str


# Queries para extração de schema (SQL Server)
SCHEMA_QUERIES = {
    'tables': """
        SELECT 
            s.name AS schema_name,
            t.name AS table_name,
            p.rows AS row_count
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
        WHERE t.type = 'U'
        ORDER BY s.name, t.name
    """,
    
    'columns': """
        SELECT 
            s.name AS schema_name,
            t.name AS table_name,
            c.name AS column_name,
            ty.name AS data_type,
            c.max_length,
            c.is_nullable,
            c.is_identity,
            CASE WHEN dc.object_id IS NOT NULL THEN 1 ELSE 0 END AS has_default
        FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        JOIN sys.types ty ON c.user_type_id = ty.user_type_id
        LEFT JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
        WHERE t.type = 'U'
        ORDER BY s.name, t.name, c.column_id
    """,
    
    'primary_keys': """
        SELECT 
            s.name AS schema_name,
            t.name AS table_name,
            c.name AS column_name
        FROM sys.key_constraints kc
        JOIN sys.tables t ON kc.parent_object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        JOIN sys.index_columns ic ON kc.parent_object_id = ic.object_id 
            AND kc.unique_index_id = ic.index_id
        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE kc.type = 'PK'
        ORDER BY s.name, t.name, ic.key_ordinal
    """,
    
    'foreign_keys': """
        SELECT 
            s.name AS schema_name,
            t.name AS table_name,
            fk.name AS fk_name,
            c.name AS column_name,
            rs.name AS ref_schema,
            rt.name AS ref_table,
            rc.name AS ref_column
        FROM sys.foreign_keys fk
        JOIN sys.tables t ON fk.parent_object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
        JOIN sys.columns c ON fkc.parent_object_id = c.object_id 
            AND fkc.parent_column_id = c.column_id
        JOIN sys.tables rt ON fkc.referenced_object_id = rt.object_id
        JOIN sys.schemas rs ON rt.schema_id = rs.schema_id
        JOIN sys.columns rc ON fkc.referenced_object_id = rc.object_id 
            AND fkc.referenced_column_id = rc.column_id
        ORDER BY s.name, t.name, fk.name
    """,
    
    'indexes': """
        SELECT 
            s.name AS schema_name,
            t.name AS table_name,
            i.name AS index_name,
            i.type_desc,
            i.is_unique,
            i.is_primary_key,
            STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS columns
        FROM sys.indexes i
        JOIN sys.tables t ON i.object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE t.type = 'U' AND i.name IS NOT NULL
        GROUP BY s.name, t.name, i.name, i.type_desc, i.is_unique, i.is_primary_key
        ORDER BY s.name, t.name, i.name
    """,
    
    'procedures': """
        SELECT 
            s.name AS schema_name,
            p.name AS proc_name,
            p.create_date,
            p.modify_date
        FROM sys.procedures p
        JOIN sys.schemas s ON p.schema_id = s.schema_id
        ORDER BY s.name, p.name
    """,
    
    'obsolete_types': """
        SELECT 
            s.name AS schema_name,
            t.name AS table_name,
            c.name AS column_name,
            ty.name AS data_type
        FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        JOIN sys.types ty ON c.user_type_id = ty.user_type_id
        WHERE ty.name IN ('text', 'ntext', 'image')
        ORDER BY s.name, t.name
    """,
    
    'tables_without_pk': """
        SELECT 
            s.name AS schema_name,
            t.name AS table_name
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        LEFT JOIN sys.key_constraints kc ON t.object_id = kc.parent_object_id AND kc.type = 'PK'
        WHERE t.type = 'U' AND kc.object_id IS NULL
        ORDER BY s.name, t.name
    """,
    
    'identity_usage': """
        SELECT 
            OBJECT_SCHEMA_NAME(ic.object_id) AS schema_name,
            OBJECT_NAME(ic.object_id) AS table_name,
            ic.name AS column_name,
            TYPE_NAME(ic.system_type_id) AS data_type,
            IDENT_CURRENT(OBJECT_SCHEMA_NAME(ic.object_id) + '.' + OBJECT_NAME(ic.object_id)) AS current_value,
            CASE TYPE_NAME(ic.system_type_id)
                WHEN 'int' THEN 2147483647
                WHEN 'smallint' THEN 32767
                WHEN 'tinyint' THEN 255
                WHEN 'bigint' THEN 9223372036854775807
            END AS max_value
        FROM sys.identity_columns ic
        WHERE IDENT_CURRENT(OBJECT_SCHEMA_NAME(ic.object_id) + '.' + OBJECT_NAME(ic.object_id)) IS NOT NULL
    """,
    
    'missing_indexes': """
        SELECT TOP 20
            migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) AS improvement_measure,
            OBJECT_SCHEMA_NAME(mid.object_id) AS schema_name,
            OBJECT_NAME(mid.object_id) AS table_name,
            mid.equality_columns,
            mid.inequality_columns,
            mid.included_columns
        FROM sys.dm_db_missing_index_groups mig
        JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
        JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
        WHERE mid.database_id = DB_ID()
        ORDER BY improvement_measure DESC
    """
}


def analyze_schema(query_executor) -> Dict:
    """
    Analisa schema do banco usando um executor de queries.
    
    Args:
        query_executor: Função que executa queries e retorna resultados como lista de dicts
    
    Returns:
        Dict com schema completo e issues identificados
    """
    result = {
        'timestamp': datetime.now().isoformat(),
        'tables': [],
        'procedures': [],
        'issues': [],
        'summary': {}
    }
    
    # Executar queries e coletar dados
    tables_data = query_executor(SCHEMA_QUERIES['tables'])
    columns_data = query_executor(SCHEMA_QUERIES['columns'])
    pk_data = query_executor(SCHEMA_QUERIES['primary_keys'])
    fk_data = query_executor(SCHEMA_QUERIES['foreign_keys'])
    indexes_data = query_executor(SCHEMA_QUERIES['indexes'])
    procedures_data = query_executor(SCHEMA_QUERIES['procedures'])
    
    # Organizar dados por tabela
    tables_map = {}
    for row in tables_data:
        key = f"{row['schema_name']}.{row['table_name']}"
        tables_map[key] = {
            'schema': row['schema_name'],
            'name': row['table_name'],
            'row_count': row['row_count'],
            'columns': [],
            'pk_columns': [],
            'foreign_keys': [],
            'indexes': []
        }
    
    # Adicionar colunas
    for row in columns_data:
        key = f"{row['schema_name']}.{row['table_name']}"
        if key in tables_map:
            tables_map[key]['columns'].append({
                'name': row['column_name'],
                'data_type': row['data_type'],
                'max_length': row['max_length'],
                'is_nullable': row['is_nullable'],
                'is_identity': row['is_identity'],
                'has_default': row['has_default']
            })
    
    # Adicionar PKs
    for row in pk_data:
        key = f"{row['schema_name']}.{row['table_name']}"
        if key in tables_map:
            tables_map[key]['pk_columns'].append(row['column_name'])
    
    # Adicionar FKs
    for row in fk_data:
        key = f"{row['schema_name']}.{row['table_name']}"
        if key in tables_map:
            tables_map[key]['foreign_keys'].append({
                'name': row['fk_name'],
                'column': row['column_name'],
                'ref_table': f"{row['ref_schema']}.{row['ref_table']}",
                'ref_column': row['ref_column']
            })
    
    # Adicionar índices
    for row in indexes_data:
        key = f"{row['schema_name']}.{row['table_name']}"
        if key in tables_map:
            tables_map[key]['indexes'].append({
                'name': row['index_name'],
                'type': row['type_desc'],
                'is_unique': row['is_unique'],
                'columns': row['columns']
            })
    
    result['tables'] = list(tables_map.values())
    result['procedures'] = procedures_data
    
    # Identificar issues
    issues = []
    
    # 1. Tabelas sem PK
    tables_without_pk = query_executor(SCHEMA_QUERIES['tables_without_pk'])
    for row in tables_without_pk:
        issues.append({
            'category': 'integrity',
            'severity': 'high',
            'object_type': 'table',
            'object_name': f"{row['schema_name']}.{row['table_name']}",
            'description': 'Tabela sem chave primária',
            'recommendation': 'Definir chave primária para garantir integridade e performance'
        })
    
    # 2. Tipos obsoletos
    obsolete_types = query_executor(SCHEMA_QUERIES['obsolete_types'])
    for row in obsolete_types:
        issues.append({
            'category': 'obsolete',
            'severity': 'high',
            'object_type': 'column',
            'object_name': f"{row['schema_name']}.{row['table_name']}.{row['column_name']}",
            'description': f"Tipo de dados obsoleto: {row['data_type']}",
            'recommendation': f"Migrar para {'varchar(max)' if row['data_type'] == 'text' else 'nvarchar(max)' if row['data_type'] == 'ntext' else 'varbinary(max)'}"
        })
    
    # 3. Identity perto do limite
    identity_usage = query_executor(SCHEMA_QUERIES['identity_usage'])
    for row in identity_usage:
        if row['current_value'] and row['max_value']:
            percent_used = (row['current_value'] / row['max_value']) * 100
            if percent_used > 70:
                issues.append({
                    'category': 'capacity',
                    'severity': 'critical' if percent_used > 90 else 'high',
                    'object_type': 'column',
                    'object_name': f"{row['schema_name']}.{row['table_name']}.{row['column_name']}",
                    'description': f"Identity em {percent_used:.1f}% da capacidade ({row['data_type']})",
                    'recommendation': 'Considerar migração para BIGINT antes de overflow'
                })
    
    # 4. Missing indexes sugeridos
    missing_indexes = query_executor(SCHEMA_QUERIES['missing_indexes'])
    for row in missing_indexes:
        if row['improvement_measure'] > 10000:
            issues.append({
                'category': 'performance',
                'severity': 'medium',
                'object_type': 'table',
                'object_name': f"{row['schema_name']}.{row['table_name']}",
                'description': f"Índice sugerido: {row['equality_columns'] or ''} {row['inequality_columns'] or ''}",
                'recommendation': f"Criar índice. Impacto estimado: {row['improvement_measure']:.0f}"
            })
    
    # 5. Colunas que parecem FK mas não têm constraint
    for key, table in tables_map.items():
        fk_columns = {fk['column'] for fk in table['foreign_keys']}
        for col in table['columns']:
            col_name = col['name'].upper()
            # Padrões comuns de FK
            if (col_name.endswith('_ID') or col_name.endswith('ID') or 
                col_name.startswith('ID_') or col_name.startswith('COD_') or
                col_name.endswith('_COD')):
                if col['name'] not in fk_columns and col['name'] not in table['pk_columns']:
                    issues.append({
                        'category': 'integrity',
                        'severity': 'medium',
                        'object_type': 'column',
                        'object_name': f"{key}.{col['name']}",
                        'description': 'Coluna parece ser FK mas não tem constraint',
                        'recommendation': 'Verificar se deveria ter Foreign Key constraint'
                    })
    
    result['issues'] = issues
    
    # Summary
    result['summary'] = {
        'total_tables': len(result['tables']),
        'total_procedures': len(result['procedures']),
        'total_issues': len(issues),
        'issues_by_severity': {
            'critical': len([i for i in issues if i['severity'] == 'critical']),
            'high': len([i for i in issues if i['severity'] == 'high']),
            'medium': len([i for i in issues if i['severity'] == 'medium']),
            'low': len([i for i in issues if i['severity'] == 'low'])
        }
    }
    
    return result


def format_db_report(analysis: Dict) -> str:
    """Formata análise como relatório texto."""
    lines = []
    lines.append("=" * 50)
    lines.append("KPL DATABASE REPORT")
    lines.append("=" * 50)
    lines.append(f"Data: {analysis['timestamp']}")
    lines.append("")
    
    # Summary
    summary = analysis['summary']
    lines.append("📊 RESUMO")
    lines.append("-" * 30)
    lines.append(f"Tabelas: {summary['total_tables']}")
    lines.append(f"Procedures: {summary['total_procedures']}")
    lines.append(f"Issues identificados: {summary['total_issues']}")
    lines.append(f"  - Críticos: {summary['issues_by_severity']['critical']}")
    lines.append(f"  - Altos: {summary['issues_by_severity']['high']}")
    lines.append(f"  - Médios: {summary['issues_by_severity']['medium']}")
    lines.append("")
    
    # Issues por severidade
    if analysis['issues']:
        lines.append("⚠️ PROBLEMAS IDENTIFICADOS")
        lines.append("-" * 30)
        
        for severity in ['critical', 'high', 'medium', 'low']:
            issues = [i for i in analysis['issues'] if i['severity'] == severity]
            if issues:
                severity_label = {
                    'critical': '🔴 CRÍTICO',
                    'high': '🟠 ALTO',
                    'medium': '🟡 MÉDIO',
                    'low': '🟢 BAIXO'
                }[severity]
                
                lines.append(f"\n{severity_label}")
                for issue in issues[:5]:  # Limitar a 5 por severidade
                    lines.append(f"  • [{issue['object_name']}] {issue['description']}")
                    lines.append(f"    → {issue['recommendation']}")
                
                if len(issues) > 5:
                    lines.append(f"  ... e mais {len(issues) - 5} issues")
    
    # Top 10 tabelas por tamanho
    lines.append("")
    lines.append("📈 MAIORES TABELAS")
    lines.append("-" * 30)
    sorted_tables = sorted(analysis['tables'], key=lambda t: t['row_count'], reverse=True)[:10]
    for table in sorted_tables:
        lines.append(f"  {table['schema']}.{table['name']}: {table['row_count']:,} linhas")
    
    return '\n'.join(lines)


def generate_er_diagram(tables: List[Dict]) -> str:
    """Gera diagrama ER simplificado em texto."""
    lines = []
    lines.append("DIAGRAMA ER (Simplificado)")
    lines.append("=" * 40)
    lines.append("")
    
    # Tabelas
    for table in tables[:20]:  # Limitar para não ficar muito grande
        lines.append(f"[{table['schema']}.{table['name']}]")
        
        # PK
        if table['pk_columns']:
            lines.append(f"├── PK: {', '.join(table['pk_columns'])}")
        
        # Colunas principais (primeiras 5)
        other_cols = [c for c in table['columns'] if c['name'] not in table['pk_columns']]
        for col in other_cols[:5]:
            nullable = '?' if col['is_nullable'] else ''
            lines.append(f"├── {col['name']}: {col['data_type']}{nullable}")
        
        if len(other_cols) > 5:
            lines.append(f"├── ... (+{len(other_cols) - 5} colunas)")
        
        # FKs
        for fk in table['foreign_keys']:
            lines.append(f"└── FK: {fk['column']} → {fk['ref_table']}")
        
        lines.append("")
    
    # Relacionamentos
    lines.append("RELACIONAMENTOS")
    lines.append("-" * 40)
    
    for table in tables:
        for fk in table['foreign_keys']:
            lines.append(f"{table['schema']}.{table['name']} N──1 {fk['ref_table']} (via {fk['column']})")
    
    return '\n'.join(lines)


# Exemplo de uso com MCP ou pyodbc
if __name__ == '__main__':
    print("Este script deve ser chamado via MCP server ou importado como módulo.")
    print("Queries disponíveis em SCHEMA_QUERIES para execução manual.")
    print("\nExemplo de uso:")
    print("  from db_schema_extractor import analyze_schema, format_db_report")
    print("  result = analyze_schema(mcp_query_executor)")
    print("  print(format_db_report(result))")
