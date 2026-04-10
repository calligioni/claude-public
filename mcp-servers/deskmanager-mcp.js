#!/usr/bin/env node
/**
 * Deskmanager MCP Server
 * Expoe ferramentas para consultar chamados do Deskmanager via API REST.
 * Protocolo: stdio (Model Context Protocol)
 */
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const DESKMANAGER_URL = process.env.DESKMANAGER_URL || "https://api.desk.ms";
const DESKMANAGER_FILES_URL = process.env.DESKMANAGER_FILES_URL || "https://files.desk.ms";
const DESKMANAGER_API_KEY = process.env.DESKMANAGER_API_KEY;
const DESKMANAGER_PUBLIC_KEY = process.env.DESKMANAGER_PUBLIC_KEY;
const DESKMANAGER_EMPRESA = process.env.DESKMANAGER_EMPRESA || "onclick";

// ── AUTH ───────────────────────────────────────────────────────────────────
let sessionToken = null;
let tokenExpiry = 0;

async function autenticar() {
  // Reutilizar token se ainda valido (30 min de validade conservadora)
  if (sessionToken && Date.now() < tokenExpiry) return sessionToken;

  const res = await fetch(`${DESKMANAGER_URL}/Login/autenticar`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: DESKMANAGER_API_KEY,
    },
    body: JSON.stringify({ PublicKey: DESKMANAGER_PUBLIC_KEY }),
  });

  if (!res.ok) {
    throw new Error(`Falha na autenticacao Deskmanager: ${res.status} ${res.statusText}`);
  }

  const data = await res.json();
  // A resposta contem o token em diferentes formatos dependendo da versao
  sessionToken = typeof data === "string" ? data : data.token || data.access_token || JSON.stringify(data);
  tokenExpiry = Date.now() + 30 * 60 * 1000; // 30 minutos
  return sessionToken;
}

function getAuthHeader() {
  // O token retornado pela API ja contem o prefixo empresaBase64#hash
  return sessionToken;
}

// ── RESOLUCAO NOME→CODIGO ─────────────────────────────────────────────────
async function resolverEntidade(endpoint, valor, campoNome = "Nome") {
  if (/^\d+$/.test(valor)) return valor;

  await autenticar();
  const res = await fetch(`${DESKMANAGER_URL}/${endpoint}/lista`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
    body: JSON.stringify({ Pesquisa: valor }),
  });
  if (!res.ok) return null;
  const data = await res.json();
  const lista = data.root || data || [];
  if (!Array.isArray(lista) || lista.length === 0) return null;

  const normalizado = valor.toLowerCase();
  const exato = lista.find((i) => (i[campoNome] || "").toLowerCase() === normalizado);
  if (exato) return String(exato.Chave);
  const parcial = lista.find((i) => (i[campoNome] || "").toLowerCase().includes(normalizado));
  return parcial ? String(parcial.Chave) : null;
}

async function resolverGrupo(valor) { return resolverEntidade("Grupos", valor, "Nome"); }
async function resolverOperador(valor) { return resolverEntidade("Operadores", valor, "Nome"); }
async function resolverCategoria(valor) { return resolverEntidade("Categorias", valor, "Nome"); }
async function resolverCliente(valor) { return resolverEntidade("Clientes", valor, "NomeFantasia"); }
async function resolverSolicitante(valor) { return resolverEntidade("Usuarios", valor, "Nome"); }

// Status usa campo Sequencia (ex: "000001") ao inves de Chave
async function resolverStatus(valor) {
  // Se ja veio como codigo zero-padded (ex: "000001"), retorna direto
  if (/^\d{6}$/.test(valor)) return valor;

  await autenticar();
  const res = await fetch(`${DESKMANAGER_URL}/Status/lista`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
    body: JSON.stringify({ Pesquisa: valor }),
  });
  if (!res.ok) return null;
  const data = await res.json();
  const lista = data.root || data || [];
  if (!Array.isArray(lista) || lista.length === 0) return null;

  const normalizado = valor.toLowerCase();
  const exato = lista.find((i) => (i.Nome || "").toLowerCase() === normalizado);
  if (exato) return String(exato.Sequencia);
  const parcial = lista.find((i) => (i.Nome || "").toLowerCase().includes(normalizado));
  return parcial ? String(parcial.Sequencia) : null;
}

async function resolverStatusMultiplos(valor) {
  const partes = valor.split(",").map(s => s.trim()).filter(Boolean);
  const codigos = await Promise.all(partes.map(p => resolverStatus(p)));
  const naoResolvidos = partes.filter((_, i) => !codigos[i]);
  if (naoResolvidos.length > 0) return { erro: naoResolvidos };
  return { codigos: codigos.filter(Boolean) };
}

// ── IMAGENS: EXTRAIR E CONVERTER IMGUR → HTML ──────────────────────────────

const IMGUR_REGEX = /https?:\/\/i\.imgur\.com\/[a-zA-Z0-9]+\.(png|jpg|jpeg|gif)/gi;

function extrairUrlsImgur(texto) {
  if (!texto) return [];
  const matches = texto.match(IMGUR_REGEX);
  return matches ? [...new Set(matches)] : [];
}

function converterImgurParaHtml(html) {
  const urls = extrairUrlsImgur(html);
  if (urls.length === 0) return { html, imagens: [] };

  let htmlAtualizado = html;
  const imagens = [];

  for (const imgurUrl of urls) {
    const filename = imgurUrl.split("/").pop();
    imagens.push({ url: imgurUrl, filename });
    const imgTag = `<img src="${imgurUrl}" alt="${filename}" width="600" />`;
    // Trocar links <a href="url">...</a> que contenham essa URL
    const linkRegex = new RegExp(`<a[^>]*href=["']${imgurUrl.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}["'][^>]*>[^<]*</a>`, 'gi');
    htmlAtualizado = htmlAtualizado.replace(linkRegex, imgTag);
    // Trocar URLs soltas (que nao foram convertidas acima)
    htmlAtualizado = htmlAtualizado.replace(new RegExp(`(?<!src=")${imgurUrl.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}`, 'gi'), imgTag);
  }

  return { html: htmlAtualizado, imagens };
}

// ── STRIP HTML ────────────────────────────────────────────────────────────
function stripHtml(text) {
  if (!text) return "";
  let t = text;
  t = t.replace(/<br\s*\/?>/gi, "\n");
  t = t.replace(/<[^>]+>/g, "");
  t = t.replace(/&nbsp;/g, " ");
  t = t.replace(/&aacute;/g, "á").replace(/&eacute;/g, "é");
  t = t.replace(/&iacute;/g, "í").replace(/&oacute;/g, "ó");
  t = t.replace(/&uacute;/g, "ú").replace(/&atilde;/g, "ã");
  t = t.replace(/&otilde;/g, "õ").replace(/&ccedil;/g, "ç");
  t = t.replace(/&agrave;/g, "à").replace(/&amp;/g, "&");
  t = t.replace(/&lt;/g, "<").replace(/&gt;/g, ">");
  t = t.replace(/&quot;/g, '"');
  return t.trim();
}

// ── UPLOAD DE ANEXOS ──────────────────────────────────────────────────────
async function enviarAnexo({ chamado, codacao, base64, type, name }) {
  await autenticar();
  const body = {
    chamado: chamado || "",
    base64: base64 || "",
    type: type || "application/octet-stream",
    name: name || "arquivo",
    ...(codacao && { codacao }),
  };
  const res = await fetch(`${DESKMANAGER_FILES_URL}/v1/enviar`, {
    method: "PUT",
    headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`Erro upload: ${res.status} ${res.statusText}`);
  const data = await res.json();
  if (data.erro) throw new Error(`Erro upload: ${data.erro}`);
  return data;
}

// ── PARSE INTERACOES DO HTML ─────────────────────────────────────────────
function parseInteracoesHtml(html) {
  if (!html) return [];
  const interacoes = [];
  const parts = html.split(/<table[^>]*>/i);

  const actionRe = /Dados da A[çc][ãa]o\s+(\d+)\s*-\s*(Suporte|Cliente)\s*-\s*(\S+)/i;
  const descRe = /Descri[çc][ãa]o da A[çc][ãa]o/i;

  for (let i = 0; i < parts.length; i++) {
    const part = parts[i];
    const match = actionRe.exec(part);
    if (!match) continue;

    const numero = parseInt(match[1], 10);
    const tipo = match[2].trim();

    // Extract field values from <td> cells
    const cells = [];
    const tdRe = /<td[^>]*>\s*([\s\S]*?)\s*<\/td>/gi;
    let tdMatch;
    while ((tdMatch = tdRe.exec(part)) !== null) {
      cells.push(stripHtml(tdMatch[1]).trim());
    }

    const fields = {};
    for (let j = 0; j < cells.length - 2; j++) {
      const label = cells[j].replace(/:$/, "");
      if (cells[j + 1] === ":") {
        fields[label] = cells[j + 2];
        j += 2;
      }
    }

    // Extract description from next table part
    let descricao = "";
    if (i + 1 < parts.length && descRe.test(parts[i + 1])) {
      const colspanRe = /<td\s+colspan="3"\s*>([\s\S]*?)<\/td>/gi;
      let cMatch;
      while ((cMatch = colspanRe.exec(parts[i + 1])) !== null) {
        descricao = cMatch[1].trim();
      }
    }

    // Determine operator
    let operador = "";
    if (tipo.toLowerCase() === "cliente") {
      operador = Object.entries(fields).find(([k]) => /espons/i.test(k))?.[1] || "";
    } else {
      operador = fields["Operador/Grupo"] || "";
    }

    const dataCriacao = Object.entries(fields).find(([k]) => /Cria/i.test(k))?.[1] || "";
    const status = Object.entries(fields).find(([k]) => k.toLowerCase() === "status")?.[1] || "";
    const forma = Object.entries(fields).find(([k]) => /Forma/i.test(k))?.[1] || "";

    // Extract images from description HTML
    const imgMatches = descricao.match(/<img[^>]*src=["']([^"']+)["']/gi) || [];
    const imagens = imgMatches.map((tag) => {
      const m = tag.match(/src=["']([^"']+)["']/);
      return m ? m[1] : null;
    }).filter((url) => url && !url.startsWith("data:"));

    const descClean = stripHtml(descricao.replace(/<br\s*\/?>\s*/gi, "\n"));

    const interacao = {
      numero,
      tipo,
      operador,
      data: dataCriacao,
      horaInicial: fields["Hora Inicial"] || "",
      horaFinal: fields["Hora Final"] || "",
      status,
      formaAtendimento: forma,
      descricao: descClean,
      descricaoHtml: descricao !== descClean ? descricao : "",
    };
    if (imagens.length > 0) interacao.imagens = imagens;
    interacoes.push(interacao);
  }
  return interacoes;
}

function montarFiltro({ codOperador, codGrupo, codCategoria, codCliente, codSolicitante, codStatusList, dataInicio, dataFim }) {
  const filtro = {};
  if (codOperador) filtro.CodOperador = [codOperador, ""];
  if (codGrupo) filtro.CodGrupo = [codGrupo];
  if (codCategoria) filtro.CodSubCategoria = [codCategoria];
  if (codCliente) filtro.CodCliente = [codCliente];
  if (codSolicitante) filtro.CodUsuario = [codSolicitante];
  if (codStatusList && codStatusList.length > 0) {
    filtro.CodStatusAtual = [codStatusList, "onlist"];
  }
  if (dataInicio || dataFim) {
    filtro.DataCriacao = [dataInicio || "", dataFim || "", "", ""];
  }
  return filtro;
}

async function resolverFiltros({ operador, grupo, categoria, cliente, solicitante, statusChamado, dataInicio, dataFim }) {
  const resolucoes = await Promise.all([
    operador ? resolverOperador(operador) : null,
    grupo ? resolverGrupo(grupo) : null,
    categoria ? resolverCategoria(categoria) : null,
    cliente ? resolverCliente(cliente) : null,
    solicitante ? resolverSolicitante(solicitante) : null,
  ]);

  const nomes = ["operador", "grupo", "categoria", "cliente", "solicitante"];
  const valores = [operador, grupo, categoria, cliente, solicitante];
  const naoResolvidos = [];
  for (let i = 0; i < nomes.length; i++) {
    if (valores[i] && !resolucoes[i]) naoResolvidos.push(nomes[i]);
  }

  let codStatusList = null;
  if (statusChamado) {
    const resultado = await resolverStatusMultiplos(statusChamado);
    if (resultado.erro) {
      naoResolvidos.push(...resultado.erro.map(s => `statusChamado(${s})`));
    } else {
      codStatusList = resultado.codigos;
    }
  }

  if (naoResolvidos.length > 0) {
    return { erro: `Nao foi possivel resolver: ${naoResolvidos.join(", ")}. Verifique os nomes informados.` };
  }

  const filtro = montarFiltro({
    codOperador: resolucoes[0],
    codGrupo: resolucoes[1],
    codCategoria: resolucoes[2],
    codCliente: resolucoes[3],
    codSolicitante: resolucoes[4],
    codStatusList,
    dataInicio,
    dataFim,
  });

  return Object.keys(filtro).length > 0 ? { filtro } : {};
}

// ── API CALLS ──────────────────────────────────────────────────────────────
const COLUNAS_PADRAO = {
  Chave: "on",
  CodChamado: "on",
  NomePrioridade: "on",
  DataCriacao: "on",
  HoraCriacao: "on",
  DataFinalizacao: "on",
  HoraFinalizacao: "on",
  DataAlteracao: "on",
  HoraAlteracao: "on",
  NomeStatus: "on",
  Assunto: "on",
  Descricao: "on",
  NomeCompletoSolicitante: "on",
  SolicitanteEmail: "on",
  NomeOperador: "on",
  SobrenomeOperador: "on",
  NomeGrupo: "on",
  TotalAcoes: "on",
  TotalAnexos: "on",
  Sla1Expirado: "on",
  Sla2Expirado: "on",
};

async function listarChamados({ pesquisa, status, ativo, statusSLA, limite, filtro, pagina, itensPorPagina, ordem, direcao }) {
  await autenticar();

  // Map ordem field names
  const ordemColuna = ordem || "Chave";
  const ordemDirecao = direcao === "ASC" ? "true" : "false";

  const body = {
    Pesquisa: pesquisa || "",
    Tatual: status || "",
    Ativo: ativo || "Todos",
    StatusSLA: statusSLA || "",
    Colunas: COLUNAS_PADRAO,
    Ordem: [{ Coluna: ordemColuna, Direcao: ordemDirecao }],
    ...(pagina && { Page: pagina }),
    ...(itensPorPagina && { PageSize: itensPorPagina }),
    ...(filtro && { Filtro: filtro }),
  };

  const res = await fetch(`${DESKMANAGER_URL}/ChamadosSuporte/lista`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: getAuthHeader(),
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    throw new Error(`Erro ao listar chamados: ${res.status} ${res.statusText}`);
  }

  const data = await res.json();
  const chamados = data.root || data || [];

  // Aplicar limite
  const maxItems = limite || 50;
  return Array.isArray(chamados) ? chamados.slice(0, maxItems) : chamados;
}

async function buscarHistorico(chave) {
  await autenticar();

  const body = {
    Chave: String(chave),
    CodChamado: "",
    Solicitante: "N",
    Colunas: {
      Chave: "on",
      Descricao: "on",
      ObservacaoInterna: "on",
      Status: "on",
      Aberto: "on",
      DataCriacao: "on",
      HoraCriacao: "on",
      DataAcao: "on",
      Solicitante: "on",
      Operador: "on",
      NomeFormaAtendimento: "on",
      CodCausa: "on",
      NomeCausa: "on",
      HoraAcaoInicio: "on",
      HoraAcaoFim: "on",
      TotalHoras: "on",
    },
  };

  const res = await fetch(`${DESKMANAGER_URL}/ChamadoHistoricos/lista`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: getAuthHeader(),
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    throw new Error(`Erro ao buscar historico: ${res.status} ${res.statusText}`);
  }

  return res.json();
}

// ── MCP SERVER ─────────────────────────────────────────────────────────────
const server = new McpServer({
  name: "deskmanager",
  version: "3.0.0",
  description: "Consulta chamados e tickets do Deskmanager (desk.ms)",
});

// Tool: listar_chamados
server.tool(
  "listar_chamados",
  "Lista chamados do Deskmanager com filtros opcionais. Aceita nomes ou codigos para operador, grupo, categoria, cliente, solicitante e status — resolve automaticamente nomes para codigos.",
  {
    pesquisa: z.string().optional().describe("Texto para buscar no assunto ou descricao"),
    status: z.string().optional().describe("Filtrar por status (ex: Novo, Pendente, Em Atendimento)"),
    ativo: z.enum(["Todos", "Sim", "Nao"]).optional().describe("Filtrar por chamados ativos. Padrao: Todos"),
    statusSLA: z.string().optional().describe("Filtrar por status de SLA"),
    operador: z.string().optional().describe("Nome ou codigo do operador"),
    grupo: z.string().optional().describe("Nome ou codigo do grupo de atendimento"),
    categoria: z.string().optional().describe("Nome ou codigo da categoria"),
    cliente: z.string().optional().describe("Nome ou codigo do cliente"),
    solicitante: z.string().optional().describe("Nome ou codigo do solicitante"),
    statusChamado: z.string().optional().describe("Nome(s) ou codigo(s) de status, separados por virgula (ex: 'Novo, Pendente')"),
    dataInicio: z.string().optional().describe("Data inicio criacao (YYYY-MM-DD)"),
    dataFim: z.string().optional().describe("Data fim criacao (YYYY-MM-DD)"),
    limite: z.number().optional().describe("Numero maximo de chamados a retornar. Padrao: 50"),
    pagina: z.number().optional().describe("Numero da pagina (default: 1)"),
    itensPorPagina: z.number().optional().describe("Itens por pagina (default: 50)"),
    ordem: z.string().optional().describe("Campo para ordenar (Criacao, Alterado, Chave, Prioridade, Assunto, Solicitante). Padrao: Chave"),
    direcao: z.enum(["ASC", "DESC"]).optional().describe("Direcao da ordenacao. Padrao: DESC (mais recente primeiro)"),
  },
  async (args) => {
    try {
      const { operador, grupo, categoria, cliente, solicitante, statusChamado, dataInicio, dataFim, ...restoArgs } = args;
      const temFiltrosAvancados = operador || grupo || categoria || cliente || solicitante || statusChamado || dataInicio || dataFim;
      let filtro;
      if (temFiltrosAvancados) {
        const resultado = await resolverFiltros({ operador, grupo, categoria, cliente, solicitante, statusChamado, dataInicio, dataFim });
        if (resultado.erro) {
          return { content: [{ type: "text", text: resultado.erro }], isError: true };
        }
        filtro = resultado.filtro;
        console.error("[DEBUG listar_chamados] filtro montado:", JSON.stringify(filtro));
      }
      const chamados = await listarChamados({ ...restoArgs, filtro });
      const resumo = Array.isArray(chamados)
        ? chamados.map((c) => ({
            chave: c.Chave,
            codigo: c.CodChamado,
            assunto: c.Assunto,
            status: c.NomeStatus,
            prioridade: c.NomePrioridade,
            solicitante: c.NomeCompletoSolicitante,
            email: c.SolicitanteEmail,
            operador: `${c.NomeOperador} (${c.SobrenomeOperador})`,
            grupo: c.NomeGrupo,
            criado: `${c.DataCriacao} ${c.HoraCriacao}`,
            alterado: `${c.DataAlteracao} ${c.HoraAlteracao}`,
            sla1Expirado: c.Sla1Expirado === "S",
            sla2Expirado: c.Sla2Expirado === "S",
          }))
        : chamados;
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(
              { total: Array.isArray(resumo) ? resumo.length : 0, chamados: resumo },
              null,
              2
            ),
          },
        ],
      };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// Tool: buscar_chamado
server.tool(
  "buscar_chamado",
  "Busca chamados por texto no assunto/descricao com filtros opcionais. Aceita nomes ou codigos para operador, grupo, categoria, cliente, solicitante e status.",
  {
    pesquisa: z.string().describe("Texto para buscar (codigo do chamado, nome do cliente, assunto)"),
    operador: z.string().optional().describe("Nome ou codigo do operador"),
    grupo: z.string().optional().describe("Nome ou codigo do grupo de atendimento"),
    categoria: z.string().optional().describe("Nome ou codigo da categoria"),
    cliente: z.string().optional().describe("Nome ou codigo do cliente"),
    solicitante: z.string().optional().describe("Nome ou codigo do solicitante"),
    statusChamado: z.string().optional().describe("Nome(s) ou codigo(s) de status, separados por virgula (ex: 'Novo, Pendente')"),
    dataInicio: z.string().optional().describe("Data inicio criacao (YYYY-MM-DD)"),
    dataFim: z.string().optional().describe("Data fim criacao (YYYY-MM-DD)"),
    limite: z.number().optional().describe("Numero maximo de resultados. Padrao: 10"),
  },
  async (args) => {
    try {
      const { pesquisa, operador, grupo, categoria, cliente, solicitante, statusChamado, dataInicio, dataFim, limite } = args;
      const temFiltrosAvancados = operador || grupo || categoria || cliente || solicitante || statusChamado || dataInicio || dataFim;
      let filtro;
      if (temFiltrosAvancados) {
        const resultado = await resolverFiltros({ operador, grupo, categoria, cliente, solicitante, statusChamado, dataInicio, dataFim });
        if (resultado.erro) {
          return { content: [{ type: "text", text: resultado.erro }], isError: true };
        }
        filtro = resultado.filtro;
      }
      const chamados = await listarChamados({
        pesquisa,
        limite: limite || 10,
        filtro,
      });
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(
              { total: Array.isArray(chamados) ? chamados.length : 0, chamados },
              null,
              2
            ),
          },
        ],
      };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// Tool: historico_chamado
server.tool(
  "historico_chamado",
  "Busca o historico de acoes/interacoes de um chamado especifico pela sua Chave numerica.",
  {
    chave: z.number().describe("Chave numerica do chamado (ex: 61722)"),
  },
  async (args) => {
    try {
      const historico = await buscarHistorico(args.chave);
      return {
        content: [{ type: "text", text: JSON.stringify(historico, null, 2) }],
      };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// Tool: resumo_sla
server.tool(
  "resumo_sla",
  "Gera um resumo dos chamados com SLA expirado ou em risco. Identifica chamados criticos que precisam de atencao.",
  {},
  async () => {
    try {
      const todos = await listarChamados({ ativo: "Sim", limite: 500 });
      if (!Array.isArray(todos)) {
        return { content: [{ type: "text", text: "Nenhum chamado encontrado" }] };
      }

      const sla1Expirado = todos.filter((c) => c.Sla1Expirado === "S");
      const sla2Expirado = todos.filter((c) => c.Sla2Expirado === "S");
      const abertos = todos.filter((c) => c.NomeStatus !== "Finalizado" && c.NomeStatus !== "Cancelado");

      // Calcular dias em aberto
      const hoje = new Date();
      const comDias = abertos.map((c) => {
        const criado = new Date(c.DataCriacao);
        const dias = Math.floor((hoje - criado) / (1000 * 60 * 60 * 24));
        return { ...c, diasAberto: dias };
      });

      const criticos = comDias.filter((c) => c.diasAberto > 30);
      const atencao = comDias.filter((c) => c.diasAberto > 15 && c.diasAberto <= 30);

      const resumo = {
        totalAtivos: abertos.length,
        sla1Expirado: sla1Expirado.length,
        sla2Expirado: sla2Expirado.length,
        criticos: criticos.map((c) => ({
          chave: c.Chave,
          codigo: c.CodChamado,
          assunto: c.Assunto,
          diasAberto: c.diasAberto,
          operador: c.NomeOperador,
          grupo: c.NomeGrupo,
        })),
        atencao: atencao.map((c) => ({
          chave: c.Chave,
          codigo: c.CodChamado,
          assunto: c.Assunto,
          diasAberto: c.diasAberto,
          operador: c.NomeOperador,
          grupo: c.NomeGrupo,
        })),
      };

      return {
        content: [{ type: "text", text: JSON.stringify(resumo, null, 2) }],
      };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: dados_chamado ───────────────────────────────────────────────────
server.tool(
  "dados_chamado",
  "Retorna dados completos de um chamado especifico pela sua Chave numerica. Mais detalhado que buscar_chamado.",
  {
    chave: z.number().describe("Chave numerica do chamado (ex: 61722)"),
  },
  async (args) => {
    try {
      await autenticar();
      const res = await fetch(`${DESKMANAGER_URL}/ChamadosSuporte`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
        body: JSON.stringify({ Chave: String(args.chave) }),
      });
      if (!res.ok) throw new Error(`Erro: ${res.status} ${res.statusText}`);
      const data = await res.json();
      return { content: [{ type: "text", text: JSON.stringify(data, null, 2) }] };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: detalhes_chamado ───────────────────────────────────────────────
server.tool(
  "detalhes_chamado",
  "Retorna detalhes extras de um chamado: anexos, campos extras, ICs vinculados, local. Complementa dados_chamado.",
  {
    codigo: z.string().describe("Codigo do chamado (ex: 1225-001011)"),
  },
  async (args) => {
    try {
      await autenticar();
      const res = await fetch(`${DESKMANAGER_URL}/ChamadosSuporte/listaDetalhes`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
        body: JSON.stringify({ Codigo: args.codigo }),
      });
      if (!res.ok) throw new Error(`Erro: ${res.status} ${res.statusText}`);
      const data = await res.json();
      return { content: [{ type: "text", text: JSON.stringify(data, null, 2) }] };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: listar_anexos ─────────────────────────────────────────────────
server.tool(
  "listar_anexos",
  "Lista anexos de um chamado especifico pela sua Chave numerica.",
  {
    chave: z.number().describe("Chave numerica do chamado (ex: 61722)"),
  },
  async (args) => {
    try {
      await autenticar();
      const res = await fetch(`${DESKMANAGER_URL}/ChamadosSuporte/listaanexos`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
        body: JSON.stringify({ Chave: String(args.chave) }),
      });
      if (!res.ok) throw new Error(`Erro: ${res.status} ${res.statusText}`);
      const data = await res.json();
      return { content: [{ type: "text", text: JSON.stringify(data, null, 2) }] };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: listar_comentarios ────────────────────────────────────────────
server.tool(
  "listar_comentarios",
  "Lista comentarios internos de um chamado. Comentarios sao visiveis apenas para operadores.",
  {
    chave: z.number().describe("Chave numerica do chamado (ex: 61722)"),
  },
  async (args) => {
    try {
      await autenticar();
      const res = await fetch(`${DESKMANAGER_URL}/ChamadosSuporte/comentar`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
        body: JSON.stringify({ TComentario: { Chave: String(args.chave) } }),
      });
      if (!res.ok) throw new Error(`Erro: ${res.status} ${res.statusText}`);
      const data = await res.json();

      const notifs = data.Notificacoes || [];
      const comentarios = notifs.map((n) => {
        const conteudoHtml = n.Conteudo || "";
        const imgs = conteudoHtml.match(/<img[^>]*src=["']([^"']+)["']/gi) || [];
        const imageUrls = imgs.map((tag) => {
          const m = tag.match(/src=["']([^"']+)["']/);
          return m ? m[1] : null;
        }).filter(Boolean);
        const comment = {
          chave: n.Chave,
          autor: n.RespCreate || "",
          data: n.DataInicial || "",
          assunto: n.Assunto || "",
          conteudoHtml,
          conteudoTexto: stripHtml(conteudoHtml),
          codChamado: n.CodChamado || "",
          codOperador: n.CodOperador || null,
        };
        if (imageUrls.length > 0) comment.imagens = imageUrls;
        return comment;
      });

      return {
        content: [{ type: "text", text: JSON.stringify({ total: comentarios.length, comentarios }, null, 2) }],
      };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: imprimir_chamado ──────────────────────────────────────────────
server.tool(
  "imprimir_chamado",
  "Obtem a versao para impressao do chamado (HTML completo com todas interacoes e imagens). Decodifica base64 da resposta.",
  {
    chave: z.number().describe("Chave numerica do chamado (ex: 61722)"),
  },
  async (args) => {
    try {
      await autenticar();
      const res = await fetch(`${DESKMANAGER_URL}/ChamadosSuporte/imprimir`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
        body: JSON.stringify({ Chave: String(args.chave) }),
      });
      if (!res.ok) throw new Error(`Erro: ${res.status} ${res.statusText}`);
      const data = await res.json();

      const root = data.root || {};
      const b64 = root.base64 || "";
      if (!b64) {
        return { content: [{ type: "text", text: JSON.stringify({ erro: "Sem conteudo base64 na resposta" }, null, 2) }], isError: true };
      }

      const html = Buffer.from(b64, "base64").toString("utf-8");
      const imgMatches = html.match(/<img[^>]*src=["']([^"']+)["']/gi) || [];
      const imageUrls = imgMatches.map((tag) => {
        const m = tag.match(/src=["']([^"']+)["']/);
        return m ? m[1] : null;
      }).filter((url) => url && !url.startsWith("data:"));

      const texto = stripHtml(html);

      return {
        content: [{
          type: "text",
          text: JSON.stringify({
            html,
            texto: texto.substring(0, 5000),
            imagens: imageUrls,
            tamanhoHtml: html.length,
          }, null, 2),
        }],
      };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: interacoes_chamado ─────────────────────────────────────────────
server.tool(
  "interacoes_chamado",
  "Busca todas as interacoes/acoes de um chamado de forma estruturada. Usa o endpoint de impressao para obter o HTML completo e faz parse para extrair cada interacao com operador, data, status, descricao e imagens.",
  {
    chave: z.number().describe("Chave numerica do chamado (ex: 61722)"),
  },
  async (args) => {
    try {
      await autenticar();
      // Get print HTML
      const res = await fetch(`${DESKMANAGER_URL}/ChamadosSuporte/imprimir`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
        body: JSON.stringify({ Chave: String(args.chave) }),
      });
      if (!res.ok) throw new Error(`Erro: ${res.status} ${res.statusText}`);
      const data = await res.json();

      const root = data.root || {};
      const b64 = root.base64 || "";
      if (!b64) {
        return { content: [{ type: "text", text: JSON.stringify({ erro: "Sem conteudo base64 na resposta" }) }], isError: true };
      }

      const html = Buffer.from(b64, "base64").toString("utf-8");
      const interacoes = parseInteracoesHtml(html);

      return {
        content: [{
          type: "text",
          text: JSON.stringify({ total: interacoes.length, interacoes }, null, 2),
        }],
      };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: interagir_chamado ───────────────────────────────────────────────
server.tool(
  "interagir_chamado",
  "Interagir/responder em um chamado existente. Adiciona uma acao ao chamado com descricao, podendo alterar status, operador, transferencia, forma de atendimento, imagem inline e anexo. Se descricao vazia e status informado, busca FrasePronta do status como template.",
  {
    chave: z.number().describe("Chave numerica do chamado"),
    descricao: z.string().optional().describe("Texto da interacao/resposta. Texto puro (nao HTML). Use [imagem] para posicionar imagem. Vazio = usa template automatico do status (FrasePronta)."),
    status: z.string().optional().describe("Novo status do chamado (ex: Em Atendimento, Pendente, Finalizado)"),
    operador: z.number().optional().describe("Chave do operador responsavel"),
    observacaoInterna: z.boolean().optional().describe("Se true, interacao e interna (nao visivel ao solicitante). Padrao: false"),
    transferirOperador: z.string().optional().describe("Nome do operador para transferencia (ex: 'Produtos EIVE'). Resolve nome para codigo automaticamente."),
    formaAtendimento: z.string().optional().describe("Codigo da forma de atendimento (ex: '000009' = Desk Manager). Padrao: nao informar"),
    horaInicial: z.string().optional().describe("Hora inicial no formato HH:MM. Padrao: hora atual"),
    imagemUrl: z.string().optional().describe("URL de imagem ja hospedada para inserir inline via Markdown ![Print](URL)"),
    imagemBase64: z.string().optional().describe("Imagem em base64 para upload ao CDN do Desk Manager. Alternativa a imagemUrl."),
    imagemNome: z.string().optional().describe("Nome do arquivo de imagem (ex: 'screenshot.png'). Usado com imagemBase64."),
    imagemTipo: z.string().optional().describe("MIME type da imagem (ex: 'image/png'). Padrao: image/png. Usado com imagemBase64."),
    codigoChamado: z.string().optional().describe("Codigo referencia do chamado (ex: '0825-000039'). Necessario para upload de anexo."),
    anexoBase64: z.string().optional().describe("Arquivo em base64 para anexar na interacao via files.desk.ms"),
    anexoNome: z.string().optional().describe("Nome do arquivo anexo (ex: 'relatorio.pdf')"),
    anexoTipo: z.string().optional().describe("MIME type do anexo (ex: 'application/pdf'). Padrao: application/octet-stream"),
  },
  async (args) => {
    try {
      await autenticar();

      // 0. Upload image to CDN if base64 provided
      let imagemUrl = args.imagemUrl || "";
      if (args.imagemBase64 && !imagemUrl) {
        const uploadResult = await enviarAnexo({
          chamado: args.codigoChamado || String(args.chave),
          base64: args.imagemBase64,
          type: args.imagemTipo || "image/png",
          name: args.imagemNome || "image.png",
        });
        // A resposta de sucesso pode conter URL ou apenas {"sucesso":"true"}
        // Para imagens inline, o CDN retorna a URL
        if (uploadResult.url) imagemUrl = uploadResult.url;
      }

      // 0b. Upload file attachment if provided
      let anexoUploadResult = null;
      if (args.anexoBase64) {
        anexoUploadResult = await enviarAnexo({
          chamado: args.codigoChamado || String(args.chave),
          base64: args.anexoBase64,
          type: args.anexoTipo || "application/octet-stream",
          name: args.anexoNome || "arquivo",
        });
      }

      // 1. Resolve status - buscar detalhes do status (FrasePronta) via POST /Status
      let statusFrasePronta = "";
      if (args.status) {
        // Resolver nome do status para Chave/Sequencia via /Status/lista
        const statusRes = await fetch(`${DESKMANAGER_URL}/Status/lista`, {
          method: "POST",
          headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
          body: JSON.stringify({ Pesquisa: args.status }),
        });
        if (statusRes.ok) {
          const statusData = await statusRes.json();
          const statusLista = statusData.root || statusData || [];
          if (Array.isArray(statusLista)) {
            const normalizado = args.status.toLowerCase().trim();
            const found = statusLista.find((s) => (s.Nome || "").toLowerCase().trim() === normalizado)
              || statusLista.find((s) => (s.Nome || "").toLowerCase().includes(normalizado));
            if (found) {
              // Buscar detalhes completos do status (FrasePronta, etc)
              const detRes = await fetch(`${DESKMANAGER_URL}/Status`, {
                method: "POST",
                headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
                body: JSON.stringify({ Chave: String(found.Chave) }),
              });
              if (detRes.ok) {
                const detData = await detRes.json();
                const tStatus = detData.TStatus || detData || {};
                statusFrasePronta = tStatus.FraseProntaDescricao || tStatus.FrasePronta || "";
              }
            }
          }
        }
      }

      // 2. Resolve transfer operator name to code
      let transferirOperadorCode = "";
      if (args.transferirOperador) {
        const opRes = await fetch(`${DESKMANAGER_URL}/Operadores/lista`, {
          method: "POST",
          headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
          body: JSON.stringify({ Pesquisa: args.transferirOperador }),
        });
        if (opRes.ok) {
          const opData = await opRes.json();
          const opLista = opData.root || opData || [];
          if (Array.isArray(opLista)) {
            const normalizado = args.transferirOperador.toLowerCase();
            const found = opLista.find((o) => {
              const nome = `${o.Nome || ""} ${o.Sobrenome || ""}`.trim().toLowerCase();
              return nome.includes(normalizado) || normalizado.includes(nome);
            });
            if (found) transferirOperadorCode = String(found.Chave);
          }
        }
        if (!transferirOperadorCode) {
          return { content: [{ type: "text", text: `Operador de transferencia '${args.transferirOperador}' nao encontrado` }], isError: true };
        }
      }

      // 3. Build description (use FrasePronta template if no description provided)
      let descricao = args.descricao || "";
      if (!descricao && statusFrasePronta) {
        descricao = statusFrasePronta;
      }

      // 4. Embed image using Markdown ![Print](URL) syntax
      if (imagemUrl) {
        const imgMarkdown = `![Print](${imagemUrl})`;
        if (descricao.includes("[imagem]")) {
          descricao = descricao.replace("[imagem]", imgMarkdown);
        } else if (descricao) {
          descricao = `${descricao}\n\n${imgMarkdown}`;
        } else {
          descricao = imgMarkdown;
        }
      }

      // 5. PUT /ChamadosSuporte/interagir
      const body = {
        Chave: String(args.chave),
        Descricao: descricao,
        ...(args.status && { Status: args.status }),
        ...(args.operador && { CodOperador: String(args.operador) }),
        ...(transferirOperadorCode && { TransferirOperador: transferirOperadorCode }),
        ...(args.formaAtendimento && { CodFormaAtendimento: args.formaAtendimento }),
        ...(args.horaInicial && { HoraInicial: args.horaInicial }),
        ObservacaoInterna: args.observacaoInterna ? "S" : "N",
      };
      const res = await fetch(`${DESKMANAGER_URL}/ChamadosSuporte/interagir`, {
        method: "PUT",
        headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
        body: JSON.stringify(body),
      });
      if (!res.ok) throw new Error(`Erro: ${res.status} ${res.statusText}`);
      const data = await res.json();

      const resultado = {
        sucesso: true,
        chave: args.chave,
        status: args.status || null,
        transferirOperador: args.transferirOperador || null,
        transferirOperadorCode: transferirOperadorCode || null,
        descricao: descricao.substring(0, 200),
        ...(statusFrasePronta && { fraseProntaUsada: !args.descricao }),
        resultadoServidor: data,
      };
      if (imagemUrl) {
        resultado.imagemIncluida = true;
        resultado.imagemUrl = imagemUrl;
        resultado.imagemFormato = "![Print](URL) Markdown";
      }
      if (anexoUploadResult) {
        resultado.anexoIncluido = true;
        resultado.anexoResultado = anexoUploadResult;
      }

      return { content: [{ type: "text", text: JSON.stringify(resultado, null, 2) }] };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: comentar_chamado ────────────────────────────────────────────────
server.tool(
  "comentar_chamado",
  "Adiciona um comentario interno a um chamado. Comentarios sao visiveis apenas para operadores. Suporta @mencao de operador e imagem inline.",
  {
    chave: z.number().describe("Chave numerica do chamado"),
    comentario: z.string().describe("Texto do comentario. Quebras de linha (\\n) sao convertidas para <br>. Use [imagem] no texto para posicionar a imagem em local especifico."),
    mencionarOperador: z.string().optional().describe("Nome do operador para @mencao no inicio do comentario (ex: 'Anderson Suporte EIVE')"),
    imagemUrl: z.string().optional().describe("URL de imagem ja hospedada para inserir inline no comentario"),
    imagemLargura: z.number().optional().describe("Largura da imagem em pixels (padrao: 340)"),
  },
  async (args) => {
    try {
      await autenticar();

      // Resolve operator for @mention
      let operadorCode = "";
      let operadorNome = "";
      if (args.mencionarOperador) {
        const opRes = await fetch(`${DESKMANAGER_URL}/Operadores/lista`, {
          method: "POST",
          headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
          body: JSON.stringify({ Pesquisa: args.mencionarOperador }),
        });
        if (opRes.ok) {
          const opData = await opRes.json();
          const opLista = opData.root || opData || [];
          if (Array.isArray(opLista)) {
            const normalizado = args.mencionarOperador.toLowerCase();
            const found = opLista.find((o) => {
              const nome = `${o.Nome || ""} ${o.Sobrenome || ""}`.trim().toLowerCase();
              return nome.includes(normalizado) || normalizado.includes(nome);
            });
            if (found) {
              operadorCode = String(found.Chave);
              operadorNome = `${found.Nome || ""} ${found.Sobrenome || ""}`.trim();
            }
          }
        }
        if (!operadorCode) {
          return { content: [{ type: "text", text: `Operador '${args.mencionarOperador}' nao encontrado` }], isError: true };
        }
      }

      // Format description as HTML
      let descHtml = args.comentario.replace(/\r\n/g, "\n").replace(/\n/g, "<br>");
      if (!descHtml.trim().startsWith("<")) {
        descHtml = `<p>${descHtml}</p>`;
      }

      // Prepend @operator mention
      if (operadorNome) {
        if (descHtml.startsWith("<p>")) {
          descHtml = `<p>@${operadorNome}<br>${descHtml.substring(3)}`;
        } else {
          descHtml = `<p>@${operadorNome}<br></p>${descHtml}`;
        }
      }

      // Insert image inline
      if (args.imagemUrl) {
        const largura = args.imagemLargura || 340;
        const ext = args.imagemUrl.split(".").pop().split("?")[0] || "png";
        const imgTag = `<img style="width: ${largura}px;" src="${args.imagemUrl}" data-filename="image.${ext}">`;
        if (descHtml.includes("[imagem]")) {
          descHtml = descHtml.replace("[imagem]", `<br>${imgTag}<br>`);
        } else if (descHtml.endsWith("</p>")) {
          descHtml = `${descHtml.slice(0, -4)}<br>${imgTag}<br></p>`;
        } else {
          descHtml = `${descHtml}<br>${imgTag}`;
        }
      }

      const body = {
        TComentario: {
          Chave: String(args.chave),
          Operadores: operadorCode,
          Descricao: descHtml,
        },
      };

      const res = await fetch(`${DESKMANAGER_URL}/ChamadosSuporte/comentar`, {
        method: "PUT",
        headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
        body: JSON.stringify(body),
      });
      if (!res.ok) throw new Error(`Erro: ${res.status} ${res.statusText}`);
      const data = await res.json();

      const resultado = {
        sucesso: true,
        chave: args.chave,
        operador: operadorNome || null,
        descricaoHtml: descHtml.substring(0, 500),
        resultadoServidor: data,
      };
      if (args.imagemUrl) resultado.imagemUrl = args.imagemUrl;

      return { content: [{ type: "text", text: JSON.stringify(resultado, null, 2) }] };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: criar_chamado ──────────────────────────────────────────────────
server.tool(
  "criar_chamado",
  "Abre um novo chamado no Deskmanager. Retorna os dados do chamado criado.",
  {
    assunto: z.string().describe("Assunto/titulo do chamado"),
    descricao: z.string().describe("Descricao detalhada do chamado"),
    solicitante: z.number().optional().describe("Chave do solicitante"),
    categoria: z.number().optional().describe("Chave da categoria"),
    prioridade: z.number().optional().describe("Chave da prioridade"),
    operador: z.number().optional().describe("Chave do operador responsavel"),
    grupo: z.number().optional().describe("Chave do grupo de atendimento"),
  },
  async (args) => {
    try {
      await autenticar();
      const body = {
        Assunto: args.assunto,
        Descricao: args.descricao,
        ...(args.solicitante && { CodSolicitante: String(args.solicitante) }),
        ...(args.categoria && { CodCategoria: String(args.categoria) }),
        ...(args.prioridade && { CodPrioridade: String(args.prioridade) }),
        ...(args.operador && { CodOperador: String(args.operador) }),
        ...(args.grupo && { CodGrupo: String(args.grupo) }),
      };
      const res = await fetch(`${DESKMANAGER_URL}/ChamadosSuporte`, {
        method: "PUT",
        headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
        body: JSON.stringify(body),
      });
      if (!res.ok) throw new Error(`Erro: ${res.status} ${res.statusText}`);
      const data = await res.json();
      return { content: [{ type: "text", text: JSON.stringify(data, null, 2) }] };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: editar_chamado ─────────────────────────────────────────────────
server.tool(
  "editar_chamado",
  "Edita/categoriza um chamado existente. Permite alterar status, operador, grupo, categoria, prioridade, assunto (AutoCategoria), campos extras (DevOps, data prevista de entrega) via endpoint dedicado, envio de email e observacao interna.",
  {
    chave: z.number().describe("Chave numerica do chamado a editar"),
    codigo: z.string().optional().describe("Codigo referencia do chamado (ex: '0825-000039'). Necessario para campos extras. Se nao informado, usa a chave numerica."),
    status: z.string().optional().describe("Novo status"),
    operador: z.number().optional().describe("Chave do novo operador"),
    grupo: z.number().optional().describe("Chave do novo grupo"),
    categoria: z.number().optional().describe("Chave da nova categoria"),
    prioridade: z.number().optional().describe("Chave da nova prioridade"),
    assunto: z.string().optional().describe("Nome do assunto/AutoCategoria (ex: 'Erro'). Busca automaticamente na lista de AutoCategorias."),
    devopsWitId: z.string().optional().describe("ID do Work Item do Azure DevOps para preencher campo extra 'DevOps'"),
    dataPrevistaEntrega: z.string().optional().describe("Data prevista de entrega no formato dd/mm/yyyy (ex: '31/03/2026')"),
    camposExtras: z.string().optional().describe("Campos extras adicionais como JSON string de objeto {codigoCampoExtra: valor} (ex: '{\"25307\": \"1234\"}')"),
    envEmail: z.enum(["on", "off"]).optional().describe("Enviar email ao cliente. Padrao: off"),
    observacaoInterna: z.string().optional().describe("Texto de observacao interna"),
  },
  async (args) => {
    try {
      await autenticar();
      const resultados = {};

      // 1. Editar chamado basico (status, operador, grupo, categoria, prioridade, assunto)
      const temEdicaoBasica = args.status || args.operador || args.grupo || args.categoria || args.prioridade || args.assunto || args.observacaoInterna || args.envEmail;

      if (temEdicaoBasica) {
        // Se assunto fornecido, buscar AutoCategoria
        let autoCategoria = "";
        let autoCategoriaArvore = "";
        if (args.assunto) {
          const catRes = await fetch(`${DESKMANAGER_URL}/ChamadosSuporte/ListaAutocategoria`, {
            method: "POST",
            headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
            body: JSON.stringify({ Pesquisa: args.assunto }),
          });
          if (catRes.ok) {
            const catData = await catRes.json();
            const catList = catData.root || catData || [];
            if (Array.isArray(catList)) {
              const normalizado = args.assunto.toLowerCase().trim();
              let found = catList.find((c) => (c.Nome || "").toLowerCase().trim() === normalizado);
              if (!found) found = catList.find((c) => (c.Nome || "").toLowerCase().includes(normalizado));
              if (found) {
                autoCategoria = `${found.Chave}\\`;
                autoCategoriaArvore = found.Nome || args.assunto;
              } else {
                return { content: [{ type: "text", text: `AutoCategoria '${args.assunto}' nao encontrada` }], isError: true };
              }
            }
          }
          resultados.assunto = autoCategoriaArvore;
        }

        const body = {
          Chave: String(args.chave),
          ...(args.status && { Status: args.status }),
          ...(args.operador && { CodOperador: String(args.operador) }),
          ...(args.grupo && { CodGrupo: String(args.grupo) }),
          ...(args.categoria && { CodCategoria: String(args.categoria) }),
          ...(args.prioridade && { CodPrioridade: String(args.prioridade) }),
          ...(autoCategoria && { AutoCategoria: autoCategoria, AutoCategoriaArvore: autoCategoriaArvore }),
          ...(args.observacaoInterna && { ObservacaoInterna: args.observacaoInterna }),
          ...(args.envEmail && { EnvEmail: args.envEmail }),
        };

        const res = await fetch(`${DESKMANAGER_URL}/ChamadosSuporte`, {
          method: "PUT",
          headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
          body: JSON.stringify(body),
        });
        if (!res.ok) throw new Error(`Erro ao editar chamado: ${res.status} ${res.statusText}`);
        resultados.edicaoBasica = await res.json();
      }

      // 2. Atualizar campos extras via endpoint dedicado PUT /ChamadosSuporte/camposextras
      const temCamposExtras = args.devopsWitId || args.dataPrevistaEntrega || args.camposExtras;

      if (temCamposExtras) {
        const chaveRef = args.codigo || String(args.chave);

        // 2a. Buscar campos extras atuais via POST /ChamadosSuporte/camposextras
        const ceRes = await fetch(`${DESKMANAGER_URL}/ChamadosSuporte/camposextras`, {
          method: "POST",
          headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
          body: JSON.stringify({ Chave: chaveRef }),
        });
        if (!ceRes.ok) throw new Error(`Erro ao buscar campos extras: ${ceRes.status}`);
        const ceData = await ceRes.json();
        const ceList = ceData.TCamposExtras || [];

        // Mapear nome -> codcampoextra e ordem
        const ceMap = {};
        for (const ce of ceList) {
          ceMap[String(ce.codcampoextra)] = {
            nome: (ce.nomecampoextra || "").trim().toLowerCase(),
            ordem: ce.ordemcampoextra || 0,
            valor: ce.valcampoextra || "",
          };
        }

        // Montar TCampoExtra e TCampoExtraOrdem
        const tCampoExtra = {};
        const tCampoExtraOrdem = {};
        for (const [cod, info] of Object.entries(ceMap)) {
          tCampoExtra[cod] = info.valor;
          tCampoExtraOrdem[cod] = String(info.ordem);
        }

        // Aplicar DevOps WIT ID
        if (args.devopsWitId) {
          const devopsEntry = Object.entries(ceMap).find(([, info]) => info.nome === "devops");
          if (devopsEntry) tCampoExtra[devopsEntry[0]] = String(args.devopsWitId);
        }

        // Aplicar data prevista de entrega
        if (args.dataPrevistaEntrega) {
          const dataEntry = Object.entries(ceMap).find(([, info]) => info.nome.includes("data prevista"));
          if (dataEntry) tCampoExtra[dataEntry[0]] = String(args.dataPrevistaEntrega);
        }

        // Aplicar campos extras adicionais (por codigo ou nome)
        if (args.camposExtras) {
          const camposObj = typeof args.camposExtras === "string" ? JSON.parse(args.camposExtras) : args.camposExtras;
          for (const [key, value] of Object.entries(camposObj)) {
            if (/^\d+$/.test(key)) {
              tCampoExtra[key] = String(value);
            } else {
              const normalizado = key.trim().toLowerCase();
              const entry = Object.entries(ceMap).find(([, info]) => info.nome === normalizado);
              if (entry) tCampoExtra[entry[0]] = String(value);
            }
          }
        }

        // 2b. Salvar campos extras via PUT /ChamadosSuporte/camposextras
        const ceBody = {
          TChamado: { Chave: chaveRef },
          TCampoExtra: tCampoExtra,
          TCampoExtraOrdem: tCampoExtraOrdem,
        };
        const cePutRes = await fetch(`${DESKMANAGER_URL}/ChamadosSuporte/camposextras`, {
          method: "PUT",
          headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
          body: JSON.stringify(ceBody),
        });
        if (!cePutRes.ok) throw new Error(`Erro ao salvar campos extras: ${cePutRes.status}`);
        resultados.camposExtras = await cePutRes.json();
        if (args.devopsWitId) resultados.devopsWitId = args.devopsWitId;
        if (args.dataPrevistaEntrega) resultados.dataPrevistaEntrega = args.dataPrevistaEntrega;
      }

      return {
        content: [{
          type: "text",
          text: JSON.stringify({ sucesso: true, chave: args.chave, ...resultados }, null, 2),
        }],
      };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: listar_operadores ──────────────────────────────────────────────
server.tool(
  "listar_operadores",
  "Lista operadores/atendentes disponiveis no Deskmanager. Util para saber quem pode ser atribuido a um chamado.",
  {
    pesquisa: z.string().optional().describe("Filtrar operadores por nome"),
  },
  async (args) => {
    try {
      await autenticar();
      const body = {
        ...(args.pesquisa && { Pesquisa: args.pesquisa }),
      };
      const res = await fetch(`${DESKMANAGER_URL}/Operadores/lista`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
        body: JSON.stringify(body),
      });
      if (!res.ok) throw new Error(`Erro: ${res.status} ${res.statusText}`);
      const data = await res.json();
      const lista = data.root || data || [];
      const operadores = Array.isArray(lista) ? lista.map((o) => ({
        chave: o.Chave,
        nome: `${o.Nome || ""} ${o.Sobrenome || ""}`.trim(),
        email: o.Email || o.EmailOperador || "",
        ativo: o.Ativo === "S",
      })) : lista;
      return { content: [{ type: "text", text: JSON.stringify({ total: Array.isArray(operadores) ? operadores.length : 0, operadores }, null, 2) }] };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: listar_grupos ──────────────────────────────────────────────────
server.tool(
  "listar_grupos",
  "Lista grupos de atendimento disponiveis no Deskmanager.",
  {
    pesquisa: z.string().optional().describe("Filtrar grupos por nome"),
  },
  async (args) => {
    try {
      await autenticar();
      const body = {
        ...(args.pesquisa && { Pesquisa: args.pesquisa }),
      };
      const res = await fetch(`${DESKMANAGER_URL}/Grupos/lista`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
        body: JSON.stringify(body),
      });
      if (!res.ok) throw new Error(`Erro: ${res.status} ${res.statusText}`);
      const data = await res.json();
      const lista = data.root || data || [];
      const grupos = Array.isArray(lista) ? lista.map((g) => ({
        chave: g.Chave,
        nome: g.Nome || g.NomeGrupo || "",
        ativo: g.Ativo === "S",
      })) : lista;
      return { content: [{ type: "text", text: JSON.stringify({ total: Array.isArray(grupos) ? grupos.length : 0, grupos }, null, 2) }] };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: listar_categorias ──────────────────────────────────────────────
server.tool(
  "listar_categorias",
  "Lista categorias de chamados disponiveis no Deskmanager.",
  {
    pesquisa: z.string().optional().describe("Filtrar categorias por nome"),
  },
  async (args) => {
    try {
      await autenticar();
      const body = {
        ...(args.pesquisa && { Pesquisa: args.pesquisa }),
      };
      const res = await fetch(`${DESKMANAGER_URL}/Categorias/lista`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
        body: JSON.stringify(body),
      });
      if (!res.ok) throw new Error(`Erro: ${res.status} ${res.statusText}`);
      const data = await res.json();
      const lista = data.root || data || [];
      const categorias = Array.isArray(lista) ? lista.map((c) => ({
        chave: c.Chave,
        nome: c.Nome || c.NomeCategoria || "",
        ativo: c.Ativo === "S",
      })) : lista;
      return { content: [{ type: "text", text: JSON.stringify({ total: Array.isArray(categorias) ? categorias.length : 0, categorias }, null, 2) }] };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: listar_clientes ────────────────────────────────────────────────
server.tool(
  "listar_clientes",
  "Lista clientes/empresas cadastrados no Deskmanager.",
  {
    pesquisa: z.string().optional().describe("Filtrar clientes por nome ou CNPJ"),
    limite: z.number().optional().describe("Numero maximo de resultados. Padrao: 50"),
  },
  async (args) => {
    try {
      await autenticar();
      const body = {
        ...(args.pesquisa && { Pesquisa: args.pesquisa }),
      };
      const res = await fetch(`${DESKMANAGER_URL}/Clientes/lista`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
        body: JSON.stringify(body),
      });
      if (!res.ok) throw new Error(`Erro: ${res.status} ${res.statusText}`);
      const data = await res.json();
      const lista = data.root || data || [];
      const maxItems = args.limite || 50;
      const clientes = Array.isArray(lista) ? lista.slice(0, maxItems).map((c) => ({
        chave: c.Chave,
        nome: c.NomeFantasia || c.RazaoSocial || c.Nome || "",
        razaoSocial: c.RazaoSocial || "",
        cnpj: c.CNPJ || c.CpfCnpj || "",
        email: c.Email || "",
        telefone: c.Telefone || "",
        ativo: c.Ativo === "S",
      })) : lista;
      return { content: [{ type: "text", text: JSON.stringify({ total: Array.isArray(clientes) ? clientes.length : 0, clientes }, null, 2) }] };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: listar_solicitantes ────────────────────────────────────────────
server.tool(
  "listar_solicitantes",
  "Lista solicitantes (usuarios que abrem chamados) cadastrados no Deskmanager.",
  {
    pesquisa: z.string().optional().describe("Filtrar solicitantes por nome ou email"),
    cliente: z.number().optional().describe("Filtrar por chave do cliente/empresa"),
    limite: z.number().optional().describe("Numero maximo de resultados. Padrao: 50"),
  },
  async (args) => {
    try {
      await autenticar();
      const body = {
        ...(args.pesquisa && { Pesquisa: args.pesquisa }),
        ...(args.cliente && { CodCliente: String(args.cliente) }),
      };
      const res = await fetch(`${DESKMANAGER_URL}/Solicitantes/lista`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
        body: JSON.stringify(body),
      });
      if (!res.ok) throw new Error(`Erro: ${res.status} ${res.statusText}`);
      const data = await res.json();
      const lista = data.root || data || [];
      const maxItems = args.limite || 50;
      const solicitantes = Array.isArray(lista) ? lista.slice(0, maxItems).map((s) => ({
        chave: s.Chave,
        nome: `${s.Nome || ""} ${s.Sobrenome || ""}`.trim(),
        email: s.Email || "",
        cliente: s.NomeCliente || s.NomeFantasia || "",
        ativo: s.Ativo === "S",
      })) : lista;
      return { content: [{ type: "text", text: JSON.stringify({ total: Array.isArray(solicitantes) ? solicitantes.length : 0, solicitantes }, null, 2) }] };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: buscar_base_conhecimento ───────────────────────────────────────
server.tool(
  "buscar_base_conhecimento",
  "Pesquisa artigos na base de conhecimento do Deskmanager. Util para encontrar solucoes conhecidas.",
  {
    pesquisa: z.string().optional().describe("Texto para buscar nos artigos"),
    limite: z.number().optional().describe("Numero maximo de resultados. Padrao: 20"),
  },
  async (args) => {
    try {
      await autenticar();
      const body = {
        ...(args.pesquisa && { Pesquisa: args.pesquisa }),
      };
      const res = await fetch(`${DESKMANAGER_URL}/BaseConhecimento/lista`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
        body: JSON.stringify(body),
      });
      if (!res.ok) throw new Error(`Erro: ${res.status} ${res.statusText}`);
      const data = await res.json();
      const lista = data.root || data || [];
      const maxItems = args.limite || 20;
      const artigos = Array.isArray(lista) ? lista.slice(0, maxItems).map((a) => ({
        chave: a.Chave,
        titulo: a.Titulo || a.Assunto || "",
        categoria: a.NomeCategoria || "",
        visualizacoes: a.Visualizacoes || 0,
        ativo: a.Ativo === "S",
      })) : lista;
      return { content: [{ type: "text", text: JSON.stringify({ total: Array.isArray(artigos) ? artigos.length : 0, artigos }, null, 2) }] };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: listar_tarefas_chamado ─────────────────────────────────────────
server.tool(
  "listar_tarefas_chamado",
  "Lista as tarefas vinculadas a um chamado especifico.",
  {
    chamado: z.number().describe("Chave numerica do chamado"),
  },
  async (args) => {
    try {
      await autenticar();
      const body = {
        CodChamado: String(args.chamado),
      };
      const res = await fetch(`${DESKMANAGER_URL}/Tarefas/lista`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
        body: JSON.stringify(body),
      });
      if (!res.ok) throw new Error(`Erro: ${res.status} ${res.statusText}`);
      const data = await res.json();
      const lista = data.root || data || [];
      const tarefas = Array.isArray(lista) ? lista.map((t) => ({
        chave: t.Chave,
        titulo: t.Titulo || t.Descricao || "",
        status: t.NomeStatus || t.Status || "",
        responsavel: t.NomeOperador || t.Responsavel || "",
        dataCriacao: t.DataCriacao || "",
        dataPrevisao: t.DataPrevisao || "",
      })) : lista;
      return { content: [{ type: "text", text: JSON.stringify({ total: Array.isArray(tarefas) ? tarefas.length : 0, tarefas }, null, 2) }] };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: listar_status ──────────────────────────────────────────────────
server.tool(
  "listar_status",
  "Lista status de chamados disponiveis no Deskmanager. Util para saber quais status existem antes de filtrar chamados.",
  {
    pesquisa: z.string().optional().describe("Filtrar status por nome"),
  },
  async (args) => {
    try {
      await autenticar();
      const body = {
        ...(args.pesquisa && { Pesquisa: args.pesquisa }),
      };
      const res = await fetch(`${DESKMANAGER_URL}/Status/lista`, {
        method: "POST",
        headers: { "Content-Type": "application/json", Authorization: getAuthHeader() },
        body: JSON.stringify(body),
      });
      if (!res.ok) throw new Error(`Erro: ${res.status} ${res.statusText}`);
      const data = await res.json();
      const lista = data.root || data || [];
      const statusList = Array.isArray(lista) ? lista.map((s) => ({
        chave: s.Chave,
        sequencia: s.Sequencia,
        nome: s.Nome || s.NomeStatus || "",
      })) : lista;
      return { content: [{ type: "text", text: JSON.stringify({ total: Array.isArray(statusList) ? statusList.length : 0, status: statusList }, null, 2) }] };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── Tool: processar_imagens_chamado ──────────────────────────────────────
server.tool(
  "processar_imagens_chamado",
  "Processa imagens imgur de um chamado: converte links imgur em tags <img> no HTML. Retorna HTML atualizado com <img> e lista de URLs de imagens encontradas. Responsabilidade: apenas Deskmanager. Upload para DevOps deve ser feito via MCP do Azure DevOps.",
  {
    html: z.string().describe("HTML contendo links de imagens imgur (ex: historico ou descricao de chamado)"),
  },
  async (args) => {
    try {
      const urls = extrairUrlsImgur(args.html);
      if (urls.length === 0) {
        return { content: [{ type: "text", text: JSON.stringify({ mensagem: "Nenhuma imagem imgur encontrada no HTML", imagensEncontradas: 0, html: args.html, imagens: [] }, null, 2) }] };
      }
      const resultado = converterImgurParaHtml(args.html);
      return {
        content: [{
          type: "text",
          text: JSON.stringify({
            mensagem: `${resultado.imagens.length} imagem(ns) encontrada(s) e convertida(s) para <img>`,
            imagensEncontradas: resultado.imagens.length,
            imagens: resultado.imagens,
            html: resultado.html,
          }, null, 2),
        }],
      };
    } catch (e) {
      return { content: [{ type: "text", text: `Erro: ${e.message}` }], isError: true };
    }
  }
);

// ── START ──────────────────────────────────────────────────────────────────
async function main() {
  if (!DESKMANAGER_API_KEY || !DESKMANAGER_PUBLIC_KEY) {
    console.error("DESKMANAGER_API_KEY e DESKMANAGER_PUBLIC_KEY sao obrigatorios");
    process.exit(1);
  }

  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((err) => {
  console.error("Erro fatal no Deskmanager MCP:", err);
  process.exit(1);
});
