# Local Inference Gateway

## O que faz

Configura um gateway de inferência multi-modelo unificado usando LiteLLM. Executa modelos locais no seu Mac (MLX, Ollama) com fallback automático para cloud (OpenRouter, Anthropic) — tudo por trás de uma única API compatível com OpenAI em `http://localhost:4000/v1`.

Use junto com seu plano Claude Max. Claude cuida da orquestração e raciocínio complexo. Modelos locais cuidam das tarefas baratas — sumarização, formatação, classificação, geração de texto — gratuitamente.

## Como invocar

```
/local-inference
```

A skill guia você interativamente através de:
- Detecção do seu ambiente (RAM, OS, dependências existentes)
- Seleção de backends (Ollama, MLX, OpenRouter, Anthropic)
- Download e configuração de modelos
- Testes de fallback automático
- Setup de auto-inicialização (opcional)

**Exemplos de uso após setup:**

```bash
# Via curl
curl http://localhost:4000/v1/chat/completions \
  -d '{"model":"local","messages":[{"role":"user","content":"Resuma isto: ..."}]}'

# Via Python
client = OpenAI(base_url="http://localhost:4000/v1", api_key="none")
response = client.chat.completions.create(model="local", messages=[...])
```

## Quando usar

- **Você roda Claude Max** e quer economizar em chamadas pequenas (formatação, sumarização)
- **Quer fallback automático** entre múltiplos backends (Ollama, MLX, cloud)
- **Tem hardware local** (Mac Apple Silicon, Linux com GPU) e quer aproveitar
- **Integra ferramentas** (scripts, IDEs, apps) que falam OpenAI API
