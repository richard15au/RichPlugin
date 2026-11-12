# RichPlugin

Small TypeScript test project (Vitest + ESLint) used to try out Claude Code workflows.

## Scripts

- `npm run typecheck` – type-check with `tsc`
- `npm run lint` – lint with ESLint
- `npm test` – run the Vitest suite

## Install (recommended: works locally and in the cloud)
Run inside the project, then commit and push:

**Windows (PowerShell)** (untested: try it on a scratch repo first)
```powershell
irm https://raw.githubusercontent.com/richard15au/RichPlugin/main/install.ps1 | iex
```
**Mac / Linux / WSL**
```bash
curl -fsSL https://raw.githubusercontent.com/richard15au/RichPlugin/main/install.sh | bash
```
This copies the plugin into `.claude/`, so every session (local or cloud) has `/run-spec` with nothing to install.
Re-run the same line to update. It never touches `.env`, your specs, your skills or your own settings.
