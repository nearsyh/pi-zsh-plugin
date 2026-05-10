# Plugin-Scoped Session Management Implementation Plan

**Goal:** Add Forge-style `:` prefix new/continue flows to `pi.plugin.zsh` without changing or accidentally resuming normal pi sessions.

**Architecture:** Keep pi's native JSONL session files as the durable conversation store, but make the zsh plugin maintain its own metadata index under a plugin-owned directory. Every plugin-created session is launched with a plugin-owned `--session-dir`, so `:continue` only resumes sessions started through this plugin. Store per-working-directory metadata (`last_session_id`, `last_session_file`, timestamps) under `${PI_ZSH_PLUGIN_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/pi-zsh-plugin}`. Do not use `pi -c` for plugin continuation because `-c` means pi's global/latest session and may touch normal pi sessions. Delay tree/fork/clone/export/copy until after the core lifecycle is stable.

**Final Completion Criteria:** `:new`, `: <prompt>`, `:continue`, and `:continue-interactive` use only plugin-owned sessions; normal `pi` sessions outside the plugin are never resumed by plugin commands; README documents the isolation model; `zsh -n pi.plugin.zsh` passes.

---

## Updated Decisions From User Feedback

1. **Plugin sessions must be isolated from normal pi sessions.**
   - The plugin must not call `pi -c` for continuation.
   - The plugin must not use pi's default `~/.pi/agent/sessions` lookup for `:` commands.
   - The plugin can still use pi's session format, but should pass `--session-dir <plugin-dir>`.

2. **Scope is intentionally small for the first implementation.**
   - Implement new session and continue only.
   - Delay tree, fork, clone, export, copy, rename, compact, and session picker.

3. **Add explicit interactive continuation.**
   - Add `:continue-interactive` (alias candidates: `:ci`, maybe `:i`) to open the plugin's last session in pi's TUI.
   - Keep prompt continuation non-interactive/one-shot where possible.

## Research Summary

### Forge zsh plugin behavior worth copying

Forge's implementation is under `/tmp/pi-github-repos/tailcallhq/forgecode/shell-plugin/`:

- `lib/config.zsh` defines hidden shell state:
  - `_FORGE_CONVERSATION_ID`
  - `_FORGE_PREVIOUS_CONVERSATION_ID`
  - `_FORGE_ACTIVE_AGENT`
- `lib/dispatcher.zsh` intercepts buffers matching `^:` in a ZLE widget and routes commands by name.
- `lib/actions/core.zsh` starts a fresh conversation, clears current conversation, and tracks previous conversation.
- Forge auto-creates a conversation ID on first prompt, then sends every prompt with an explicit conversation id.

The key idea to keep: **the shell plugin tracks the active conversation explicitly instead of relying on global latest-session semantics**.

### Pi session primitives available

From installed pi docs and `pi --help`:

- `pi "prompt"` starts a new interactive session with an initial prompt.
- `pi -p "prompt"` runs non-interactive mode and saves a session unless `--no-session` is used.
- `pi --session <path|id> [prompt]` uses a specific session file or partial UUID.
- `pi --session-dir <dir>` overrides session storage and lookup.
- `pi -c [prompt]` continues pi's most recent session. **Do not use this in plugin continuation**, because it can resume normal pi sessions.
- Sessions are JSONL files. The first line header includes session UUID `id`, timestamp, and cwd.

## Isolation Model

Use two plugin-owned storage concepts:

```text
${PI_ZSH_PLUGIN_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/pi-zsh-plugin}/
  metadata/
    <cwd-key>.zsh        # last session metadata for one working directory
  sessions/
    <cwd-key>/           # passed to pi as --session-dir
      <pi-created>.jsonl
```

### Why a separate `--session-dir` is preferable

It is better than only storing metadata that points into normal pi's session directory because:

- `pi -r` or normal `pi -c` will not see plugin sessions unless the user explicitly points pi at this dir.
- `:continue` cannot accidentally pick up a normal pi session.
- Plugin cleanup is simple: remove the plugin state directory.
- The plugin's meaning of "last session for this folder" is deterministic.

### Directory key

Use a stable filesystem-safe key derived from `$PWD`.

Recommended initial implementation:

```zsh
local cwd_key="${PWD//\//-}"
cwd_key="${cwd_key#:}"
```

A hash would be more collision-resistant, but plain encoded path is inspectable and aligns with pi's own path encoding. If desired later, use `python3 -c '...'` or `shasum` to generate a hash.

### Metadata file format

Use a zsh-sourceable metadata file because this is a zsh plugin and values are controlled by the plugin.

Example:

```zsh
PI_ZSH_LAST_SESSION_ID='650e8400-e29b-41d4-a716-446655440000'
PI_ZSH_LAST_SESSION_FILE='/Users/me/.local/state/pi-zsh-plugin/sessions/-Users-me-project/2026-05-09T...jsonl'
PI_ZSH_LAST_UPDATED='2026-05-09T12:34:56Z'
PI_ZSH_CWD='/Users/me/project'
```

Important: quote values safely with zsh `${(qqq)value}` when writing.

## Command Surface For First Version

| Command | Behavior |
| --- | --- |
| `: <prompt>` | Continue plugin session for current `$PWD`; if none exists, create a new plugin session with this prompt. |
| `:something` | Shorthand for `: something`, same as above. |
| `:` | Continue last plugin session for current `$PWD` interactively. If none exists, start a new interactive plugin session. |
| `:new [prompt]`, `:n [prompt]` | Start a fresh plugin session for current `$PWD`, save it as the folder's last plugin session. |
| `:continue [prompt]`, `:c [prompt]` | Continue last plugin session for current `$PWD`; with prompt, send prompt to that session; without prompt, open interactively. If none exists, print a helpful error or start new depending on chosen policy. |
| `:continue-interactive`, `:ci` | Explicitly open last plugin session for current `$PWD` in pi TUI. If none exists, start a new interactive plugin session. |
| `:print <prompt>`, `:p <prompt>` | Non-interactive print mode against plugin session; if none exists, create plugin session. |

Recommended policy for missing session:

- `: <prompt>` creates a new plugin session automatically. This is convenient and keeps old behavior.
- `:continue <prompt>` should also create a new plugin session if missing, because it is equivalent to normal prompt flow.
- `:continue` / `:continue-interactive` with no session can start a new interactive plugin session and persist it.
- Do **not** fall back to `pi -c`.

## File Structure

- Modify: `pi.plugin.zsh`
  - Add plugin state/session-dir helpers.
  - Add metadata read/write helpers.
  - Replace `pi -c` continuation with explicit `--session-dir` and `--session` logic.
  - Add `:continue-interactive` and `:ci`.
- Modify: `README.md`
  - Document plugin-scoped sessions and state directory.
  - Document command behavior and non-interference with normal pi sessions.

## Task 1: Add plugin-owned paths and binary helper

**Files:**
- Modify: `pi.plugin.zsh`

- [ ] **Step 1: Add configuration variables near top of file**

```zsh
typeset -h _PI_ZSH_BIN="${PI_ZSH_BIN:-pi}"
typeset -h _PI_ZSH_STATE_DIR="${PI_ZSH_PLUGIN_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/pi-zsh-plugin}"
```

- [ ] **Step 2: Add `_pi_exec` helper**

```zsh
function _pi_exec() {
  "$_PI_ZSH_BIN" "$@"
}
```

- [ ] **Step 3: Add state directory helpers**

```zsh
function _pi_zsh_cwd_key() {
  local key="${PWD//\//-}"
  key="${key#-}"
  [[ -z "$key" ]] && key="root"
  print -- "$key"
}

function _pi_zsh_metadata_file() {
  print -- "$_PI_ZSH_STATE_DIR/metadata/$(_pi_zsh_cwd_key).zsh"
}

function _pi_zsh_session_dir() {
  print -- "$_PI_ZSH_STATE_DIR/sessions/$(_pi_zsh_cwd_key)"
}

function _pi_zsh_ensure_dirs() {
  mkdir -p "$_PI_ZSH_STATE_DIR/metadata" "$(_pi_zsh_session_dir)"
}
```

- [ ] **Step 4: Syntax check**

Run:

```bash
zsh -n pi.plugin.zsh
```

Expected: no output, exit 0.

## Task 2: Add metadata read/write helpers

**Files:**
- Modify: `pi.plugin.zsh`

- [ ] **Step 1: Add `_pi_zsh_load_metadata`**

Avoid leaking loaded values globally except hidden plugin variables.

```zsh
typeset -h _PI_ZSH_LAST_SESSION_ID=""
typeset -h _PI_ZSH_LAST_SESSION_FILE=""

function _pi_zsh_load_metadata() {
  _PI_ZSH_LAST_SESSION_ID=""
  _PI_ZSH_LAST_SESSION_FILE=""

  local metadata="$(_pi_zsh_metadata_file)"
  [[ -f "$metadata" ]] || return 0

  local PI_ZSH_LAST_SESSION_ID=""
  local PI_ZSH_LAST_SESSION_FILE=""
  local PI_ZSH_LAST_UPDATED=""
  local PI_ZSH_CWD=""
  source "$metadata"

  _PI_ZSH_LAST_SESSION_ID="$PI_ZSH_LAST_SESSION_ID"
  _PI_ZSH_LAST_SESSION_FILE="$PI_ZSH_LAST_SESSION_FILE"
}
```

- [ ] **Step 2: Add `_pi_zsh_save_metadata`**

```zsh
function _pi_zsh_save_metadata() {
  local session_id="$1"
  local session_file="$2"
  local metadata="$(_pi_zsh_metadata_file)"

  _pi_zsh_ensure_dirs

  {
    print -- "PI_ZSH_LAST_SESSION_ID=${(qqq)session_id}"
    print -- "PI_ZSH_LAST_SESSION_FILE=${(qqq)session_file}"
    print -- "PI_ZSH_LAST_UPDATED=${(qqq)$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
    print -- "PI_ZSH_CWD=${(qqq)PWD}"
  } > "$metadata"

  _PI_ZSH_LAST_SESSION_ID="$session_id"
  _PI_ZSH_LAST_SESSION_FILE="$session_file"
}
```

- [ ] **Step 3: Add `_pi_zsh_latest_session_file`**

```zsh
function _pi_zsh_latest_session_file() {
  local dir="$(_pi_zsh_session_dir)"
  local -a files
  files=("$dir"/*.jsonl(N.om[1]))
  [[ ${#files[@]} -gt 0 ]] && print -- "$files[1]"
}
```

- [ ] **Step 4: Add `_pi_zsh_session_id_from_file`**

Prefer header parsing over filename assumptions.

```zsh
function _pi_zsh_session_id_from_file() {
  local file="$1"
  [[ -f "$file" ]] || return 1

  python3 - "$file" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    header = json.loads(f.readline())
print(header.get("id", ""))
PY
}
```

- [ ] **Step 5: Add `_pi_zsh_refresh_last_session`**

Call this after any pi command that may create a session.

```zsh
function _pi_zsh_refresh_last_session() {
  local latest="$(_pi_zsh_latest_session_file)"
  [[ -n "$latest" ]] || return 0

  local session_id="$(_pi_zsh_session_id_from_file "$latest")"
  [[ -n "$session_id" ]] || return 0

  _pi_zsh_save_metadata "$session_id" "$latest"
}
```

- [ ] **Step 6: Syntax check**

Run `zsh -n pi.plugin.zsh`.

## Task 3: Implement plugin-scoped new and continue actions

**Files:**
- Modify: `pi.plugin.zsh`

- [ ] **Step 1: Add `_pi_zsh_run_new`**

```zsh
function _pi_zsh_run_new() {
  local prompt="$1"
  _pi_zsh_ensure_dirs

  if [[ -n "$prompt" ]]; then
    _pi_exec --session-dir "$(_pi_zsh_session_dir)" "$prompt"
  else
    _pi_exec --session-dir "$(_pi_zsh_session_dir)"
  fi

  _pi_zsh_refresh_last_session
}
```

- [ ] **Step 2: Add `_pi_zsh_run_continue`**

```zsh
function _pi_zsh_run_continue() {
  local prompt="$1"
  _pi_zsh_ensure_dirs
  _pi_zsh_load_metadata

  if [[ -z "$_PI_ZSH_LAST_SESSION_ID" ]]; then
    _pi_zsh_run_new "$prompt"
    return $?
  fi

  if [[ -n "$prompt" ]]; then
    _pi_exec --session-dir "$(_pi_zsh_session_dir)" --session "$_PI_ZSH_LAST_SESSION_ID" "$prompt"
  else
    _pi_exec --session-dir "$(_pi_zsh_session_dir)" --session "$_PI_ZSH_LAST_SESSION_ID"
  fi

  _pi_zsh_refresh_last_session
}
```

- [ ] **Step 3: Add `_pi_zsh_run_print`**

```zsh
function _pi_zsh_run_print() {
  local prompt="$1"

  if [[ -z "$prompt" ]]; then
    echo "Usage: :print <prompt>" >&2
    return 0
  fi

  _pi_zsh_ensure_dirs
  _pi_zsh_load_metadata

  if [[ -n "$_PI_ZSH_LAST_SESSION_ID" ]]; then
    _pi_exec --session-dir "$(_pi_zsh_session_dir)" --session "$_PI_ZSH_LAST_SESSION_ID" -p "$prompt"
  else
    _pi_exec --session-dir "$(_pi_zsh_session_dir)" -p "$prompt"
  fi

  _pi_zsh_refresh_last_session
}
```

- [ ] **Step 4: Replace old direct invocations**

Replace:

```zsh
pi -c "..."
pi -c
pi "..."
pi
pi -c -p "..."
```

with the new helper functions.

- [ ] **Step 5: Syntax check**

Run `zsh -n pi.plugin.zsh`.

## Task 4: Add `:continue-interactive`

**Files:**
- Modify: `pi.plugin.zsh`
- Modify: `README.md`

- [ ] **Step 1: Implement `_pi_zsh_run_continue_interactive`**

This is intentionally explicit and equivalent to continue with no prompt.

```zsh
function _pi_zsh_run_continue_interactive() {
  _pi_zsh_run_continue ""
}
```

- [ ] **Step 2: Wire dispatcher aliases**

Recognize:

```zsh
continue-interactive|ci
```

Behavior:

```zsh
_pi_zsh_run_continue_interactive
```

- [ ] **Step 3: Decide whether `:` alone maps to this**

Recommended: yes.

```zsh
elif [[ -z "$input" ]]; then
  _pi_zsh_run_continue_interactive
```

This keeps the current documented `:` behavior but isolates it to plugin sessions.

- [ ] **Step 4: Syntax check**

Run `zsh -n pi.plugin.zsh`.

## Task 5: Update command parsing carefully

**Files:**
- Modify: `pi.plugin.zsh`

Current parser handles:

- `: <prompt>`
- `:n [prompt]`
- `:c [prompt]`
- `:p <prompt>`
- `:`
- fallback `:something` as prompt

Update cases to:

```zsh
if [[ "$input" =~ "^[[:space:]]+(.*)$" ]]; then
  _pi_zsh_run_continue "${match[1]}"
elif [[ "$input" =~ "^(n|new)([[:space:]]+(.*))?$" ]]; then
  _pi_zsh_run_new "${match[3]}"
elif [[ "$input" =~ "^(c|continue)([[:space:]]+(.*))?$" ]]; then
  _pi_zsh_run_continue "${match[3]}"
elif [[ "$input" =~ "^(ci|continue-interactive)$" ]]; then
  _pi_zsh_run_continue_interactive
elif [[ "$input" =~ "^(p|print)[[:space:]]+(.*)$" ]]; then
  _pi_zsh_run_print "${match[2]}"
elif [[ -z "$input" ]]; then
  _pi_zsh_run_continue_interactive
else
  _pi_zsh_run_continue "$input"
fi
```

Important: no branch should call `pi -c`.

## Task 6: README update

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update feature list**

Add:

```markdown
- Keeps plugin sessions isolated from normal `pi` sessions by using a plugin-owned session directory.
- Tracks the last plugin session separately for each working directory.
```

- [ ] **Step 2: Update command table**

```markdown
| Command | Action |
| --- | --- |
| `: <prompt>` | Continue the current folder's plugin session, creating one if needed |
| `:` | Open the current folder's plugin session interactively, creating one if needed |
| `:n <prompt>` | Start a new plugin session with the given prompt |
| `:n` | Start a fresh interactive plugin session |
| `:c <prompt>` | Continue the current folder's plugin session with a prompt |
| `:c` | Open the current folder's plugin session interactively |
| `:ci`, `:continue-interactive` | Explicitly open the current folder's plugin session interactively |
| `:p <prompt>` | Non-interactive print against the current folder's plugin session |
| `:something` | Shorthand for `: something` |
```

- [ ] **Step 3: Add isolation section**

```markdown
## Session Isolation

This plugin does not use `pi -c` for continuation. It stores plugin sessions under:

`${PI_ZSH_PLUGIN_STATE_DIR:-${XDG_STATE_HOME:-~/.local/state}/pi-zsh-plugin}`

Each working directory gets its own plugin session directory and metadata file. Normal `pi` sessions remain separate; running `pi`, `pi -c`, or `pi -r` outside the plugin will use pi's normal session storage.
```

- [ ] **Step 4: Document environment variables**

```markdown
- `PI_ZSH_BIN`: pi executable to run. Defaults to `pi`.
- `PI_ZSH_PLUGIN_STATE_DIR`: plugin state/session directory. Defaults to `${XDG_STATE_HOME:-~/.local/state}/pi-zsh-plugin`.
```

## Task 7: Validation

**Files:**
- Verify: `pi.plugin.zsh`
- Verify: `README.md`

- [ ] **Step 1: Syntax check**

```bash
zsh -n pi.plugin.zsh
```

Expected: exit 0.

- [ ] **Step 2: Non-interactive source check**

```bash
zsh -f -c 'source ./pi.plugin.zsh'
```

If this fails because ZLE widgets require interactive mode, add a guard:

```zsh
if [[ -o interactive ]]; then
  zle -N pi-accept-line
  bindkey '^M' pi-accept-line
  bindkey '^J' pi-accept-line
fi
```

- [ ] **Step 3: Manual isolated session smoke test**

Use a temporary state dir to avoid touching real state:

```zsh
export PI_ZSH_PLUGIN_STATE_DIR=/tmp/pi-zsh-plugin-test
source ./pi.plugin.zsh
:n say only PLUGIN_NEW
: what did I ask you to say?
:ci
```

Expected:

- Files appear under `/tmp/pi-zsh-plugin-test/sessions/<cwd-key>/`.
- Metadata appears under `/tmp/pi-zsh-plugin-test/metadata/<cwd-key>.zsh`.
- No command uses `pi -c`.

- [ ] **Step 4: Confirm normal pi isolation**

```zsh
pi -c
```

Expected: resumes normal pi latest session, not necessarily the plugin session. This confirms separation.

## Delayed Features

Do not implement in this pass:

- `:tree`
- `:fork`
- `:clone`
- `:copy`
- `:export`
- `:compact`
- `:rename`
- session picker

Add them only after the plugin-owned session lifecycle is stable. Future versions can use the same `--session-dir "$(_pi_zsh_session_dir)"` isolation model for those commands.
