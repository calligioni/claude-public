# Regras de Análise Estática - .NET Framework 4.5

## Sumário
1. [APIs Obsoletas](#apis-obsoletas)
2. [Async/Await Patterns](#asyncawait-patterns)
3. [Tratamento de Exceções](#tratamento-de-exceções)
4. [Performance](#performance)
5. [Segurança](#segurança)
6. [Data Binding](#data-binding)
7. [Padrões de Código](#padrões-de-código)

---

## APIs Obsoletas

### DOTNET-001: WebClient obsoleto
**Risco:** Médio | **Esforço:** Médio

**Detectar:** Uso de `System.Net.WebClient`

**Substituição:** `HttpClient` (preferível) ou `HttpWebRequest`

```csharp
// Obsoleto
var client = new WebClient();
var data = client.DownloadString(url);

// Recomendado
using var client = new HttpClient();
var data = await client.GetStringAsync(url);
```

### DOTNET-002: ArrayList/Hashtable não tipados
**Risco:** Baixo | **Esforço:** Baixo

**Detectar:** Uso de `ArrayList`, `Hashtable`, `Stack`, `Queue` (não genéricos)

**Substituição:** `List<T>`, `Dictionary<K,V>`, `Stack<T>`, `Queue<T>`

### DOTNET-003: ConfigurationManager.AppSettings
**Risco:** Baixo | **Esforço:** Médio

**Detectar:** Acesso direto a `ConfigurationManager.AppSettings`

**Recomendação:** Encapsular em classe de configuração tipada.

### DOTNET-004: Thread.Abort()
**Risco:** Alto | **Esforço:** Alto

**Detectar:** Chamadas a `Thread.Abort()`

**Problema:** Pode deixar estado inconsistente.

**Substituição:** CancellationToken pattern.

---

## Async/Await Patterns

### DOTNET-010: I/O síncrono em contexto assíncrono
**Risco:** Alto | **Esforço:** Médio

**Detectar:** Operações I/O síncronas em métodos que deveriam ser async:
- `File.ReadAllText()` → `File.ReadAllTextAsync()`
- `Stream.Read()` → `Stream.ReadAsync()`
- `SqlCommand.ExecuteReader()` → `ExecuteReaderAsync()`

### DOTNET-011: async void (exceto event handlers)
**Risco:** Alto | **Esforço:** Baixo

**Detectar:** Métodos `async void` que não são event handlers

**Problema:** Exceções não podem ser capturadas.

**Correção:** Usar `async Task`

### DOTNET-012: .Result ou .Wait() em código async
**Risco:** Alto | **Esforço:** Médio

**Detectar:** 
```csharp
var result = someTask.Result;  // Pode causar deadlock
someTask.Wait();               // Pode causar deadlock
```

**Correção:** Usar `await`

### DOTNET-013: Task.Run para operações I/O
**Risco:** Médio | **Esforço:** Baixo

**Detectar:** `Task.Run()` envolvendo operações de I/O

**Problema:** Desperdiça thread do pool.

**Correção:** Usar APIs async nativas.

---

## Tratamento de Exceções

### DOTNET-020: catch(Exception) genérico
**Risco:** Médio | **Esforço:** Baixo

**Detectar:**
```csharp
try { }
catch (Exception ex) { } // Muito genérico
```

**Recomendação:** Capturar exceções específicas.

### DOTNET-021: Exception silenciada
**Risco:** Alto | **Esforço:** Baixo

**Detectar:**
```csharp
try { }
catch { } // Sem tratamento nem log
```

### DOTNET-022: throw ex (perde stack trace)
**Risco:** Médio | **Esforço:** Baixo

**Detectar:**
```csharp
catch (Exception ex)
{
    throw ex;  // Perde stack trace original
}
```

**Correção:** Usar `throw;` ou `throw new Exception("msg", ex);`

### DOTNET-023: Exceção em finally
**Risco:** Alto | **Esforço:** Médio

**Detectar:** Código que pode lançar exceção dentro de bloco `finally`.

---

## Performance

### DOTNET-030: String concatenação em loop
**Risco:** Médio | **Esforço:** Baixo

**Detectar:**
```csharp
string result = "";
foreach (var item in items)
    result += item;  // Ineficiente
```

**Correção:** Usar `StringBuilder` ou `string.Join()`

### DOTNET-031: LINQ ToList() desnecessário
**Risco:** Baixo | **Esforço:** Baixo

**Detectar:** `ToList()` quando `IEnumerable` seria suficiente.

### DOTNET-032: Boxing/Unboxing excessivo
**Risco:** Médio | **Esforço:** Médio

**Detectar:** Conversões frequentes entre value types e object.

### DOTNET-033: Dispose não chamado
**Risco:** Médio | **Esforço:** Baixo

**Detectar:** Objetos `IDisposable` sem `using` ou `Dispose()` explícito.

---

## Segurança

### DOTNET-040: SQL Injection
**Risco:** Alto | **Esforço:** Médio

**Detectar:**
```csharp
var sql = "SELECT * FROM Users WHERE Id = " + userId;
// Vulnerável
```

**Correção:** Usar parâmetros ou ORMs.

### DOTNET-041: Hardcoded credentials
**Risco:** Alto | **Esforço:** Baixo

**Detectar:** Strings contendo "password", "pwd", "secret", "connectionstring" com valores literais.

### DOTNET-042: Criptografia fraca
**Risco:** Alto | **Esforço:** Médio

**Detectar:** Uso de `MD5`, `SHA1`, `DES`, `TripleDES`

**Substituição:** `SHA256`, `SHA512`, `AES`

### DOTNET-043: Validação de entrada ausente
**Risco:** Alto | **Esforço:** Médio

**Detectar:** Dados de entrada usados diretamente sem validação em:
- File paths
- URLs
- SQL queries
- Regex patterns

---

## Data Binding

### DOTNET-050: PropertyChanged não implementado
**Risco:** Médio | **Esforço:** Médio

**Detectar:** Classes usadas em binding sem `INotifyPropertyChanged`

### DOTNET-051: ObservableCollection não usado
**Risco:** Médio | **Esforço:** Baixo

**Detectar:** `List<T>` em propriedades bound a ItemsSource

**Correção:** Usar `ObservableCollection<T>`

### DOTNET-052: Binding sem Mode especificado
**Risco:** Baixo | **Esforço:** Baixo

**Detectar:** Bindings que deveriam ser TwoWay mas não especificam Mode.

---

## Padrões de Código

### DOTNET-060: Métodos muito longos
**Risco:** Médio | **Esforço:** Médio

**Threshold:** > 50 linhas efetivas

### DOTNET-061: Complexidade ciclomática alta
**Risco:** Médio | **Esforço:** Alto

**Threshold:** > 10

### DOTNET-062: Muitos parâmetros
**Risco:** Baixo | **Esforço:** Médio

**Threshold:** > 5 parâmetros

**Correção:** Usar objeto de parâmetro ou builder pattern.

### DOTNET-063: Código duplicado
**Risco:** Médio | **Esforço:** Variável

**Detectar:** Blocos de código idênticos ou muito similares (> 10 linhas).

---

## Priorização

| Categoria | Regras | Prioridade |
|-----------|--------|------------|
| Segurança | DOTNET-040, 041, 042, 043 | 🔴 Crítica |
| Async/Deadlock | DOTNET-011, 012 | 🔴 Alta |
| Exceções silenciadas | DOTNET-021 | 🟠 Alta |
| APIs obsoletas críticas | DOTNET-004 | 🟠 Alta |
| Performance crítica | DOTNET-030, 033 | 🟠 Média |
| Data Binding | DOTNET-050, 051 | 🟡 Média |
| Manutenibilidade | DOTNET-060, 061, 062, 063 | 🟡 Média |
| APIs obsoletas menores | DOTNET-001, 002, 003 | 🟢 Baixa |
