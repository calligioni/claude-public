# Regras de Análise Estática - Delphi 5

## Sumário
1. [Vazamentos de Memória](#vazamentos-de-memória)
2. [Código Morto](#código-morto)
3. [Componentes Obsoletos](#componentes-obsoletos)
4. [Manipulação de Strings](#manipulação-de-strings)
5. [Acesso a Dados](#acesso-a-dados)
6. [Tratamento de Exceções](#tratamento-de-exceções)
7. [Padrões de Código](#padrões-de-código)

---

## Vazamentos de Memória

### DELPHI-001: Create sem Free correspondente
**Risco:** Alto | **Esforço:** Médio

**Padrão a detectar:**
```delphi
// Problema: objeto criado sem garantia de liberação
MyObj := TMyClass.Create;
MyObj.DoSomething;
// Free ausente ou fora de try/finally
```

**Correção sugerida:**
```delphi
MyObj := TMyClass.Create;
try
  MyObj.DoSomething;
finally
  MyObj.Free;
end;
```

### DELPHI-002: GetMem/AllocMem sem FreeMem
**Risco:** Alto | **Esforço:** Médio

**Detectar:** Chamadas a `GetMem`, `AllocMem`, `ReallocMem` sem `FreeMem` correspondente no mesmo escopo ou destructor.

### DELPHI-003: Strings não liberadas em PChar
**Risco:** Médio | **Esforço:** Baixo

**Detectar:** Conversões `StrAlloc`, `StrNew` sem `StrDispose`.

---

## Código Morto

### DELPHI-010: Procedures/Functions não referenciadas
**Risco:** Baixo | **Esforço:** Baixo

**Heurística:** Buscar declarações em `interface` ou `implementation` sem chamadas no projeto.

### DELPHI-011: Variáveis declaradas não utilizadas
**Risco:** Baixo | **Esforço:** Baixo

**Detectar:** Variáveis em seção `var` sem referência no corpo do procedimento.

### DELPHI-012: Units em uses não utilizadas
**Risco:** Baixo | **Esforço:** Baixo

**Detectar:** Units em cláusula `uses` cujos tipos/funções não são referenciados.

---

## Componentes Obsoletos

### DELPHI-020: Uso de BDE (Borland Database Engine)
**Risco:** Alto | **Esforço:** Alto

**Detectar:** Componentes: `TTable`, `TQuery`, `TDatabase`, `TSession`, `TStoredProc` (BDE).

**Substituições recomendadas:**
- `TTable` → `TADOTable` ou `TFDTable`
- `TQuery` → `TADOQuery` ou `TFDQuery`
- `TDatabase` → `TADOConnection` ou `TFDConnection`

### DELPHI-021: Uso de TClientDataSet sem Provider
**Risco:** Médio | **Esforço:** Médio

**Detectar:** `TClientDataSet` referenciando BDE DataSets.

### DELPHI-022: Componentes de terceiros descontinuados
**Risco:** Alto | **Esforço:** Variável

**Lista de componentes a verificar:**
- InfoPower
- TurboPower (alguns)
- QuickReport (versões antigas)

---

## Manipulação de Strings

### DELPHI-030: Concatenação em loops
**Risco:** Médio | **Esforço:** Baixo

**Detectar:**
```delphi
for i := 0 to Count - 1 do
  Result := Result + Items[i];  // Ineficiente
```

**Correção:** Usar `TStringList` ou `TStringBuilder` (Delphi moderno).

### DELPHI-031: Uso de string sem considerar encoding
**Risco:** Médio | **Esforço:** Médio

**Detectar:** Conversões diretas `PChar`, `AnsiString` sem tratamento explícito.

### DELPHI-032: Format com parâmetros incorretos
**Risco:** Alto | **Esforço:** Baixo

**Detectar:** Chamadas `Format()` onde número de especificadores ≠ número de argumentos.

---

## Acesso a Dados

### DELPHI-040: SQL dinâmico sem parametrização
**Risco:** Alto | **Esforço:** Médio

**Detectar:**
```delphi
Query.SQL.Text := 'SELECT * FROM Users WHERE ID = ' + IntToStr(ID);
// Vulnerável a SQL Injection
```

**Correção:**
```delphi
Query.SQL.Text := 'SELECT * FROM Users WHERE ID = :ID';
Query.ParamByName('ID').AsInteger := ID;
```

### DELPHI-041: Transações não gerenciadas
**Risco:** Alto | **Esforço:** Médio

**Detectar:** `ExecSQL` ou operações de escrita sem `StartTransaction`/`Commit`/`Rollback`.

### DELPHI-042: Cursores não fechados
**Risco:** Médio | **Esforço:** Baixo

**Detectar:** `Open` sem `Close` correspondente ou verificação de `Active`.

---

## Tratamento de Exceções

### DELPHI-050: Exception silenciada
**Risco:** Alto | **Esforço:** Baixo

**Detectar:**
```delphi
try
  // código
except
  // vazio ou apenas comentário
end;
```

### DELPHI-051: Raise sem re-raise em finally
**Risco:** Médio | **Esforço:** Baixo

**Detectar:** `raise` dentro de `finally` que pode mascarar exceção original.

### DELPHI-052: Uso de Exit em try/finally
**Risco:** Médio | **Esforço:** Baixo

**Detectar:** `Exit` dentro de bloco `try` antes de `finally` - verificar se recursos são liberados.

---

## Padrões de Código

### DELPHI-060: Números mágicos
**Risco:** Baixo | **Esforço:** Baixo

**Detectar:** Literais numéricos que não são 0, 1, ou -1 usados diretamente.

**Correção:** Extrair para constantes nomeadas.

### DELPHI-061: Funções muito longas
**Risco:** Médio | **Esforço:** Médio

**Threshold:** > 100 linhas de código efetivo (excluindo comentários/linhas em branco).

### DELPHI-062: Aninhamento excessivo
**Risco:** Médio | **Esforço:** Médio

**Threshold:** > 4 níveis de indentação (if/for/while/case).

### DELPHI-063: Uso de variáveis globais
**Risco:** Médio | **Esforço:** Alto

**Detectar:** Variáveis declaradas em seção `var` da unit (fora de classes/procedures).

---

## Priorização

| Categoria | Regras | Prioridade |
|-----------|--------|------------|
| Segurança | DELPHI-040, 041 | 🔴 Crítica |
| Vazamentos | DELPHI-001, 002, 003 | 🔴 Alta |
| Obsolescência | DELPHI-020, 021, 022 | 🟠 Alta |
| Exceções | DELPHI-050, 051, 052 | 🟠 Média |
| Manutenibilidade | DELPHI-060, 061, 062, 063 | 🟡 Média |
| Código morto | DELPHI-010, 011, 012 | 🟢 Baixa |
