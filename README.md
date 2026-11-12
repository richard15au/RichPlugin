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

### Local, once for every project (user-level)
```bash
curl -fsSL https://raw.githubusercontent.com/richard15au/RichPlugin/main/install.sh | bash -s -- --user
```
Installs into `~/.claude` so `/run-spec` and `/agent-init` exist in every local project. Run `/agent-init` once per project for `stack.json`, the vault folders, `CLAUDE.md` rules and `.gitignore`. (Mac / Linux / WSL; the per-project installer above is what the cloud uses.)

### Cloud, one click
Paste this into the cloud environment's **setup script** field:
```bash
curl -fsSL https://raw.githubusercontent.com/richard15au/RichPlugin/main/cloud-setup.sh | bash
```
It installs the plugin into every cloned repo and the `claude` CLI, and runs `npm ci` where there is a `package.json`. Then set `DEEPSEEK_API_KEY` (and optionally `SLACK_WEBHOOK_URL`, `SLACK_NOTIFY_ON_STOP=1`) as environment variables, and allow `github.com`, `raw.githubusercontent.com`, `api.deepseek.com` and `hooks.slack.com` under Network access.
