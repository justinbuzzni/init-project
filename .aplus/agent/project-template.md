# A+ Project Template

This is the file-based fallback and MCP routing guide for this A+ Studio project.

Use it when:
- the common MCP skill is unavailable,
- the user did not press a Studio trigger button,
- or the workspace is empty / has no clear app structure yet.

## Assigned Ports

- frontend_port: 30004
- backend_port: 40002

If a port is assigned above, use it exactly for the matching service. Do not silently switch to another port. If the assigned port is occupied, report the blocker with the owning process.

These ports are for local development and Container Preview only. Do not bake them into deploy artifacts — no literal port in `Dockerfile` (`ENV PORT=`, `EXPOSE`, `CMD`), in `docker-compose.yml` (`ports:`, `PORT=`), or in the start command. Deploy routes traffic by `PORT` / `APLUS_HTTP_PORT`, so a dev port baked into those files makes the container listen where the proxy never reaches: the container is Up and the build succeeds, yet the public URL is a permanent 502 and no layer reports a failure. Read the listen port from `process.env.PORT` with a local default instead, and let the deploy start command pass no explicit listen port.

Frameworks that check the request Host must accept the deploy domain too. A dev-only host allowlist answers the public URL with 403 instead of the app — for example Vite's `preview` needs `allowedHosts` to cover it.

## Planning Document Authoring

When the user asks to create, refine, or compare planning proposals, treat that as planning work, not implementation work.

Do not write new planning content to `AX_PROJECT_PLAN.md` unless the user explicitly names that legacy file.
Use a specs bundle instead:

```text
specs/[feature-slug]/prd.md
specs/[feature-slug]/spec.md
specs/[feature-slug]/plan.md
specs/[feature-slug]/context.md
```

Rules:

- Pick `[feature-slug]` from the planning title in lowercase kebab-case. Korean slugs are allowed.
- Put the user-facing planning document in `prd.md`.
- Add a `## 연관 문서` section at the bottom of `prd.md` with links to `spec.md`, `plan.md`, and `context.md`.
- Create `spec.md`, `plan.md`, and `context.md` if they do not exist.
- If those related files already exist, do not overwrite them while refreshing `prd.md`.
- For second or later planning proposals, create a separate `specs/[feature-slug]/` folder for that proposal.
- When asked which planning file will be used for implementation, answer with the selected `prd.md` path and the related specs bundle paths.

Developer document structure:

- spec.md: Source of Truth for implementation. Include Goal, Non-Goals,
  Requirements, Acceptance Criteria in Given/When/Then form, and Open Questions.
- plan.md: 3-5 small, feature-oriented implementation phases. Each phase must
  include a concrete goal, checklist items, and a `Verification` line that says
  how the phase is proven. Avoid broad catch-all phases such as
  "Remaining Behavior" when requirements can be split by user-visible behavior.
  Keep Phase 0 as planning-only and state that code must not be written before
  user approval.
- context.md: Current Status plus Decision Log, Verification Log, and Next
  Step. Record dates, decisions, test results, skipped verification, and
  remaining risks here.

## Container Preview Discipline

When this project uses Container Preview, direct host smoke runs are allowed only temporarily.
Before returning the final `axstudio-config` marker or asking Studio/Docker to run the services, stop any host dev server you started for this same project.
The same project must not remain running once on the host and once in Docker on the same port.

## MCP Skill Routing

When the user asks to implement, build the initial app, continue from planning/design, or create the product:

1. Call `mcp__aplus-common__get_common_skill`.
2. Use:
   - skill_id: "project-template"
   - context: { "frontend_port": 30004, "backend_port": 40002, "plan_file": "AX_PROJECT_PLAN.md" }
   - Only include `design_file` / `design_content` when a design was explicitly selected or written.
3. Follow the returned instruction body.

When the user asks to run, start, analyze, fix, or connect the dev server / preview:

1. Call `mcp__aplus-common__get_common_skill`.
2. Use:
   - skill_id: "project-analyze"
   - context: { "frontend_port": 30004, "backend_port": 40002 }
3. Follow the returned instruction body.

If the MCP tool is unavailable, continue with this file as the fallback instruction.
If the MCP call stalls or fails during implementation startup, do not wait indefinitely.
Read this file as the fallback instruction and continue building the project.

## Managed Script Automations

For scheduled collection, batch processing, or an externally triggered script, use the Happy `script_automations` MCP tool. Call `{request:{operation:"list"}}` first, write and validate a self-contained Node .js/.mjs bundle in this project, then call upsert with a stable registrationKey, expectedRevision, sourcePath, name, and schedule. The tool encrypts the bundle and returns the same ID shown in Execution → Automations. File edits take effect only after another upsert.

Use schedule=null for registration-only or API-only work; externalEnabled enables API-key admission. Supported schedules are at (UTC epoch milliseconds), interval (at least 15 minutes), daily and weekly (IANA timezone, hour/minute; weekly days 0=Sunday). For example: schedule={kind:"daily",hour:9,minute:0,timezone:"Asia/Seoul",enabled:true}. set_enabled controls the whole automation; disabling schedule.enabled only stops scheduled runs. run requires JSON input and a stable idempotencyKey; list_runs shows durable queue/results, and runId requests that run's log. A queued response is not execution success.

Use allowedOrigins for explicit HTTP(S) network destinations and secretRefs such as {DB_TOKEN:"env:<mountedGroupId>:TOKEN"}. Never copy PocketBase superuser files or host credentials into a bundle. PocketBase collection credentials and frontend display are optional, project-specific choices. API keys are managed by a person in the same admin and are not returned by this agent tool. If the capability or verified project context is unavailable, report that prerequisite; do not substitute OS cron or a hidden setInterval.

## Work Type Selection

When the user has not explicitly said they are a developer, treat the user as non-developer by default.
Do not ask non-developers to choose internals such as MongoDB vs PocketBase, FastAPI vs hooks, or HTML vs backend structure.
Use plain product/user language by default instead of specialized development jargon.
If the user asks a technical or developer-level question, answer at that technical level.
Use AskUserQuestion for necessary clarification questions, but do not create a first-request purpose-selection step.

If the request is project-building and the user did not explicitly request a different structure, use React + PocketBase by default:

- `frontend/`: Vite + React + TypeScript.
- `backend/pocketbase`: PocketBase runtime, migrations, hooks, static output, and app-local startup.
- `backend/packages/domain` and `backend/packages/contracts`: testable domain logic and contracts.

Document/analysis/marketing artifact requests should not scaffold a code app by default.
If the user explicitly asks for no persistence, single-file/static HTML, email templates, embeddable snippets, or an artifact that must open without a dev server, honor that request instead of applying the React + PocketBase default.
Use the existing FastAPI full template or a hybrid only when the requirements need a separate backend, custom APIs, LLM proxy, secret handling, complex server workflows, billing, scheduled jobs, or explicit external DB integration.

Use vanilla `index.html` / CSS / JS only when the user explicitly asks for single-file/static HTML, email templates, embeddable snippets, or an artifact that must open without a dev server.

## Document Output Directory

User-facing final document artifacts such as PDF, DOCX, PPTX, XLSX, and TXT must be stored under the project-root `documents/` directory.

- Run `mkdir -p documents` before generating a final document when the directory does not exist.
- Do not place final document artifacts in the project root or `specs/`.
- Record development progress in the existing relevant `specs/` documents unless the user explicitly requests another location.
- Keep planning and development Markdown bundles under `specs/`; they are not final downloadable document artifacts.
- Report the final `documents/...` path in the `axstudio-work-complete` marker.

## Database Defaulting

- If the app is generated from the default React + PocketBase structure, use PocketBase(SQLite).
- If the account is not in an organization and the app needs durable storage/auth/upload/CRUD, default to PocketBase(SQLite).
- If full template mode is selected and `MONGO_DB_URL` is missing, use PocketBase(SQLite) unless the requirements clearly need a separate backend.
- If `MONGO_DB_URL` or another explicit DB env exists, respect that external DB intent.
- If the user explicitly asks for MongoDB, PostgreSQL, Supabase, PocketBase, or no persistence, respect the user choice.

## Full Template Layout

Keep the existing full-stack shape when the product needs a real application backend, custom APIs, LLM proxy, secret handling, complex server workflows, billing, scheduled jobs, or explicit external DB integration:

- `frontend/`: Next.js 15 App Router + TypeScript + shadcn/ui + Tailwind.
- `backend/`: FastAPI + uv + pydantic v2.
- `frontend/README.md` and `backend/README.md`: directory contract, commands, naming rules.
- Root `Dockerfile` and `docker-compose.yml`: reproducible app runtime artifacts.

Next.js is the frontend shell only for the Full Template Layout. Do not apply the Next.js default to PocketBase light mode.

Do not generate both FastAPI and PocketBase by default just because PocketBase is selected. Add FastAPI only when requirements need a separate application backend. A hybrid is allowed when FastAPI is needed and PocketBase is the persistence/auth/admin service behind repository adapters.

## PocketBase Light / TDD Layout

For PocketBase-backed projects that do not need a separate FastAPI backend, prefer:

```text
frontend
backend/pocketbase/pb_hooks/routes
backend/pocketbase/pb_hooks/adapters
backend/pocketbase/pb_migrations
backend/pocketbase/pb_public
backend/pocketbase/pb_data
backend/pocketbase/test_pb_data
backend/packages/domain
backend/packages/contracts
backend/tests/e2e
```

`frontend/`: Vite + React + TypeScript. This is the same frontend directory used by frontend-only light apps, so adding PocketBase later keeps the existing frontend and adds `backend/` beside it. Do not scaffold Next.js for PocketBase light mode unless the user explicitly asks for Next.js or the requirements need the Full Template Layout.

PocketBase hooks are adapters: `pb_hooks` should contain request routing and PocketBase adapter code only. Business logic belongs in `backend/packages/domain`; DTO/schema/contracts belong in `backend/packages/contracts`.

Keep TDD fast by testing domain and contracts with normal Vitest unit tests. Use a real PocketBase process only for e2e tests around migrations, auth rules, hooks, and adapter wiring. Build TypeScript shared logic to JavaScript before importing it from PocketBase hooks; do not expect PocketBase to execute TypeScript directly.

Do not include `*.test.*` or `*.spec.*` files in the production TypeScript build. If the frontend `tsconfig.json` includes sibling source such as `../backend/packages/domain/src`, remember that exclude paths are relative to that tsconfig file: add explicit sibling-relative excludes or use a separate `tsconfig.build.json`. Do not add Vitest/Jest as a production dependency just to make the build pass.

If an existing project already uses `frontend/` + `backend/` and PocketBase is only the selected persistence/auth service, do not force a monorepo migration. Keep domain/contracts inside the existing backend ownership boundary and put PocketBase-specific code under `backend/pocketbase` and backend adapters.

## Frontend Work Classification (Critical)

- Apply TDD to frontend business logic extracted into custom hooks.
- Apply TDD to repeated shared utility logic.
- For style, copy, layout, simple display, and local UI interaction changes, do not add new tests by default.
- Do not add tests that assert DOM child order, CSS class names, or pixel placement for UI-only changes.
- Run affected existing tests for regression, regardless of whether new tests are added.
- Add UI tests only for accessibility contracts or actual user-facing behavior defects.
- This frontend scope takes precedence over the general TDD rules.

## File Placement And Reuse

- Declare before editing: State how many files you will modify and create, plus a one-sentence reason for each new file, then continue. Decide placement yourself; do not ask the user or wait for approval. If you cannot state the reason in one sentence, do not create the file; keep the code in an existing file.
- Search before creating: Search for an existing equivalent before adding a utility, hook, or type. Do not assume none exists without searching.
- Scope ladder: local function in the same file, then `frontend/src/features/{name}/_utils` and `_hooks`, then `frontend/src/lib`, then `backend/packages/domain` and `contracts`. The only condition for moving one step up is a real second consumer. Possible future reuse is not a promotion reason. Move code back down or delete it when its last consumer is gone.
- Do not import another feature's internal files. Needing that import is the signal to promote the code to `frontend/src/lib`.
- Split on responsibility, not size: if you cannot describe what a file does in one sentence, it has two responsibilities. Line count is a review signal, not a mandatory split trigger. The primary reason to split is testability, not reuse.
- Share on the third duplication: copying is fine through the second occurrence. Do not merge code just because it looks alike; ask whether a requirement change must change all copies together, and leave them alone if the answer is no. When you do share it, replace every existing call site instead of leaving old copies beside the new shared function.

## PocketBase Runtime Details

- Create deterministic collection schema migrations under `pb_migrations/`.
- Use `pb_public/` for static build output when serving through PocketBase.
- Frontend code should use the PocketBase SDK or same-origin REST paths such as `/api/collections/{collection}/records`.
- Do not treat generic custom APIs like `/api/tasks` as PocketBase built-ins. Add an explicit `pb_hooks` route or use PocketBase collection APIs.
- If `pb_hooks` requires a generated file (for example an esbuild CommonJS bundle of a TypeScript domain package), expose the generation step as the backend package `build` script — not only inside the dev/start script. Deploy runs `pocketbase serve` directly, so a step hidden in the start script never runs, the required file is missing, and every route that requires it fails at request time.
- Do not use `/api/health` as the app's own health route. PocketBase answers `/api/health` itself even when no `pb_hooks` route loaded, so it cannot prove the app is alive. Add an app-owned route such as `/api/status` that reports real readiness.
- Preserve A+ preview path prefixes such as `/preview-proxy/{port}/` and `/v1/preview/{machineId}/{port}/` when creating PocketBase SDK base URLs.
- On preview subdomains, use same-origin PocketBase URLs through the frontend proxy. Never fall back to a browser-side `http://localhost:<backend_port>` URL: that points to the visitor’s computer. If the frontend reads a custom base-URL environment variable, include it in the runtime configuration or use the current origin by default.
- Mirror PocketBase auth tokens to `X-PocketBase-Authorization` when a Node/Express proxy or preview relay may consume the normal `Authorization` header.
- Never commit or deploy `pb_data/`; it is runtime SQLite data.
- Never commit or deploy `.aplus-pocketbase-superuser.csv`; A+ Studio stores generated local/deploy superuser credentials there for the user.
- PocketBase light templates must not assume a random global `pocketbase` command or machine-level binary exists on PATH. A verified `/usr/local/bin/pocketbase` from the A+ Preview base image may be used first as the app-local cache bootstrap source. Generate `backend/pocketbase/package.json` and an app-local `backend/pocketbase/scripts/pocketbase-dev.mjs`; the startup script executes only `backend/pocketbase/.bin/pocketbase` so the downloaded project remains independently runnable.
- The startup script may reuse an existing `backend/pocketbase/.bin/pocketbase` only after `backend/pocketbase/.bin/pocketbase --version` succeeds. If verification fails, delete the cached file before reinstalling.
- The startup script should next verify `/usr/local/bin/pocketbase --version`; if it succeeds, copy that binary into `backend/pocketbase/.bin/pocketbase`, chmod it, verify the copied binary with `--version`, and skip release zip download/extraction.
- App-local install must download the OS/arch-specific PocketBase binary (v0.39.x) into a temp dir, verify HTTP status and a non-empty archive, extract the zip, verify the extracted `pocketbase` exists, apply `chmod +x`, and move it into `backend/pocketbase/.bin/pocketbase` only after `--version` succeeds. On verification failure, delete bad temp/cache files and retry once; never leave a corrupted binary cached.
- Add `extract-zip` to `backend/pocketbase/package.json` dependencies and use it from the app-local startup script to unpack PocketBase release zips. Validate it with `node -e "import('extract-zip')"`; directory existence is not enough because stale Preview volumes can leave an empty dependency directory. If the import fails, remove the stale `node_modules/extract-zip`, run `npm install --no-audit --no-fund` inside `backend/pocketbase`, and verify the import again before extracting. Do not shell out to `unzip`; it is not guaranteed in host or Preview containers. Do not import `tar`; PocketBase release artifacts are zip files, and a root-level script cannot resolve dependencies installed under `backend/pocketbase/node_modules`. Node 24 Preview can leave an `extract-zip promise` unresolved after the extracted `pocketbase` file appears, so guard extraction with a short file-existence timeout and either continue to binary verification or fail with a clear bootstrap error.
- Put `npm run dev -- --http 0.0.0.0:<backend_port>` in `axstudio-config.services[*].devCommand`. Keep binary bootstrap, superuser upsert, and `serve` inside the npm script; do not put `curl`, `&&`, pipes, or redirects directly in `devCommand`.
- Parse both `--http 0.0.0.0:<backend_port>` and `--http=0.0.0.0:<backend_port>` in `backend/pocketbase/scripts/pocketbase-dev.mjs`. Never pass the literal string `--http` as the listen address; if no value is provided, default to `0.0.0.0:<PORT>` when `process.env.PORT` or `process.env.APLUS_HTTP_PORT` is set, and only otherwise to `127.0.0.1:8090`. The deploy fallback path starts the app with a bare `npm start` that passes no `--http`, so a hardcoded loopback default makes the container unreachable from the proxy even though the process is running.
- Always pass `--publicDir=<absolute path to backend/pocketbase/pb_public>` alongside `--dir` when spawning `serve` in `backend/pocketbase/scripts/pocketbase-dev.mjs`. PocketBase resolves the default `--publicDir` relative to the executable, not the cwd (`backend/pocketbase/.bin/pb_public`), so without this flag `/` returns 404 while only `/api/*` answers 200, even though the build wrote the static output into `pb_public`. Compute it as an absolute path from the script location, the same way as `--dir`.
- For local PocketBase startup scripts, read the generated superuser email/password from `.aplus-pocketbase-superuser.csv` or `APLUS_POCKETBASE_SUPERUSER_EMAIL` / `APLUS_POCKETBASE_SUPERUSER_PASSWORD`, then run `superuser upsert "$APLUS_POCKETBASE_SUPERUSER_EMAIL" "$APLUS_POCKETBASE_SUPERUSER_PASSWORD" --dir=./pb_data` with the local binary before `serve` only when both values are present and the email is syntactically valid. If credentials are missing or the email is invalid, print a warning and skip `superuser upsert`; still start `serve`. Never use a project id, session id, username, or random slug as the email fallback.
- Never place superuser passwords, API keys, private tokens, or production secrets in migrations or seed data.
- PocketBase runtime is v0.23+ / v0.39.x. Do not use `Dao`, `new Collection({ schema: [...] })`, `saveCollection`, or `deleteCollection`; those are old v0.22 migration APIs and will fail on deploy.
- Do not use `BaseCollection`, `TextField`, or `BoolField` unless you have verified the bindings in the target PocketBase binary; prefer `app.importCollections([...], false)` for generated schema migrations.

Use callback `app` and a collection snapshot in migrations:

```js
migrate((app) => {
  app.importCollections([
    {
      id: "pbc_todos000001",
      name: "todos",
      type: "base",
      fields: [
        { id: "text_todo_title", name: "title", type: "text", required: true, min: 1, max: 500 },
        { id: "bool_todo_done", name: "done", type: "bool", required: false },
        { id: "autodate_todo_created", name: "created", type: "autodate", onCreate: true, onUpdate: false },
        { id: "autodate_todo_updated", name: "updated", type: "autodate", onCreate: true, onUpdate: true },
      ],
      indexes: [],
      listRule: "",
      viewRule: "",
      createRule: "",
      updateRule: "",
      deleteRule: "",
    },
  ], false)
}, (app) => {
  const collection = app.findCollectionByNameOrId("todos")
  app.delete(collection)
})
```

## Domain Boundary For Future DB Refactors

These rules apply to pure domain and DB-independent contracts, not to preview/runtime code.

`backend/packages/domain` and DB-independent parts of `backend/packages/contracts` must not depend on:

- PocketBase globals such as `$app`, `Record`, `routerAdd`, request info, collection APIs, or PocketBase record shapes.
- MongoDB `_id`, `ObjectId`, aggregation pipelines, or update operators.
- PostgreSQL raw SQL, query clients, transaction clients, or row-shape details.
- HTTP request/response objects, env vars, filesystem access, network calls, process ports, or runtime side effects.

Adapters, migrations, runtime bootstrap, preview wiring, PocketBase hooks, and e2e tests may use those APIs internally where appropriate. Map DB-specific data into domain types at the adapter boundary, for example PocketBase/MongoDB/PostgreSQL IDs into `id: string`.

Repository contracts should document pagination, uniqueness, not-found, transaction/concurrency behavior, and stable domain errors. Do not silently assume PocketBase, MongoDB, and PostgreSQL have the same transaction semantics.

## Frontend Defaults

- Keep render-affecting state close to the components that actually use it; when it must live higher, let only the components that need it subscribe so unrelated parts of the screen do not re-render. Do not preemptively wrap code in `memo`, `useMemo`, or `useCallback` for performance problems you have not measured.
- Next.js is the frontend shell only for the Full Template Layout. Do not create `frontend/app/api/**` or `frontend/pages/api/**` for product/domain APIs.
- New Full Template Next.js scaffolds should use `"next": "^15"`, `"react": "^18"`, and `"react-dom": "^18"` in `frontend/package.json` unless the user explicitly requests another version or a version-specific failure is reproduced.
- If `frontend/app/globals.css` or `frontend/src/index.css` uses `@import "tailwindcss"`, include `"tailwindcss"` in `frontend/package.json` dependencies. For Vite, also include `"@tailwindcss/vite"` and wire `tailwindcss()` in `vite.config.ts`. If code uses shadcn/ui, TanStack Query, or Jotai, include the matching packages before install/build verification.
- For Docker/Container Preview, the final Next dev command must bind to `0.0.0.0`. Prefer `package.json` script `"dev": "next dev --hostname 0.0.0.0"`; if the script is plain `next dev`, include `--hostname 0.0.0.0 --port <frontend_port>` in the `axstudio-config` dev command.
- `axstudio.next.config.mjs` and `AXSTUDIO_INLINE_BEGIN` blocks are Studio Preview runtime-managed. If a build reports missing `./axstudio.next.config.mjs`, do not delete the import or simplify `next.config.*` to an empty object. Re-run Studio preview/project analysis to regenerate the sidecar, or for local-only smoke keep an equivalent `/api/*` rewrite and `turbopack.root = process.cwd()`.
- Generated Vite frontends must defend against Container Preview watcher exhaustion. Add `server.watch.ignored` entries for `**/node_modules/**`, `**/.git/**`, `**/dist/**`, `**/build/**`, `**/.next/**`, `**/.nuxt/**`, `**/.turbo/**`, `**/coverage/**`, `**/.cache/**`, `**/.parcel-cache/**`, `**/backend/pocketbase/node_modules/**`, `**/backend/pocketbase/pb_data/**`, and `**/backend/pocketbase/.bin/**`. Set `server.watch.usePolling` to `process.env.CHOKIDAR_USEPOLLING === '1'`, and set both `server.watch.interval` and `server.watch.binaryInterval` to `Number(process.env.CHOKIDAR_INTERVAL) || 2000`, while keeping HMR for `frontend/src/**`. This also prevents `EMFILE: too many open files` failures and keeps binary-file polling at the same low frequency.
- Vite + Tailwind v4 frontends must install `@tailwindcss/vite` and wire `tailwindcss()` in `vite.config.ts`; without that plugin, `@theme inline` can remain unprocessed and token utilities will not resolve.
- In FastAPI full template mode, the backend owns domain APIs. Put CRUD, LLM proxy, persistence, auth, and third-party secret calls in `backend/`.
- From frontend code, call backend through same-origin paths such as `/api/...`, or through `process.env.NEXT_PUBLIC_API_URL` / `process.env.NEXT_PUBLIC_BACKEND_URL` when a base URL is needed. This rule is about the request target; for how to issue the request, follow the React Query rules in this section.
- When the frontend uses React Query, the query cache owns server data. Do not call `fetch` inside `useEffect` and spread loading/error/data across separate `useState` values; use `useQuery` instead.
- Put every value that determines the response into the `queryKey` (for example resource name, id, filters, page), and build key strings in one place instead of scattering them across call sites. Do not copy server data into local state; after a successful mutation, invalidate the related keys rather than hand-updating state. This does not apply to projects that do not use React Query.
- Server Components may fetch backend data for HTML rendering, but in FastAPI full template mode they should call the backend service; they should not replace backend routes with Next.js route handlers.
- For client mutation UI in React 19 / Next.js App Router, do not rely on `<form onSubmit>` by default. For modal, drawer, table action, and settings-save flows that should not navigate, prefer a container plus `<button type="button" onClick={...}>`. Use `<form>` only for intentional HTML submit, Server Actions, or progressive enhancement. If you use `<form onSubmit>`, verify `event.preventDefault()` and confirm no full page reload. Every non-submit button inside a form must declare `type="button"`.
- Keep design tokens in `frontend/app/globals.css` and `frontend/lib/design-tokens.ts`.
- Do not inline raw colors, font names, or spacing values in components when a token or Tailwind utility exists.
- Import the stylesheet from the app entry: Next.js uses `frontend/app/layout.tsx` with `import "./globals.css"`; Vite uses `frontend/src/main.tsx` with `import "./index.css"`.
- For Tailwind v4, connect shadcn tokens through `@theme inline` after `@import "tailwindcss";`. At minimum bridge `--color-background`, `--color-foreground`, `--color-primary`, `--color-primary-foreground`, `--color-border`, `--color-input`, `--color-ring`, `--radius-sm`, `--radius-md`, `--radius-lg`, and `--radius-xl` to real `:root` variables. Without this bridge, classes such as `bg-primary`, `border-border`, `ring-ring`, and `rounded-md` do not reflect the design tokens.
- Do not redefine Tailwind built-in scale names such as `--spacing-lg`, `--container-*`, `--breakpoint-*`, or `--text-*`.
- Do not generate dynamic Tailwind classes such as `bg-${color}`, `rounded-${radius}`, or `p-${space}`; Tailwind cannot scan them. Use static class maps or explicit arbitrary values such as `p-[var(--app-space-md)]`.
- Add one smoke surface that renders `bg-primary`, `text-primary-foreground`, `border-border`, `border-input`, `ring-ring`, and `rounded-md`; after build/dev compile, verify the browser computed styles reflect the selected design tokens.

## Backend Defaults

- In FastAPI full template mode, the backend owns domain APIs and is the only place for API secrets, database writes, and integrations that must not run in the browser.
- Use explicit API contracts and pydantic v2 request/response models.
- Choose database/cache dependencies from the actual requirements. Do not add unused infrastructure.
- Prefer httpOnly cookie sessions unless the user explicitly asks for bearer-token auth.

## A+ Studio Runtime Contract

- The final implementation response should include an `axstudio-config` marker with the actual services, directories, dev commands, and ports.
- Every service must include `name`, `dir`, `kind`, `framework`, `devCommand`, and `port`. Set `kind` to `frontend` for the web UI, `backend` for APIs/PocketBase, or `electron-gui` for desktop GUI previews. A name such as `web` or `api` does not replace `kind`; omitting it can prevent Studio from selecting the preview service.
- Use the assigned frontend/backend ports when present. Do not silently switch to another port.
- The Studio runtime owns the final preview start. After emitting `axstudio-config`, let the current Preview runtime toggle decide the execution path.
- In Container Preview, do not start and stop a manual dev server just for smoke testing. The Studio should run the saved `devCommand` inside the Preview container; verify that container-started service instead.
- Next.js frontend dev commands must expose the server with `--hostname 0.0.0.0` so the preview container port is reachable from the Studio preview panel.
- `devCommand` must be one shell command without pipes, redirects, `&&`, `;`, backticks, or `$()`.
- The agent owns the server verification loop. After writing `axstudio-config`, wait for the Studio Preview runtime to start the saved services, inspect service logs/status, distinguish first-failure service from secondary `ECONNREFUSED` proxy symptoms, fix the cause, restart, and repeat until frontend listen, backend listen, API health, and requested CRUD smoke all pass.
- After smoke checks pass, leave the Studio-managed preview services running so the user can open the live preview. Do not stop, kill, or tear down the preview server after verification unless the user explicitly asks to stop it.
