# Erros Recorrentes Delphi

Base acumulativa de erros já corrigidos. Consultar antes de fazer alterações.

**Formato para novos registros:**

```
## Erro
Mensagem exata ou descrição do erro.

## Causa
Por que aconteceu.

## Correção
Como corrigir.

## Prevenção
Regra para evitar no futuro.
```

---

<!-- Última atualização: 2026-05-20 -->

## Erro: .pas e .dfm gravados com caracteres de substituição UTF-8 (EF BF BD)

## Causa
A ferramenta Write grava arquivos em UTF-8. Quando o conteúdo inclui caracteres acentuados (ó, ç, ã, õ) em contexto de projeto Delphi 5 (ISO-8859-1), os bytes ficam como `EF BF BD` (U+FFFD — replacement character) em vez dos bytes Latin-1 corretos. O `file` detecta o arquivo como `utf-8` por causa desses bytes. Delphi 5 não consegue abrir o DFM corretamente.

## Correção
1. **Nunca usar Write/Edit para arquivos .pas/.dfm KPL** — seguir `encoding.md`.
2. Para restaurar arquivo .pas corrompido que existia antes: `git checkout <commit-original> -- arquivo.pas` (restaura ISO-8859-1), depois adicionar as mudanças novas via PowerShell com `[System.Text.Encoding]::GetEncoding(28591)`.
3. Para recriar arquivo .pas/.dfm novo corrompido: usar PowerShell com `[char]0xF3` (ó), `[char]0xE7` (ç), `[char]0xE3` (ã), `[char]0xF5` (õ) e `WriteAllBytes($path, $enc.GetBytes($content))`.
4. Verificar: `file --mime-encoding arquivo.pas` deve retornar `iso-8859-1`. Buscar `EF BF BD` em sequência nos bytes para confirmar ausência de corruption.

## Prevenção
- Nunca usar Write/Edit em arquivos .pas/.dfm do projeto KPL.
- Ao criar arquivo .pas/.dfm novo: usar PowerShell com `GetEncoding(28591)` e variáveis `[char]0xNNNN` para os acentos.
- Sempre verificar encoding com `file --mime-encoding` após qualquer escrita.


---

<!-- Ultima atualizacao: 2026-05-21 -->

## Erro: "error creating form: identifier expected on line N" ao abrir formulario DFM

## Causa
O arquivo .dfm contem comentarios no estilo Pascal { --- texto --- }. O parser de DFM do Delphi nao suporta comentarios - ele espera sempre um identificador (object, inherited, end, ou nome de propriedade). Qualquer { invalida o parse.

## Correcao
Remover todas as linhas de comentario { } do .dfm via PowerShell (preservar encoding ISO-8859-1):
`powershell
System.Text.UTF8Encoding = [System.Text.Encoding]::GetEncoding(28591)
 = [System.IO.File]::ReadAllText(C:\Users\adriano.calligioni\.claude\delphi-knowledge\error-patterns.md, System.Text.UTF8Encoding)
 = ( -split "
") | Where-Object {  -notmatch '^\s*\{[^}]*\}\s*$' }
[System.IO.File]::WriteAllText(C:\Users\adriano.calligioni\.claude\delphi-knowledge\error-patterns.md, ( -join "
"), System.Text.UTF8Encoding)
`

## Prevencao
- Nunca adicionar comentarios { } em arquivos .dfm.
- Comentarios em .dfm sao invalidos - qualquer anotacao deve ir no .pas correspondente.
- O IDE do Delphi nao escreve comentarios no .dfm; se aparecer, foi adicionado manualmente/por ferramenta externa.

---

<!-- Última atualização: 2026-06-12 -->

## Erro: [Fatal Error] arquivo.pas(1): Line too long (more than 1023 characters)

## Causa
O `sed -i` do Git Bash (Windows) converteu as quebras de linha de CRLF para LF ao editar o arquivo. O compilador Delphi 5 exige CRLF; com LF puro ele não reconhece as quebras e trata o arquivo como uma linha gigante. O encoding Latin-1 permanece intacto — só os `\r` somem, então o `file` continua mostrando `iso-8859-1`, mas sem o sufixo "with CRLF line terminators".

## Correção
```bash
unix2dos -q arquivo.pas   # restaura CRLF sem tocar nos bytes Latin-1
file arquivo.pas          # confirmar: "ISO-8859 text, with CRLF line terminators"
```

## Prevenção
- Após QUALQUER `sed -i` em arquivo .pas/.dfm/.sql do KPL, rodar `unix2dos -q` no arquivo.
- Preferir Perl com handles `:raw` e `\r\n` explícito para edições — não altera as quebras das demais linhas.
- Na verificação pós-edição usar `file arquivo` (não só `--mime-encoding`): a saída precisa conter "with CRLF line terminators".