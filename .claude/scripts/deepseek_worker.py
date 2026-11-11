#!/usr/bin/env python3
"""LITE DeepSeek worker (backup): one quick edit via a single API call, no tools.
Use deepseek_agent.sh for normal work; use this for tiny edits or if the agent runner breaks.

Runs one coding/doc subtask, applies its edits to disk, prints one summary line.

The worker reads files itself, so file contents never pass through Claude's context.
DeepSeek returns SEARCH/REPLACE blocks; each block must match the file exactly once,
and only files listed in --edit may be changed. Every edit is checked first; if any fails, nothing is written.

Exit codes: 0 = edits applied, 1 = API/config error, 2 = edits rejected (counts as a strike).

Example:
  python3 .claude/scripts/deepseek_worker.py \
    --task "Add a `published` boolean to Course and expose it in course.list" \
    --edit prisma/schema.prisma src/server/api/routers/course.ts \
    --read src/server/api/trpc.ts --skill minimal-code,stack-rules
"""
import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path

ROOT = Path(os.environ.get("WORKER_ROOT", ".")).resolve()
SKILLS_DIR = ROOT / ".claude/skills"
CORE = ROOT / ".claude/worker/core.md"
LOG_DIR = ROOT / ".claude/logs"
BASE_URL = os.environ.get("DEEPSEEK_BASE_URL", "https://api.deepseek.com").rstrip("/")
MODEL = os.environ.get("DEEPSEEK_MODEL", "deepseek-flash")
MAX_FILE_BYTES = 200_000
MAX_TOKENS = int(os.environ.get("DEEPSEEK_MAX_TOKENS", "32000"))

# Never sent to DeepSeek, never written by it.
SECRET = re.compile(
    r"(^|/)(\.env(\.[^/]*)?|[^/]*\.(pem|key|p12|pfx|crt)|id_(rsa|ed25519|ecdsa)[^/]*"
    r"|secrets?(/|$|\.)|credentials[^/]*|\.npmrc|\.pgpass)$|(^|/)\.git/",
    re.I,
)

FORMAT_RULES = """\
## Output format (mandatory)
Return ONLY edit blocks followed by one summary line. No prose, no code fences.
Each edit block:

path/relative/to/repo
<<<<<<< SEARCH
exact existing lines, copied character-for-character (include enough lines to be unique)
=======
replacement lines
>>>>>>> REPLACE

- To create a new file: leave SEARCH empty.
- One block per change; several blocks per file are fine, applied in order.
- Only touch files listed under "Editable files".
- Last line: SUMMARY: <one line, what changed and why>
- If the task cannot be done safely, output only: SUMMARY: BLOCKED <reason>
"""


def die(code, msg):
    print(f"FAIL {msg}")
    sys.exit(code)


def rel_path(p):
    path = (ROOT / p).resolve()
    if ROOT not in path.parents and path != ROOT:
        die(1, f"path outside repo: {p}")
    rel = path.relative_to(ROOT).as_posix()
    if SECRET.search(rel):
        die(1, f"refusing secret-like path: {rel}")
    return rel


def load_skills(names):
    parts = [CORE.read_text()]
    for name in names:
        f = SKILLS_DIR / name / "SKILL.md"
        if not f.exists():
            die(1, f"missing skill {f.relative_to(ROOT)}")
        parts.append(f.read_text())
    return "\n\n".join(parts)


def file_section(rel, editable):
    p = ROOT / rel
    if not p.exists():
        if editable:
            return f"### {rel}\n(new file, does not exist yet)\n"
        die(1, f"--read file not found: {rel}")
    if p.stat().st_size > MAX_FILE_BYTES:
        die(1, f"file too large to send: {rel}")
    return f"### {rel}\n{p.read_text()}\n### end {rel}\n"


def call_api(system, user):
    key = os.environ.get("DEEPSEEK_API_KEY")
    if not key:
        die(1, "DEEPSEEK_API_KEY not set")
    body = json.dumps({
        "model": MODEL,
        "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}],
        "temperature": 0,
        "max_tokens": MAX_TOKENS,
    }).encode()
    req = urllib.request.Request(
        f"{BASE_URL}/chat/completions", data=body,
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
    )
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=600) as r:
                data = json.load(r)
            return data["choices"][0]["message"]["content"], data.get("usage", {})
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503) and attempt < 2:
                time.sleep(5 * (attempt + 1))
                continue
            die(1, f"API HTTP {e.code}: {e.read()[:200].decode(errors='replace')}")
        except (urllib.error.URLError, TimeoutError) as e:
            if attempt < 2:
                time.sleep(5 * (attempt + 1))
                continue
            die(1, f"API unreachable: {e}")


def parse(text):
    """Return ([(path, search, replace)], summary)."""
    lines = [l for l in text.splitlines(keepends=True) if not l.strip().startswith("```")]
    edits, summary, i = [], "", 0
    while i < len(lines):
        line = lines[i].rstrip("\r\n")
        if line.startswith("SUMMARY:"):
            summary = line[len("SUMMARY:"):].strip()
        if line == "<<<<<<< SEARCH":
            path = lines[i - 1].strip() if i else ""
            j = i + 1
            while j < len(lines) and lines[j].rstrip("\r\n") != "=======":
                j += 1
            k = j + 1
            while k < len(lines) and lines[k].rstrip("\r\n") != ">>>>>>> REPLACE":
                k += 1
            if k >= len(lines):
                raise ValueError("unterminated edit block")
            edits.append((path, "".join(lines[i + 1:j]), "".join(lines[j + 1:k])))
            i = k
        i += 1
    return edits, summary


def apply(edits, editable, dry_run=False):
    """Validate every edit in memory first; write only if all succeed."""
    new = {}
    for path, search, replace in edits:
        rel = Path(path).as_posix()
        if rel not in editable:
            raise ValueError(f"edit to non-editable file: {rel}")
        p = ROOT / rel
        cur = new.get(rel, p.read_text() if p.exists() else None)
        if search == "":
            if cur:
                raise ValueError(f"{rel}: empty SEARCH on a non-empty file")
            cur = replace
        else:
            if cur is None:
                raise ValueError(f"{rel}: file does not exist")
            n = cur.count(search)
            if n != 1:
                raise ValueError(f"{rel}: SEARCH matched {n} times (need exactly 1)")
            cur = cur.replace(search, replace, 1)
        new[rel] = cur
    if not dry_run:
        for rel, text in new.items():
            (ROOT / rel).parent.mkdir(parents=True, exist_ok=True)
            (ROOT / rel).write_text(text)
    return sorted(new)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--task", required=True, help="what to do (or @path to read the task from a file)")
    ap.add_argument("--edit", nargs="+", required=True, help="files the worker may modify or create")
    ap.add_argument("--read", nargs="*", default=[], help="read-only context files")
    ap.add_argument("--skill", default="", help="comma list of .claude/skills/<name> (worker/core.md always loaded)")
    ap.add_argument("--dry-run", action="store_true", help="validate edits without writing")
    ap.add_argument("--response-file", help="replay a saved response instead of calling the API")
    a = ap.parse_args()

    task = (ROOT / a.task[1:]).read_text() if a.task.startswith("@") else a.task
    editable = {rel_path(p) for p in a.edit}
    readable = [rel_path(p) for p in a.read]
    skills = [s.strip() for s in a.skill.split(",") if s.strip()]

    system = load_skills(skills) + "\n\n" + FORMAT_RULES
    user = (f"# Task\n{task}\n\n# Editable files\n" + "".join(file_section(r, True) for r in sorted(editable))
            + ("\n# Read-only context\n" + "".join(file_section(r, False) for r in readable) if readable else ""))

    if a.response_file:
        text, usage = Path(a.response_file).read_text(), {}
    else:
        text, usage = call_api(system, user)
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        log = LOG_DIR / f"{datetime.now():%Y%m%d-%H%M%S}-{os.getpid()}.md"
        log.write_text(f"# Task\n{task}\n\n# Response\n{text}\n")

    try:
        edits, summary = parse(text)
        if summary.startswith("BLOCKED"):
            die(2, summary)
        if not edits:
            raise ValueError("no edit blocks in response")
        changed = apply(edits, editable, a.dry_run)
    except ValueError as e:
        die(2, str(e))

    tok = f"{usage.get('prompt_tokens', '?')}/{usage.get('completion_tokens', '?')}" if usage else "replay"
    print(f"OK{' (dry-run)' if a.dry_run else ''} files={','.join(changed)} tokens={tok} | {summary or 'no summary'}")


if __name__ == "__main__":
    main()
