# Node.js Domain Guide

## Project Structure Patterns
- `src/` or `lib/` — source code
- `test/` or `__tests__/` — test files
- `package.json` — dependencies and scripts
- `tsconfig.json` — TypeScript configuration (if applicable)
- `.env` / `.env.example` — environment variables (never commit .env)
- `dist/` or `build/` — compiled output (gitignored)

## Build and Test Commands

**npm:**
- Install: `npm install`
- Build: `npm run build`
- Test: `npm test`
- Lint: `npm run lint`
- Dev: `npm run dev`

**yarn:**
- Install: `yarn`
- Build: `yarn build`
- Test: `yarn test`

**pnpm:**
- Install: `pnpm install`
- Build: `pnpm build`
- Test: `pnpm test`

**Bun:**
- Install: `bun install`
- Build: `bun run build`
- Test: `bun test`

## Common Step Patterns

- **Dependency step**: `npm install <package>` then verify in package.json
- **Build verification**: Run build, check for TypeScript errors (exit code 0)
- **Test step**: Run test suite, parse output for failures
- **Lint step**: Run linter before commit, auto-fix where possible
- **Config step**: When adding env vars, update .env.example too

## Recommended allowed-tools

```yaml
allowed-tools:
  - Bash(npm:*)      # or yarn/pnpm/bun
  - Bash(npx:*)
  - Bash(node:*)
  - Read
  - Edit
  - Write
  - Grep
  - Glob
```

## Common Pitfalls

- Lock file mismatch: use the package manager matching the existing lock file (package-lock.json → npm, yarn.lock → yarn)
- Node version matters: check `.nvmrc` or `engines` in package.json
- ESM vs CommonJS: check `"type": "module"` in package.json
- Never commit `node_modules/` or `.env`
- Monorepo awareness: check for workspaces in package.json or lerna.json
