---
name: iniciaGptMaker
description: "Transforma documentacao tecnica (FAQ, POP, RAG, Guia Rapido) em textos curtos de ate 1000 caracteres para treinar agentes de IA no GPTMaker. Gera um arquivo .txt para cada arquivo .md fonte, com textos em linguagem simples de suporte N1 (sem SQL, sem codigos internos). Controla progresso via JSON para retomada. Use quando o usuario pedir para gerar textos para GPTMaker, criar base de conhecimento para chatbot, transformar documentacao em textos de suporte, alimentar agente de IA com textos curtos, ou processar pasta de docs para treinamento. Triggers: /iniciaGptMaker, gptmaker, textos para chatbot, treinar agente, gerar textos suporte, alimentar base conhecimento."
user-invocable: true
effort: high
---

# GPTMaker Text Generator

Transforma documentacao tecnica em textos curtos (ate 1000 caracteres) formatados como afirmacoes diretas para treinar agentes de IA na plataforma GPTMaker.

## Quando Usar

- Gerar textos de treinamento para GPTMaker a partir de documentacao
- Transformar FAQs, POPs, RAGs e Guias Rapidos em textos de suporte N1
- Alimentar base de conhecimento de chatbot com textos curtos
- Processar pasta inteira de documentacao com controle de progresso

## Conceito Central

O GPTMaker tem uma funcionalidade "Texto" onde cada entrada aceita ate 1000 caracteres. O agente funciona melhor com **afirmacoes diretas e factuais** (nao perguntas). Cada texto deve ser uma unidade de conhecimento autonoma que o agente possa usar para responder usuarios de suporte.

## Processo

### Passo 1: Identificar Pasta Fonte e Pasta de Saida

Pergunte ao usuario (se nao informado):
- **Pasta fonte**: onde estao os arquivos .md de documentacao
- **Pasta de saida**: onde gerar os .txt (padrao: `gptmaker_textos/` dentro da pasta fonte)

Se ja houver um `progresso.json` na pasta de saida, ler e retomar de onde parou.

### Passo 2: Verificar Progresso Existente

Ler `progresso.json` na pasta de saida. Se existir:
1. Informar ao usuario quantos arquivos ja foram processados
2. Listar arquivos pendentes
3. Continuar processando apenas os pendentes

Se nao existir, criar o arquivo inicial listando todos os .md fontes como `pendente`.

### Passo 3: Selecionar Arquivos a Processar

#### Arquivos a PULAR (sem valor para suporte N1)

Ignorar automaticamente arquivos cujo nome contenha estes padroes (marcar como `ignorado` no progresso.json):

- `*INDEX*`, `*INDICE*` - Apenas indices/sumarios, sem conteudo util
- `*EspecificacaoTecnica*`, `*Especificacao_Tecnica*`, `*EspecTecnica*`, `*especificacao_tecnica*` - Muito tecnicos (N2/dev)
- `*README*` - Resumos basicos sem valor de suporte
- `*Metadados*`, `*STATUS_DOCUMENTACAO*` - Controle interno de documentacao
- `*Mapeamento_RAG*` - Metadados de indexacao, nao conteudo
- `*Referenciatecnica*`, `*Referencia_tecnica*` - Detalhes tecnicos para dev
- `*Diagrama*`, `*DiagramaFluxo*`, `*DiagramaArquitetura*`, `*Diagrama_Dados*` - Diagramas visuais sem texto util
- `*VALIDACAO*`, `*EVIDENCIAS*`, `*RELATORIO_CONCLUSAO*`, `*RELATORIO_FINAL*`, `*RELATORIO_GERACAO*` - Relatorios internos de validacao
- `*Casos_Teste*`, `*CasosDeTeste*` - Casos de teste (para dev, nao suporte)
- `*exemplos_sql*`, `*Consultas_SQL*`, `*Exemplos_Codigo*` - Codigo SQL/Delphi (N2/dev)
- `*Dev_Guide*`, `*TecnicoManutencao*` - Guias tecnicos para desenvolvedores
- `*Mapeamento_Banco*` - Mapeamento de banco de dados (DBA)
- `*Especificação Técnica*` - Variante com acento de especificacao tecnica

Isso reduz o escopo de ~1367 para ~740 arquivos relevantes, eliminando ~630 arquivos sem valor para suporte N1.

#### Prioridade de processamento (arquivos que DEVEM ser processados)

1. **FAQ / Troubleshooting** (`*FAQ*`, `*Troubleshooting*`) - Maior valor para suporte
2. **POP Suporte** (`*POP*`) - Procedimentos padronizados
3. **Base Conhecimento RAG** (`*RAG*`, `*Base_Conhecimento*`, `*BaseConhecimento*`) - Q&A estruturado (exceto *Mapeamento_RAG*)
4. **Guia Rapido / Referencia Rapida** (`*Guia_Rapido*`, `*GuiaRapido*`, `*Quick*`, `*ReferenciaRapida*`, `*Referencia_Rapida*`) - Informacoes condensadas
5. **Documentacao Usuario / Manual** (`*Documentacao*`, `*DocumentacaoUsuario*`, `*Manual*`, `*Manual_Usuario*`) - Procedimentos e fluxos
6. **Fluxos, Casos de Uso e Tutoriais** (`*Fluxos*`, `*CasosDeUso*`, `*Casos_Uso*`, `*ExemplosUso*`, `*Tutorial*`, `*Exemplos_Praticos*`, `*Treinamento*`, `*Guia_Usuario*`) - Cenarios praticos
7. **Checklists** (`*CHECKLIST*`) - Listas de verificacao
8. **Resumo Executivo** (`*Resumo*`, `*ResumoExecutivo*`, `*RESUMO*`, `*Sumario_Executivo*`) - Visao geral (extrair conceitos-chave)
9. **Demais arquivos .md** - Avaliar caso a caso, pular se nao tiver conteudo de suporte

### Passo 4: Processar Cada Arquivo

Para cada arquivo .md fonte:

1. Atualizar `progresso.json` com status `em_andamento`
2. Ler o conteudo completo do arquivo
3. Extrair os nuggets de informacao uteis para suporte N1
4. Gerar textos seguindo as Regras de Qualidade (abaixo) Sempre dizendo a tela.
5. Gravar arquivo .txt de saida com mesmo nome do .md fonte
6. Atualizar `progresso.json` com status `concluido` e contagem de textos

### Passo 5: Relatorio Final

Ao concluir todos os arquivos (ou ao parar):
- Total de arquivos processados
- Total de textos gerados
- Media de caracteres por texto
- Distribuicao por categoria (FAQ, POP, RAG, etc.)

## Regras de Qualidade dos Textos

Cada texto gerado DEVE seguir estas regras:

### Formato
- **Limite rigido**: ate 1000 caracteres por texto
- **Afirmacoes diretas**: nunca usar formato pergunta/resposta
- **Autonomo**: cada texto deve fazer sentido sozinho, sem depender de outro
- **Separador**: textos separados por linha em branco + `---` + linha em branco

### Linguagem
- Portugues BR, tom profissional mas acessivel
- Focado em suporte nivel 1 (atendentes que guiam o usuario)
- Sem jargao tecnico desnecessario

### Proibido nos Textos
- Codigo SQL, queries, nomes de tabelas ou campos do banco
- Codigos internos de tela (ex: usar "Tipo de Associacao" em vez de "COMCAD_ASSTIP_M")
- Emojis
- Nomes de stored procedures, functions ou units Delphi
- Trechos de codigo de qualquer linguagem

### Permitido / Recomendado
- Nomes de menu como o usuario ve no sistema (ex: "Comercial > Cadastros > Produtos")
- Atalhos de teclado (ex: F2, Ctrl+S, Alt+I)
- Nomes de botoes e campos da tela
- Passos numerados para procedimentos
- Mensagens de erro como o usuario ve na tela

## Categorias de Textos a Gerar

Para cada arquivo, gere textos nestas categorias (conforme aplicavel):

### 1. Navegacao e Acesso
Formato: "No KPL, [funcionalidade] permite [funcao]. Acesse pelo menu [caminho]. [Campos obrigatorios]. [Atalhos disponiveis]."

### 2. Troubleshooting
Formato: "Se o usuario [sintoma/erro], a causa e [causa]. Para resolver: [passos]. [Se persistir, escalar/verificar X]."

### 3. Conceito e Regra de Negocio
Formato: "No KPL, [conceito] funciona da seguinte forma: [explicacao]. [Areas afetadas]. [Exemplo pratico]."

### 4. Procedimento Rapido
Formato: "Para [tarefa]: 1) [passo]. 2) [passo]. 3) [passo]. [Observacao importante]."

### 5. Relacionamento entre Funcionalidades
Formato: "A funcionalidade [X] depende da configuracao de [Y]. Antes de usar [X], certifique-se que [pre-requisito]."

## Formato do Arquivo de Saida (.txt)

Cada arquivo .txt contem 1 ou mais textos separados por delimitador:

```
[Texto 1 - ate 1000 caracteres, afirmacao direta]

---

[Texto 2 - ate 1000 caracteres, afirmacao direta]

---

[Texto 3 - ate 1000 caracteres, afirmacao direta]
```

## Formato do progresso.json

```json
{
  "ultima_atualizacao": "2026-04-24T14:00:00",
  "pasta_fonte": "/caminho/para/docs",
  "pasta_saida": "/caminho/para/gptmaker_textos",
  "total_arquivos_fonte": 130,
  "total_processados": 10,
  "total_textos_gerados": 79,
  "arquivos": {
    "ARQUIVO_FAQ.md": {
      "status": "concluido",
      "textos_gerados": 8,
      "data_processamento": "2026-04-24T14:00:00"
    },
    "OUTRO_ARQUIVO.md": {
      "status": "pendente",
      "textos_gerados": 0,
      "data_processamento": null
    }
  }
}
```

**Status possiveis:**
- `pendente` - nao processado ainda
- `em_andamento` - comecou mas nao terminou (retomar)
- `concluido` - processado com sucesso
- `erro` - falhou (reprocessar)

## Escala e Performance

- Processar arquivos em lotes de 5-10 para nao sobrecarregar o contexto
- Apos cada lote, atualizar o `progresso.json`
- Se o usuario pedir para parar, atualizar progresso e informar como retomar
- Para retomar: basta invocar `/iniciaGptMaker` novamente na mesma pasta

## Validacao

Apos gerar os textos de um lote, validar:
- Nenhum texto excede 1000 caracteres
- Nenhum texto contem SQL ou codigos internos
- Todos os textos sao afirmacoes diretas (nao perguntas)
- Arquivo .txt gerado para cada .md processado
- `progresso.json` atualizado corretamente

## Exemplo de Texto Gerado (referencia)

**BOM** (afirmacao direta, linguagem simples, sem SQL):
```
No KPL, o Tipo de Associacao de Produto define como os produtos se relacionam entre si. Existem quatro categorias: Geral (associacoes genericas), Cross Sell (produtos complementares para venda cruzada, como celular e capinha), Up Sell (produtos superiores para aumentar o ticket medio) e Partes (componentes e pecas de reposicao). Acesse pelo menu Comercial > Cadastros > Produtos > Tipo de Associacao.
```

**RUIM** (pergunta/resposta, contem SQL, codigo interno):
```
P: Como acessar COMCAD_ASSTIP_M?
R: Execute SELECT * FROM TCOM_ASSTIP WHERE ASST_NOM LIKE '%termo%' para verificar.
```
