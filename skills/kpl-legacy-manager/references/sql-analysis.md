# Regras de Análise - SQL Server

## Sumário
1. [Integridade de Dados](#integridade-de-dados)
2. [Performance/Índices](#performanceíndices)
3. [Stored Procedures](#stored-procedures)
4. [Tipos de Dados](#tipos-de-dados)
5. [Segurança](#segurança)
6. [Boas Práticas](#boas-práticas)

---

## Integridade de Dados

### SQL-001: Tabela sem chave primária
**Risco:** Alto | **Esforço:** Médio

**Query de detecção:**
```sql
SELECT t.name AS TableName
FROM sys.tables t
LEFT JOIN sys.indexes i ON t.object_id = i.object_id AND i.is_primary_key = 1
WHERE i.object_id IS NULL
  AND t.type = 'U';
```

### SQL-002: Foreign Key ausente em relacionamento óbvio
**Risco:** Alto | **Esforço:** Médio

**Heurística:** Colunas terminadas em `_ID`, `ID_`, `COD_`, `_COD` que não possuem FK.

**Query auxiliar:**
```sql
SELECT c.TABLE_NAME, c.COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE k 
  ON c.TABLE_NAME = k.TABLE_NAME AND c.COLUMN_NAME = k.COLUMN_NAME
WHERE (c.COLUMN_NAME LIKE '%_ID' OR c.COLUMN_NAME LIKE 'ID_%' 
       OR c.COLUMN_NAME LIKE 'COD_%' OR c.COLUMN_NAME LIKE '%_COD')
  AND k.COLUMN_NAME IS NULL;
```

### SQL-003: Coluna NOT NULL sem DEFAULT
**Risco:** Médio | **Esforço:** Baixo

**Detectar:** Colunas `NOT NULL` que não são PK/FK e não têm valor default.

### SQL-004: Trigger com lógica de negócio complexa
**Risco:** Alto | **Esforço:** Alto

**Detectar:** Triggers com > 50 linhas de código ou múltiplas operações DML.

---

## Performance/Índices

### SQL-010: Coluna em WHERE/JOIN sem índice
**Risco:** Alto | **Esforço:** Médio

**Query para colunas mais usadas em JOINs sem índice:**
```sql
-- Executar com plano de execução para identificar Table Scans
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.index_type_desc,
    ips.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.index_type_desc = 'HEAP';
```

### SQL-011: Índice fragmentado (> 30%)
**Risco:** Médio | **Esforço:** Baixo

**Query:**
```sql
SELECT 
    OBJECT_NAME(ips.object_id) AS TableName,
    i.name AS IndexName,
    ips.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 30
  AND ips.page_count > 1000;
```

### SQL-012: Índice não utilizado
**Risco:** Baixo | **Esforço:** Baixo

**Query:**
```sql
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    ius.user_seeks,
    ius.user_scans,
    ius.user_updates
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats ius 
    ON i.object_id = ius.object_id AND i.index_id = ius.index_id
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
  AND i.is_primary_key = 0
  AND i.is_unique = 0
  AND COALESCE(ius.user_seeks, 0) + COALESCE(ius.user_scans, 0) = 0
  AND COALESCE(ius.user_updates, 0) > 0;
```

### SQL-013: Missing index sugerido pelo SQL Server
**Risco:** Médio | **Esforço:** Médio

**Query:**
```sql
SELECT 
    migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) AS improvement_measure,
    mid.statement AS TableName,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns
FROM sys.dm_db_missing_index_groups mig
JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
ORDER BY improvement_measure DESC;
```

---

## Stored Procedures

### SQL-020: SQL dinâmico sem parametrização
**Risco:** Alto | **Esforço:** Médio

**Padrão a detectar:**
```sql
-- Vulnerável
SET @sql = 'SELECT * FROM Users WHERE ID = ' + @ID
EXEC(@sql)
```

**Correção:**
```sql
SET @sql = N'SELECT * FROM Users WHERE ID = @ID'
EXEC sp_executesql @sql, N'@ID INT', @ID = @ID
```

### SQL-021: Cursor com comportamento default
**Risco:** Médio | **Esforço:** Baixo

**Detectar:**
```sql
DECLARE cursor_name CURSOR FOR SELECT ...  -- Sem FAST_FORWARD/LOCAL
```

**Correção:**
```sql
DECLARE cursor_name CURSOR LOCAL FAST_FORWARD FOR SELECT ...
```

### SQL-022: Procedure sem SET NOCOUNT ON
**Risco:** Baixo | **Esforço:** Baixo

**Detectar:** Procedures sem `SET NOCOUNT ON` no início.

### SQL-023: Transaction sem TRY/CATCH
**Risco:** Alto | **Esforço:** Médio

**Detectar:** `BEGIN TRANSACTION` sem bloco `TRY/CATCH` correspondente.

### SQL-024: RAISERROR sem THROW
**Risco:** Baixo | **Esforço:** Baixo

**Detectar:** Uso de `RAISERROR` que poderia ser modernizado para `THROW` (SQL 2012+).

---

## Tipos de Dados

### SQL-030: Tipo TEXT/NTEXT/IMAGE (obsoletos)
**Risco:** Alto | **Esforço:** Médio

**Query:**
```sql
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE DATA_TYPE IN ('text', 'ntext', 'image');
```

**Substituição:**
- `text` → `varchar(max)`
- `ntext` → `nvarchar(max)`
- `image` → `varbinary(max)`

### SQL-031: DATETIME usado onde DATE bastaria
**Risco:** Baixo | **Esforço:** Baixo

**Heurística:** Colunas `datetime` com nomes sugerindo apenas data (ex: `DataNascimento`, `DtCadastro`).

### SQL-032: VARCHAR sem tamanho explícito
**Risco:** Médio | **Esforço:** Baixo

**Detectar:** Declarações `VARCHAR` ou `NVARCHAR` sem comprimento (assume 1 ou 30 dependendo do contexto).

### SQL-033: Coluna numérica para valores monetários
**Risco:** Médio | **Esforço:** Médio

**Detectar:** `FLOAT` ou `REAL` para colunas com nomes sugerindo valores monetários.

**Substituição:** `DECIMAL(18,2)` ou `MONEY`

---

## Segurança

### SQL-040: Permissões excessivas
**Risco:** Alto | **Esforço:** Médio

**Query:**
```sql
SELECT pr.name AS PrincipalName,
       pe.permission_name,
       pe.state_desc
FROM sys.database_permissions pe
JOIN sys.database_principals pr ON pe.grantee_principal_id = pr.principal_id
WHERE pe.permission_name IN ('CONTROL', 'ALTER ANY', 'EXECUTE AS')
  OR pe.state_desc = 'GRANT_WITH_GRANT_OPTION';
```

### SQL-041: Login com sysadmin
**Risco:** Alto | **Esforço:** Médio

**Query:**
```sql
SELECT name FROM sys.server_principals 
WHERE IS_SRVROLEMEMBER('sysadmin', name) = 1
  AND name NOT IN ('sa', 'NT AUTHORITY\SYSTEM');
```

### SQL-042: Database owner não é SA
**Risco:** Médio | **Esforço:** Baixo

**Query:**
```sql
SELECT name, SUSER_SNAME(owner_sid) AS Owner
FROM sys.databases
WHERE SUSER_SNAME(owner_sid) <> 'sa';
```

---

## Boas Práticas

### SQL-050: Procedure sem schema explícito
**Risco:** Baixo | **Esforço:** Baixo

**Detectar:** `EXEC ProcName` ao invés de `EXEC dbo.ProcName`

### SQL-051: SELECT *
**Risco:** Médio | **Esforço:** Baixo

**Detectar:** `SELECT *` em procedures e views (não em consultas ad-hoc).

### SQL-052: ORDER BY em View
**Risco:** Baixo | **Esforço:** Baixo

**Detectar:** Views com `ORDER BY` (geralmente desnecessário e ignorado).

### SQL-053: IDENTITY overflow potencial
**Risco:** Alto | **Esforço:** Médio

**Query:**
```sql
SELECT 
    OBJECT_NAME(object_id) AS TableName,
    name AS ColumnName,
    TYPE_NAME(system_type_id) AS DataType,
    IDENT_CURRENT(OBJECT_NAME(object_id)) AS CurrentValue,
    CASE TYPE_NAME(system_type_id)
        WHEN 'int' THEN 2147483647
        WHEN 'smallint' THEN 32767
        WHEN 'tinyint' THEN 255
        WHEN 'bigint' THEN 9223372036854775807
    END AS MaxValue,
    CAST(IDENT_CURRENT(OBJECT_NAME(object_id)) AS FLOAT) / 
    CASE TYPE_NAME(system_type_id)
        WHEN 'int' THEN 2147483647.0
        WHEN 'smallint' THEN 32767.0
        WHEN 'tinyint' THEN 255.0
        WHEN 'bigint' THEN 9223372036854775807.0
    END * 100 AS PercentUsed
FROM sys.identity_columns
WHERE IDENT_CURRENT(OBJECT_NAME(object_id)) IS NOT NULL
ORDER BY PercentUsed DESC;
```

---

## Diagrama ER Simplificado (Formato Texto)

Ao gerar diagrama, usar formato:

```
[TABELA_A]
├── PK: ID_A (int)
├── COL1 (varchar)
└── FK: ID_B → TABELA_B

[TABELA_B]
├── PK: ID_B (int)
├── COL2 (datetime)
└── FK: ID_C → TABELA_C

Relacionamentos:
TABELA_A 1──N TABELA_B (via ID_B)
TABELA_B N──1 TABELA_C (via ID_C)
```

---

## Priorização

| Categoria | Regras | Prioridade |
|-----------|--------|------------|
| Segurança | SQL-020, 040, 041 | 🔴 Crítica |
| Integridade | SQL-001, 002, 023 | 🔴 Alta |
| Tipos obsoletos | SQL-030 | 🟠 Alta |
| Performance crítica | SQL-010, 013 | 🟠 Alta |
| Identity overflow | SQL-053 | 🟠 Alta |
| Performance geral | SQL-011, 012, 021 | 🟡 Média |
| Boas práticas | SQL-050, 051, 052 | 🟢 Baixa |
