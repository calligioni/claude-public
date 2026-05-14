# Padrões SQL Server — KPL/Abacos

Padrões do banco SQL Server do KPL. Descobertos por análise direta do banco `ABACOS_344B79D`.
SQL Server 2022 Standard no servidor `allisoonsqlserv`.

---

## Naming conventions

| Objeto | Padrão | Exemplo |
|---|---|---|
| Tabela | `T{MOD}_{ENT}` | `TGEN_COTMON`, `TEST_SALPRO` |
| SP de cadastro | `dbo.P{MOD}_C_{ENT}` | `dbo.PADM_C_COTMON` |
| SP de processo | `dbo.P{MOD}_P_{ENT}` | `dbo.PEST_P_MOVPRO` |
| SP de relatório | `dbo.P{MOD}_R_{ENT}` | `dbo.PCOM_R_PEDVEN` |
| Função scalar | `dbo.F{MOD}_{SECTION}_{ENT}` | `dbo.FGEN_S_GETDATE` |
| User-defined type | `DT_{SUFFIXO}` | `DT_COD`, `DT_NOM`, `DT_CHR` |
| Sequence object | `SEQ_{TABELA}` | `SEQ_TGEN_COTMON` |
| Tabela de sequência | `TSEQ_{TABELA}` | `TSEQ_TGEN_COTMON` |

Módulos confirmados no banco:
`ACE, ADM, ATE, ATR, CNT, COM, CPR, EST, FAS, FIN, GEN, GOV, IMP, IMS, INT, LOJ, NPC, QRY, RMA, RPL, RPT, SEQ, TRD`

---

## User-Defined Types (DT_)

Todos os parâmetros de SPs devem usar DT_ — nunca tipos nativos diretamente nos parâmetros.

| Tipo | Base | Tamanho | Uso |
|---|---|---|---|
| `DT_COD` | int | 4 | PKs e FKs |
| `DT_CHR` | char | 1 | Flags/códigos de 1 char |
| `DT_CHR_SN` | char | 1 | Booleano 'S'/'N' |
| `DT_NOM` | char | 50 | Nomes curtos |
| `DT_NOM_RAZ` | varchar | 100 | Razão social |
| `DT_NOM_FAN` | varchar | 60 | Nome fantasia |
| `DT_DES` | varchar | 50 | Descrições curtas |
| `DT_DES_LOG` | varchar | 255 | Descrições longas |
| `DT_MAX` | varchar | MAX | Textos livres longos |
| `DT_VAL` | float | 8 | Valores monetários |
| `DT_QTF` | float | 8 | Quantidades |
| `DT_DAT` | datetime | 8 | Datas gerais |
| `DT_DAT_CAD` | datetime | 8 | Data de cadastro |
| `DT_DAT_ALT` | datetime | 8 | Data de última alteração |
| `DT_TAB` | char | 15 | Nomes de tabelas |
| `DT_INT` | int | 4 | Inteiros gerais |
| `DT_BIG` | bigint | 8 | IDs de auditoria/log |
| `DT_GUI` | uniqueidentifier | 16 | GUIDs |
| `DT_PRE` | float | 8 | Preços |
| `DT_PCT` | float | 8 | Percentuais |
| `DT_NUM` | numeric(18,4) | — | Valores com precisão |
| `DT_CPF` | char | 11 | CPF sem pontuação |
| `DT_CNPJ` | char | 14 | CNPJ sem pontuação |
| `DT_CEP` | char | 8 | CEP sem traço |
| `DT_TEL` | char | 10 | Telefone |
| `DT_CEL` | char | 11 | Celular |
| `DT_EML` | varchar | 255 | E-mail |
| `DT_URL` | varchar | 255 | URL |
| `DT_IP` | varchar | 15 | Endereço IP |

---

## Estrutura padrão de SP de cadastro (P{MOD}_C_{ENT})

```sql
CREATE PROCEDURE dbo.P{MOD}_C_{ENT}
/******************************************************************************
* Procedimento   : dbo.P{MOD}_C_{ENT}
* Criado em      : DD/MM/AAAA
* Criado por     : <NOME>
* Descricao      : Insert, Alterar e Excluir <nome da entidade>
* Modulo         : <Modulo>
* Parametros     : @pACAO - I=Inserir, A=Alterar e E=Excluir
*                  @p{ENT}_COD - PK (OUTPUT no insert)
* Historico      :
* <version>     <data>    <autor>    <descricao>
******************************************************************************/
(
    @pACAO          DT_CHR          -- I=Inserir, A=Alterar e E=Excluir
   ,@p{ENT}_COD     DT_COD  OUTPUT  -- PK — OUTPUT p/ insert, INPUT p/ update/delete
   ,@p{ENT}_DAT_CAD DT_DAT_CAD OUTPUT
   ,@p{CAMPO1}      DT_{TIPO}
   -- ... demais parâmetros
)
--WITH ENCRYPTION
AS
BEGIN
   DECLARE @vExecProc   INT
          ,@vDataAtual  DATETIME
          ,@vTabNomLog  DT_DES
          ,@vTabNomFis  DT_TAB
          ,@vDepends    DT_NOM

   SET @vTabNomLog = '<Nome legível da entidade>'
   SET @vTabNomFis = 'T{MOD}_{ENT}'
   SET @vDataAtual = dbo.FGEN_S_GETDATE(1, NULL)

   IF NOT (@pACAO IN ('I', 'A', 'E'))
   BEGIN EXEC dbo.PGEN_P_RAISERROR @pERRORID = 88105; RETURN(1) END

   -- Verificar existência para A/E
   IF (@pACAO IN ('A', 'E'))
   BEGIN
      IF NOT EXISTS (SELECT 1 FROM dbo.T{MOD}_{ENT} (NOLOCK) WHERE {ENT}_COD = @p{ENT}_COD)
      BEGIN EXEC dbo.PGEN_P_RAISERROR @pERRORID = 88100; RETURN(1) END
   END

   BEGIN TRANSACTION

   IF (@pACAO = 'I')
   BEGIN
      -- Verificar duplicidade (quando aplicável)
      IF EXISTS (SELECT 1 FROM dbo.T{MOD}_{ENT} (NOLOCK) WHERE {ENT}_NOM = @p{ENT}_NOM)
      BEGIN ROLLBACK; EXEC dbo.PGEN_P_RAISERROR @pERRORID = 88004; RETURN(1) END

      EXEC @vExecProc = dbo.PGEN_P_GETTABLEID
           @pTABELA   = @vTabNomFis
          ,@pCHAVE    = @p{ENT}_COD OUTPUT

      IF (@vExecProc <> 0) BEGIN ROLLBACK; RETURN(1) END

      SET @p{ENT}_DAT_CAD = @vDataAtual

      INSERT INTO dbo.T{MOD}_{ENT}
             ({ENT}_COD, {ENT}_DAT_CAD, {ENT}_DAT_ALT, {ENT}_NOM /*, ... */)
      VALUES (@p{ENT}_COD, @p{ENT}_DAT_CAD, @vDataAtual, @p{ENT}_NOM /*, ... */)

      IF (@@ERROR<>0) BEGIN ROLLBACK; EXEC dbo.PGEN_P_RAISERROR @pERRORID = 88001; RETURN(1) END
   END
   ELSE IF (@pACAO = 'A')
   BEGIN
      -- Verificar duplicidade (quando aplicável)
      IF EXISTS (SELECT 1 FROM dbo.T{MOD}_{ENT} (NOLOCK) WHERE {ENT}_NOM = @p{ENT}_NOM AND {ENT}_COD <> @p{ENT}_COD)
      BEGIN ROLLBACK; EXEC dbo.PGEN_P_RAISERROR @pERRORID = 88004; RETURN(1) END

      UPDATE dbo.T{MOD}_{ENT}
      SET    {ENT}_DAT_ALT = @vDataAtual
            ,{ENT}_NOM     = @p{ENT}_NOM
             /*, ... */
      WHERE  {ENT}_COD = @p{ENT}_COD

      IF (@@ERROR<>0) BEGIN ROLLBACK; EXEC dbo.PGEN_P_RAISERROR @pERRORID = 88002; RETURN(1) END
   END
   ELSE IF (@pACAO = 'E')
   BEGIN
      SET @vDepends = ''
      EXEC dbo.PGEN_P_CHECKFK @pTABELA = @vTabNomFis, @pCHAVE = @p{ENT}_COD, @pDEPENDS = @vDepends OUTPUT
      IF (@vDepends <> '') BEGIN ROLLBACK; EXEC dbo.PGEN_P_RAISERROR @pERRORID = 88003; RETURN(1) END

      DELETE FROM dbo.T{MOD}_{ENT}
      WHERE {ENT}_COD = @p{ENT}_COD

      IF (@@ERROR<>0) BEGIN ROLLBACK; EXEC dbo.PGEN_P_RAISERROR @pERRORID = 88003; RETURN(1) END
   END

   COMMIT TRANSACTION
   RETURN(0)
END
```

---

## Utility Procedures e Functions

### `dbo.FGEN_S_GETDATE(empr_cod, unin_cod)` — data atual com timezone

```sql
SET @vDataAtual = dbo.FGEN_S_GETDATE(1, NULL)
```
- Retorna DATETIME com ajuste GMT/timezone da empresa
- Parâmetro 1 = empresa padrão; NULL = sem filtragem de unidade
- **Usar sempre em vez de GETDATE()** para campos DAT_CAD/DAT_ALT

---

### `dbo.PGEN_P_GETTABLEID` — geração de ID

```sql
EXEC @vExecProc = dbo.PGEN_P_GETTABLEID
     @pTABELA   = @vTabNomFis      -- nome físico da tabela ex: 'TGEN_COTMON'
    ,@pCHAVE    = @p{ENT}_COD OUTPUT

IF (@vExecProc <> 0) BEGIN ROLLBACK; RETURN(1) END
```
Hierarquia de busca do ID:
1. SEQUENCE `SEQ_{TABELA}` (se existir)
2. TSEQ_{TABELA} via IDENTITY INSERT (se existir)
3. MAX(PK)+1 em TGEN_TABSIS (fallback legacy)

---

### `dbo.PGEN_P_RAISERROR` — lançar erro padronizado

```sql
EXEC dbo.PGEN_P_RAISERROR @pERRORID = 88001
```
Retorna mensagem de erro localizada do catálogo. O cliente (Delphi/WCF) trata a exceção.

Erros mais usados nos cadastros:

| Código | Situação |
|---|---|
| 88001 | Erro ao inserir |
| 88002 | Erro ao alterar |
| 88003 | Erro ao excluir / registro em uso |
| 88004 | Registro duplicado |
| 88100 | Registro não encontrado |
| 88105 | Ação inválida (@pACAO inválido) |

---

### `dbo.PGEN_P_CHECKFK` — verificar dependências antes de excluir

```sql
SET @vDepends = ''
EXEC dbo.PGEN_P_CHECKFK
     @pTABELA  = @vTabNomFis     -- nome físico da tabela
    ,@pCHAVE   = @p{ENT}_COD     -- PK do registro a excluir
    ,@pDEPENDS = @vDepends OUTPUT -- retorna nome da tabela dependente ('' se livre)

IF (@vDepends <> '')
BEGIN ROLLBACK; EXEC dbo.PGEN_P_RAISERROR @pERRORID = 88003; RETURN(1) END
```

---

## Coluna padrão de toda tabela

Toda tabela `T{MOD}_{ENT}` tem obrigatoriamente:

| Coluna | Tipo | Uso |
|---|---|---|
| `{ENT}_COD` | DT_COD (int) | PK |
| `{ENT}_DAT_CAD` | DT_DAT_CAD (datetime) | Data de criação — nunca atualizar |
| `{ENT}_DAT_ALT` | DT_DAT_ALT (datetime) | Data da última alteração |

Campos opcionais recorrentes:

| Coluna | Tipo | Uso |
|---|---|---|
| `{ENT}_NOM` | DT_NOM | Nome curto |
| `{ENT}_DES` | DT_DES | Descrição |
| `{ENT}_STA` | DT_CHR | Status/situação |
| `{ENT}_OBS` | DT_MAX | Observações livres |

---

## Padrão de SELECT nas SPs (inline)

```sql
SELECT {ENT}_COD
      ,{ENT}_NOM
      ,{ENT}_DAT_CAD
      ,{ENT}_DAT_ALT
FROM   dbo.T{MOD}_{ENT} (NOLOCK)
WHERE  (1=1)
-- macros KPL substituídas pelo TMxDataSet:
-- '#VAZIO'      → (1=1)   quando sem filtro
-- '#{ENT}_COD'  → AND {ENT}_COD = @p{ENT}_COD
-- '#{ENT}_NOM'  → AND {ENT}_NOM LIKE '%'+@p{ENT}_NOM+'%'
ORDER BY {ENT}_NOM
```

Usar `(NOLOCK)` em todos os SELECTs de leitura.

---

## Tabelas de sequência (TSEQ_)

Para entidades com alto volume de inserções, existe `TSEQ_{TABELA}` em vez de SEQUENCE.
`PGEN_P_GETTABLEID` detecta automaticamente qual usar — não precisa especificar.

---

## Padrão de SPs de integração (camelCase)

SPs de integração externa (ex: marketplace, e-commerce) seguem convenção diferente:

```sql
dbo.p{Modulo}{Entidade}   -- ex: dbo.pMktpCadastrarProduto
```

Características:
- Nome camelCase (não uppercase)
- Parâmetros também em camelCase
- Retornam XML ou JSON via SELECT
- Não seguem o padrão @pACAO

**Não misturar** este padrão com o padrão interno `P{MOD}_C_{ENT}`.

---

## Criptografia de SPs (WITH ENCRYPTION)

Algumas SPs usam `WITH ENCRYPTION` — `OBJECT_DEFINITION()` retorna NULL.
Para verificar existência: `SELECT * FROM sys.objects WHERE name = 'nome_sp'`.
Para ler corpo: consultar `sys.sql_modules` (funciona apenas se não criptografado).

---

## Query de referência — ler corpo de SP

```sql
SELECT m.definition
FROM   sys.sql_modules m
INNER  JOIN sys.objects o ON m.object_id = o.object_id
WHERE  o.name = 'PADM_C_COTMON'
```

Para banco específico: prefixar com `ABACOS_344B79D.sys.sql_modules`.
