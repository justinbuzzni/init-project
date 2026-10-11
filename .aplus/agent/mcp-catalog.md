# A+ Common MCP Catalog

This file is the local routing guide for common MCP skills available through:

`mcp__aplus-common__get_common_skill`

Prefer the MCP body over this summary. This file exists so agents can choose the right lazy skill even when a Studio button did not inject a trigger prompt.

## Managed Automation Tool

Use Happy `script_automations` for project script schedules, manual runs and API-triggered work. See the Managed Script Automations section in project-template.md.

## Context Defaults

- frontend_port: 30004
- backend_port: 40002

Use assigned ports exactly when passing context. If a port is not assigned, omit it or pass null.

## Skills

### project-template

Use when implementing, building the initial app, continuing from planning/design, or creating the product.

```text
skill_id: "project-template"
context:
  frontend_port: 30004
  backend_port: 40002
  plan_file: "AX_PROJECT_PLAN.md"
  # Optional: design_file / design_content only when explicitly selected or written.
```

### project-analyze

Use when starting, running, analyzing, fixing, or connecting the dev server / preview.

```text
skill_id: "project-analyze"
context:
  frontend_port: 30004
  backend_port: 40002
```

### debug-diagnose

Use when the user reports a bug, broken behavior, failing command, flaky behavior, or performance regression, or asks to debug/diagnose something.

```text
skill_id: "debug-diagnose"
```

Follow the returned body: build a feedback loop, reproduce, rank hypotheses, instrument one variable at a time, fix with a regression test, and clean up debug probes.

### common_documents

Use when creating, editing, previewing, or validating PDF, DOCX, PPTX, XLSX, or self-contained HTML document artifacts.

```text
skill_id: "common_documents"
```

Call the common MCP skill before starting document work and follow the returned body. If the MCP tool is unavailable, times out, or fails, use this local fallback only:

- Store every user-facing original below the project-root `documents/` directory.
- Render DOCX and PPTX to PDF, render every relevant document page or slide, visually inspect every rendered page or slide, and fix clipping, overlap, missing glyphs, broken tables, and unexpected blank pages before completion.
- After a DOCX or PPTX passes visual QA, write its PDF preview to `documents/.previews/<original-relative-path>/preview.pdf` and write the checksum manifest last in the same directory. Do not list preview sidecars as deliverables.
- Treat static self-contained HTML as a document without an app preview port. Treat HTML requiring JavaScript execution or a server as an app and use the normal `axstudio-config` contract.
- Return only verified originals in the completion marker:

```axstudio-work-complete
{ "kind": "document", "artifacts": [{ "path": "documents/output.docx" }] }
```

### plan-think

Use when the user enables Think mode or asks to plan carefully before implementation.

```text
skill_id: "plan-think"
```

### backend-expansion

Use when a React/Vite frontend-only project needs a FastAPI backend, or when a PocketBase light project is being migrated to MongoDB/PostgreSQL.

```text
skill_id: "backend-expansion"
context:
  frontend_port: 30004
  backend_port: 40002
```

Follow the returned body: add a backend only when persistence, secrets, auth, jobs, uploads, server-side validation, or privileged external APIs require it; treat PocketBase to MongoDB/PostgreSQL as a backend replacement, not a PocketBase storage swap.

### db-setting

Use only for the backend auto scaffold flow from a static HTML mockup plus DB env. The trigger should pass AST and dispatch context blocks so placeholders can be replaced.
