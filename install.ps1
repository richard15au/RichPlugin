# Install rich-plugin into the current git project's .claude/ folder.
# Usage: irm https://raw.githubusercontent.com/richard15au/RichPlugin/main/install.ps1 | iex
# Re-run to update. UNTESTED on Windows: try it on a scratch repo first.
$ErrorActionPreference = 'Stop'
$Src = if ($env:RICHPLUGIN_SRC) { $env:RICHPLUGIN_SRC } else { 'https://github.com/richard15au/RichPlugin.git' }
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$Root = (git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $Root) { throw 'FAIL not inside a git repository' }
Set-Location $Root

function Write-Lf($Path, $Text) {  # UTF-8 without BOM, LF endings
  $dir = Split-Path $Path -Parent
  if ($dir) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  [IO.File]::WriteAllText((Join-Path (Get-Location) $Path), ($Text -replace "`r`n", "`n"), $Utf8)
}
function Read-Lf($Path) { ([IO.File]::ReadAllText($Path)) -replace "`r`n", "`n" }
function Add-IfMissing($From, $To) {
  if (Test-Path $To) { "skip    $To (exists)" }
  else { Write-Lf $To (Read-Lf $From); "created $To" }
}
function Copy-Tree($From, $To) {  # copy a folder, converting text files to LF
  New-Item -ItemType Directory -Force -Path $To | Out-Null
  Get-ChildItem $From -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($From.Length).TrimStart('\', '/')
    $dest = Join-Path $To $rel
    New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
    if ($_.Extension -in '.sh', '.md', '.json', '.py', '.add') { [IO.File]::WriteAllText($dest, (Read-Lf $_.FullName), $Utf8) }
    else { Copy-Item $_.FullName $dest -Force }
  }
}

# 1. Download
$Tmp = Join-Path ([IO.Path]::GetTempPath()) ("richplugin-" + [guid]::NewGuid())
"download $Src"
git -c core.autocrlf=false -c core.eol=lf clone --quiet --depth 1 --branch main $Src "$Tmp/src" 2>$null
if ($LASTEXITCODE -ne 0) { git -c core.autocrlf=false -c core.eol=lf clone --quiet --depth 1 $Src "$Tmp/src" }
if ($LASTEXITCODE -ne 0) { throw 'FAIL could not download RichPlugin' }
$P = "$Tmp/src/plugins/rich-plugin"
if (-not (Test-Path $P)) { throw "FAIL plugins/rich-plugin not found in $Src" }

try {
  # 2. Plugin files (replaced)
  if (Test-Path .claude/rich-plugin) { Remove-Item .claude/rich-plugin -Recurse -Force }
  foreach ($d in 'scripts', 'roles', 'skills', 'templates') { Copy-Tree "$P/$d" ".claude/rich-plugin/$d" }
  Write-Lf '.claude/rich-plugin/worker-settings.json' (Read-Lf "$P/worker-settings.json")
  'updated .claude/rich-plugin/'

  # 3. Commands (replaced, paths rewritten)
  foreach ($c in 'agent-init', 'run-spec') {
    $t = (Read-Lf "$P/commands/$c.md").Replace('${CLAUDE_PLUGIN_ROOT}', '.claude/rich-plugin').Replace('/rich-plugin:', '/')
    Write-Lf ".claude/commands/$c.md" $t
  }
  'updated .claude/commands/{agent-init,run-spec}.md'

  # 4. Skills (only if missing)
  foreach ($s in 'minimal-code', 'obsidian-docs', 'size-rule', 'ui-design') {
    if (Test-Path ".claude/skills/$s") { "skip    .claude/skills/$s (exists)" }
    else { Copy-Tree "$P/skills/$s" ".claude/skills/$s"; "created .claude/skills/$s" }
  }

  # 5. Project setup (only if missing)
  $T = "$P/templates"
  Add-IfMissing "$T/stack.json" '.claude/stack.json'
  Add-IfMissing "$T/spec-template.md" 'vault/specs/_template.md'
  Add-IfMissing "$T/goal-template.md" 'vault/goals/_template.md'
  Add-IfMissing "$T/env.example" '.env.example'
  New-Item -ItemType Directory -Force -Path vault/changelog, vault/architecture | Out-Null

  # 6. CLAUDE.md (block appended once)
  $block = (Read-Lf "$T/CLAUDE.block.md").Replace('/rich-plugin:', '/')
  if (-not (Test-Path CLAUDE.md)) { Write-Lf 'CLAUDE.md' ("# Project rules`n`n$block"); 'created CLAUDE.md' }
  elseif (-not (Select-String -Path CLAUDE.md -Pattern 'rich-plugin:start' -Quiet)) {
    Write-Lf 'CLAUDE.md' ((Read-Lf CLAUDE.md).TrimEnd("`n") + "`n`n$block"); 'updated CLAUDE.md (added rich-plugin block)'
  } else { 'skip    CLAUDE.md (block already present)' }

  # 7. .gitignore
  $gi = if (Test-Path .gitignore) { Read-Lf .gitignore } else { '' }
  if ($gi -match 'rich-plugin ---') { 'skip    .gitignore (block already present)' }
  else { Write-Lf '.gitignore' ($gi.TrimEnd("`n") + "`n`n" + (Read-Lf "$T/gitignore.add")); 'updated .gitignore' }

  # 8. Slack notifier (replaced)
  Write-Lf '.claude/scripts/notify.sh' (Read-Lf "$P/scripts/notify.sh")
  'updated .claude/scripts/notify.sh'

  # 9. settings.json (merge)
  $sp = '.claude/settings.json'
  $cfg = [ordered]@{}
  $ok = $true
  if (Test-Path $sp) {
    try { $cfg = Get-Content $sp -Raw | ConvertFrom-Json -AsHashtable } catch { $ok = $false; "skip    $sp (not valid JSON; fix it and run again)" }
  }
  if ($ok) {
    $changed = @()
    if (-not $cfg.ContainsKey('permissions')) { $cfg['permissions'] = @{} }
    if (-not $cfg['permissions'].ContainsKey('allow')) { $cfg['permissions']['allow'] = @() }
    if (-not ($cfg['permissions']['allow'] | Where-Object { $_ -like '*deepseek_agent.sh*' })) {
      $cfg['permissions']['allow'] = @($cfg['permissions']['allow']) + 'Bash(*deepseek_agent.sh:*)'; $changed += 'runner permission'
    }
    if (-not $cfg.ContainsKey('hooks')) { $cfg['hooks'] = @{} }
    $cmd = 'bash "$CLAUDE_PROJECT_DIR/.claude/scripts/notify.sh"'
    foreach ($ev in 'Notification', 'Stop') {
      if (-not $cfg['hooks'].ContainsKey($ev)) { $cfg['hooks'][$ev] = @() }
      $has = $cfg['hooks'][$ev] | Where-Object { $_['hooks'] | Where-Object { $_['command'] -like '*notify.sh*' } }
      if (-not $has) {
        $cfg['hooks'][$ev] = @($cfg['hooks'][$ev]) + @{ hooks = @(@{ type = 'command'; command = $cmd }) }; $changed += "$ev hook"
      }
    }
    if ($cfg.ContainsKey('extraKnownMarketplaces') -and $cfg['extraKnownMarketplaces'].ContainsKey('richard-stack')) {
      $cfg['extraKnownMarketplaces'].Remove('richard-stack'); $changed += 'removed richard-stack marketplace'
      if ($cfg['extraKnownMarketplaces'].Count -eq 0) { $cfg.Remove('extraKnownMarketplaces') }
    }
    if ($cfg.ContainsKey('enabledPlugins') -and $cfg['enabledPlugins'].ContainsKey('rich-plugin@richard-stack')) {
      $cfg['enabledPlugins'].Remove('rich-plugin@richard-stack'); $changed += 'removed rich-plugin@richard-stack'
      if ($cfg['enabledPlugins'].Count -eq 0) { $cfg.Remove('enabledPlugins') }
    }
    if ($changed) { Write-Lf $sp (($cfg | ConvertTo-Json -Depth 20) + "`n"); "updated $sp ($($changed -join ', '))" }
    else { "skip    $sp (already set up)" }
  }

  # 10. .gitattributes
  $ga = if (Test-Path .gitattributes) { Read-Lf .gitattributes } else { '' }
  if ($ga -split "`n" -contains '*.sh text eol=lf') { 'skip    .gitattributes (already set)' }
  else { Write-Lf '.gitattributes' ($ga.TrimEnd("`n") + "`n*.sh text eol=lf`n").TrimStart("`n"); 'updated .gitattributes' }

  "done. Check .claude/stack.json, then: git add -A; git commit -m 'chore: install rich-plugin'; git push"
}
finally { Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue }
