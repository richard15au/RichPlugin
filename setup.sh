#!/usr/bin/env bash
# Cloud environment setup script for claude.ai/code.
# Paste the body into the environment's setup script field (or call this file from it).
set -euo pipefail

# Pin RTK to a release tag so a bad upstream push can't break every session.
# Check https://github.com/rtk-ai/rtk/releases and bump deliberately.
RTK_VERSION="${RTK_VERSION:-v0.42.4}"

if ! command -v rtk >/dev/null 2>&1; then
  curl -fsSL "https://raw.githubusercontent.com/rtk-ai/rtk/refs/tags/${RTK_VERSION}/install.sh" | sh
fi
export PATH="$HOME/.local/bin:$PATH"

# Installs the Claude Code Bash hook. (--auto-patch isn't in RTK's docs, so it's left out.)
rtk init -g
rtk gain >/dev/null || { echo "wrong rtk installed (Rust Type Kit?)"; exit 1; }

# Ponytail's hooks need node on PATH.
command -v node >/dev/null || echo "WARNING: node not on PATH — Ponytail hooks will stay quiet"

# App dependencies, so tests/typecheck work in the session.
if [ -f package.json ]; then npm ci --no-audit --no-fund; fi

# DeepSeek workers run inside the Claude Code CLI (headless).
command -v claude >/dev/null || npm install -g @anthropic-ai/claude-code
