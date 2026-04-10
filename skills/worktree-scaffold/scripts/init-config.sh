#!/usr/bin/env bash
# init-config.sh - Generate .worktree-scaffold.json template
# Usage: init-config.sh [--type react|node|python|minimal]

set -euo pipefail

CONFIG_FILE=".worktree-scaffold.json"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

# Minimal configuration
minimal_config() {
  cat << 'EOF'
{
  "worktreeDir": "../",
  "branchPrefix": "feature/",
  "scaffolds": {
    "default": [
      { "path": "src/{name}/index.ts", "template": "index" },
      { "path": "src/{name}/README.md", "template": "readme" }
    ]
  },
  "templates": {
    "index": "// {Name} Feature\n// Created: {date} by {author}\n\nexport const {Name} = {};\n",
    "readme": "# {Name}\n\nFeature created on {date}.\n\n## Overview\n\nTODO: Describe this feature.\n"
  }
}
EOF
}

# React/TypeScript configuration
react_config() {
  cat << 'EOF'
{
  "worktreeDir": "../",
  "branchPrefix": "feature/",
  "scaffolds": {
    "default": [
      { "path": "src/features/{name}/index.ts", "template": "feature-index" },
      { "path": "src/features/{name}/types.ts", "template": "feature-types" },
      { "path": "src/features/{name}/__tests__/{name}.test.ts", "template": "feature-test" }
    ],
    "component": [
      { "path": "src/components/{Name}/{Name}.tsx", "template": "react-component" },
      { "path": "src/components/{Name}/{Name}.test.tsx", "template": "component-test" },
      { "path": "src/components/{Name}/index.ts", "template": "component-index" },
      { "path": "src/components/{Name}/{Name}.module.css", "template": "component-styles" }
    ],
    "page": [
      { "path": "src/pages/{name}/index.tsx", "template": "page-component" },
      { "path": "src/pages/{name}/loader.ts", "template": "page-loader" }
    ],
    "api": [
      { "path": "src/api/{name}/route.ts", "template": "api-route" },
      { "path": "src/api/{name}/handler.ts", "template": "api-handler" },
      { "path": "src/api/{name}/types.ts", "template": "api-types" }
    ]
  },
  "templates": {
    "feature-index": "// {Name} Feature\n// Created: {date} by {author}\n\nexport * from './types';\n",
    "feature-types": "export interface {Name}Props {\n  // TODO: Define props\n}\n\nexport interface {Name}State {\n  loading: boolean;\n  error: string | null;\n  data: unknown;\n}\n",
    "feature-test": "import { describe, it, expect } from 'vitest';\n\ndescribe('{Name}', () => {\n  it('should work', () => {\n    expect(true).toBe(true);\n  });\n});\n",
    "react-component": "import React from 'react';\nimport styles from './{Name}.module.css';\n\nexport interface {Name}Props {\n  children?: React.ReactNode;\n}\n\nexport const {Name}: React.FC<{Name}Props> = ({ children }) => {\n  return (\n    <div className={styles.container}>\n      {children}\n    </div>\n  );\n};\n",
    "component-test": "import { render, screen } from '@testing-library/react';\nimport { {Name} } from './{Name}';\n\ndescribe('{Name}', () => {\n  it('renders children', () => {\n    render(<{Name}>Test</{Name}>);\n    expect(screen.getByText('Test')).toBeInTheDocument();\n  });\n});\n",
    "component-index": "export { {Name} } from './{Name}';\nexport type { {Name}Props } from './{Name}';\n",
    "component-styles": ".container {\n  /* TODO: Add styles */\n}\n",
    "page-component": "import React from 'react';\nimport { useLoaderData } from 'react-router-dom';\nimport type { {Name}LoaderData } from './loader';\n\nexport default function {Name}Page() {\n  const data = useLoaderData() as {Name}LoaderData;\n  \n  return (\n    <div>\n      <h1>{Name}</h1>\n    </div>\n  );\n}\n",
    "page-loader": "export interface {Name}LoaderData {\n  // TODO: Define loader data\n}\n\nexport async function loader(): Promise<{Name}LoaderData> {\n  // TODO: Implement loader\n  return {};\n}\n",
    "api-route": "import { {name}Handler } from './handler';\n\nexport async function GET(request: Request) {\n  return {name}Handler.get(request);\n}\n\nexport async function POST(request: Request) {\n  return {name}Handler.post(request);\n}\n",
    "api-handler": "import type { {Name}Request, {Name}Response } from './types';\n\nexport const {name}Handler = {\n  async get(request: Request): Promise<Response> {\n    // TODO: Implement GET handler\n    return Response.json({ message: 'GET {name}' });\n  },\n  \n  async post(request: Request): Promise<Response> {\n    // TODO: Implement POST handler\n    const body = await request.json() as {Name}Request;\n    return Response.json({ message: 'POST {name}' });\n  },\n};\n",
    "api-types": "export interface {Name}Request {\n  // TODO: Define request type\n}\n\nexport interface {Name}Response {\n  // TODO: Define response type\n}\n"
  },
  "hooks": {
    "postScaffold": ""
  }
}
EOF
}

# Node.js/Express configuration
node_config() {
  cat << 'EOF'
{
  "worktreeDir": "../",
  "branchPrefix": "feature/",
  "scaffolds": {
    "default": [
      { "path": "src/{name}/index.js", "template": "module-index" },
      { "path": "src/{name}/{name}.js", "template": "module-main" },
      { "path": "tests/{name}.test.js", "template": "module-test" }
    ],
    "route": [
      { "path": "src/routes/{name}.js", "template": "express-route" },
      { "path": "src/controllers/{name}.js", "template": "express-controller" },
      { "path": "src/services/{name}.js", "template": "express-service" }
    ],
    "middleware": [
      { "path": "src/middleware/{name}.js", "template": "middleware" }
    ]
  },
  "templates": {
    "module-index": "// {Name} Module\n// Created: {date} by {author}\n\nmodule.exports = require('./{name}');\n",
    "module-main": "/**\n * {Name} Module\n * @module {name}\n */\n\nclass {Name} {\n  constructor() {\n    // TODO: Initialize\n  }\n}\n\nmodule.exports = { {Name} };\n",
    "module-test": "const { {Name} } = require('../src/{name}');\n\ndescribe('{Name}', () => {\n  it('should be defined', () => {\n    expect({Name}).toBeDefined();\n  });\n});\n",
    "express-route": "const express = require('express');\nconst router = express.Router();\nconst {name}Controller = require('../controllers/{name}');\n\nrouter.get('/', {name}Controller.list);\nrouter.get('/:id', {name}Controller.get);\nrouter.post('/', {name}Controller.create);\nrouter.put('/:id', {name}Controller.update);\nrouter.delete('/:id', {name}Controller.remove);\n\nmodule.exports = router;\n",
    "express-controller": "const {name}Service = require('../services/{name}');\n\nmodule.exports = {\n  async list(req, res, next) {\n    try {\n      const items = await {name}Service.findAll();\n      res.json(items);\n    } catch (err) {\n      next(err);\n    }\n  },\n  \n  async get(req, res, next) {\n    try {\n      const item = await {name}Service.findById(req.params.id);\n      res.json(item);\n    } catch (err) {\n      next(err);\n    }\n  },\n  \n  async create(req, res, next) {\n    try {\n      const item = await {name}Service.create(req.body);\n      res.status(201).json(item);\n    } catch (err) {\n      next(err);\n    }\n  },\n  \n  async update(req, res, next) {\n    try {\n      const item = await {name}Service.update(req.params.id, req.body);\n      res.json(item);\n    } catch (err) {\n      next(err);\n    }\n  },\n  \n  async remove(req, res, next) {\n    try {\n      await {name}Service.remove(req.params.id);\n      res.status(204).end();\n    } catch (err) {\n      next(err);\n    }\n  },\n};\n",
    "express-service": "// {Name} Service\n// Business logic for {name}\n\nmodule.exports = {\n  async findAll() {\n    // TODO: Implement\n    return [];\n  },\n  \n  async findById(id) {\n    // TODO: Implement\n    return null;\n  },\n  \n  async create(data) {\n    // TODO: Implement\n    return data;\n  },\n  \n  async update(id, data) {\n    // TODO: Implement\n    return data;\n  },\n  \n  async remove(id) {\n    // TODO: Implement\n    return true;\n  },\n};\n",
    "middleware": "/**\n * {Name} Middleware\n * Created: {date} by {author}\n */\n\nmodule.exports = function {name}Middleware(req, res, next) {\n  // TODO: Implement middleware logic\n  next();\n};\n"
  }
}
EOF
}

# Python configuration
python_config() {
  cat << 'EOF'
{
  "worktreeDir": "../",
  "branchPrefix": "feature/",
  "scaffolds": {
    "default": [
      { "path": "src/{name}/__init__.py", "template": "python-init" },
      { "path": "src/{name}/{name}.py", "template": "python-module" },
      { "path": "tests/test_{name}.py", "template": "python-test" }
    ],
    "api": [
      { "path": "src/api/{name}/routes.py", "template": "fastapi-routes" },
      { "path": "src/api/{name}/schemas.py", "template": "pydantic-schemas" },
      { "path": "src/api/{name}/service.py", "template": "python-service" }
    ],
    "cli": [
      { "path": "src/cli/{name}.py", "template": "click-command" }
    ]
  },
  "templates": {
    "python-init": "\"\"\"\n{Name} Module\n\nCreated: {date} by {author}\n\"\"\"\n\nfrom .{name} import *\n",
    "python-module": "\"\"\"\n{Name} Module\n\nTODO: Add module description.\n\"\"\"\n\n\nclass {Name}:\n    \"\"\"Main {Name} class.\"\"\"\n    \n    def __init__(self):\n        \"\"\"Initialize {Name}.\"\"\"\n        pass\n    \n    def run(self):\n        \"\"\"Execute main logic.\"\"\"\n        raise NotImplementedError\n",
    "python-test": "\"\"\"Tests for {name} module.\"\"\"\n\nimport pytest\nfrom src.{name} import {Name}\n\n\nclass Test{Name}:\n    \"\"\"Test cases for {Name}.\"\"\"\n    \n    def test_init(self):\n        \"\"\"Test initialization.\"\"\"\n        obj = {Name}()\n        assert obj is not None\n    \n    def test_run_not_implemented(self):\n        \"\"\"Test run raises NotImplementedError.\"\"\"\n        obj = {Name}()\n        with pytest.raises(NotImplementedError):\n            obj.run()\n",
    "fastapi-routes": "\"\"\"API routes for {name}.\"\"\"\n\nfrom fastapi import APIRouter, HTTPException\nfrom .schemas import {Name}Create, {Name}Response\nfrom .service import {name}_service\n\nrouter = APIRouter(prefix=\"/{name}\", tags=[\"{name}\"])\n\n\n@router.get(\"/\", response_model=list[{Name}Response])\nasync def list_{name}s():\n    \"\"\"List all {name}s.\"\"\"\n    return await {name}_service.find_all()\n\n\n@router.get(\"/{item_id}\", response_model={Name}Response)\nasync def get_{name}(item_id: str):\n    \"\"\"Get a {name} by ID.\"\"\"\n    item = await {name}_service.find_by_id(item_id)\n    if not item:\n        raise HTTPException(status_code=404, detail=\"{Name} not found\")\n    return item\n\n\n@router.post(\"/\", response_model={Name}Response, status_code=201)\nasync def create_{name}(data: {Name}Create):\n    \"\"\"Create a new {name}.\"\"\"\n    return await {name}_service.create(data)\n",
    "pydantic-schemas": "\"\"\"Pydantic schemas for {name}.\"\"\"\n\nfrom pydantic import BaseModel\nfrom datetime import datetime\nfrom typing import Optional\n\n\nclass {Name}Base(BaseModel):\n    \"\"\"Base {name} schema.\"\"\"\n    name: str\n    description: Optional[str] = None\n\n\nclass {Name}Create({Name}Base):\n    \"\"\"Schema for creating a {name}.\"\"\"\n    pass\n\n\nclass {Name}Response({Name}Base):\n    \"\"\"Schema for {name} response.\"\"\"\n    id: str\n    created_at: datetime\n    updated_at: datetime\n    \n    class Config:\n        from_attributes = True\n",
    "python-service": "\"\"\"{Name} service layer.\"\"\"\n\nfrom typing import Optional\nfrom .schemas import {Name}Create, {Name}Response\n\n\nclass {Name}Service:\n    \"\"\"Service for {name} operations.\"\"\"\n    \n    async def find_all(self) -> list[dict]:\n        \"\"\"Find all {name}s.\"\"\"\n        # TODO: Implement\n        return []\n    \n    async def find_by_id(self, item_id: str) -> Optional[dict]:\n        \"\"\"Find {name} by ID.\"\"\"\n        # TODO: Implement\n        return None\n    \n    async def create(self, data: {Name}Create) -> dict:\n        \"\"\"Create a new {name}.\"\"\"\n        # TODO: Implement\n        return data.model_dump()\n\n\n{name}_service = {Name}Service()\n",
    "click-command": "\"\"\"CLI command for {name}.\"\"\"\n\nimport click\n\n\n@click.command()\n@click.option('--verbose', '-v', is_flag=True, help='Enable verbose output')\n@click.argument('input', required=False)\ndef {name}(verbose: bool, input: str):\n    \"\"\"{Name} command.\n    \n    TODO: Add command description.\n    \"\"\"\n    if verbose:\n        click.echo('Running in verbose mode...')\n    \n    if input:\n        click.echo(f'Processing: {input}')\n    else:\n        click.echo('{Name} command executed')\n\n\nif __name__ == '__main__':\n    {name}()\n"
  }
}
EOF
}

# Main function
main() {
  local config_type="${1:-react}"
  
  # Remove -- prefix if present
  config_type="${config_type#--type=}"
  config_type="${config_type#--}"
  
  if [[ -f "$CONFIG_FILE" ]]; then
    log_warn "$CONFIG_FILE already exists"
    read -rp "Overwrite? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy] ]]; then
      log_info "Aborted"
      exit 0
    fi
  fi
  
  log_info "Generating $CONFIG_FILE with '$config_type' template..."
  
  case "$config_type" in
    minimal)
      minimal_config > "$CONFIG_FILE"
      ;;
    react|typescript|ts)
      react_config > "$CONFIG_FILE"
      ;;
    node|express|js)
      node_config > "$CONFIG_FILE"
      ;;
    python|py|fastapi)
      python_config > "$CONFIG_FILE"
      ;;
    *)
      log_warn "Unknown type '$config_type', using react"
      react_config > "$CONFIG_FILE"
      ;;
  esac
  
  log_success "Created $CONFIG_FILE"
  log_info "Edit the file to customize templates for your project"
}

main "$@"
