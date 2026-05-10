# Pi ZSH Plugin

ZSH helper plugin for `pi`. It maps `:` commands in your shell to `pi -p` calls and keeps a per-shell pi session file for continuity.

## Prerequisites

- `zsh`
- `pi` in `PATH`

## Load

```zsh
source /path/to/shell-plugin/pi.plugin.zsh
source /path/to/shell-plugin/pi.theme.zsh  # optional right prompt
```

## Usage

```zsh
: explain this repository
: new task in a fresh session
:new
:conversation
:model anthropic/claude-sonnet-4
:provider anthropic
:thinking high
:copy
:export session.html
```

Plain `: prompt` sends the prompt to `pi -p --session <session-file>`. The session file is created under `~/.pi/agent/shell-sessions` by default.

## Configuration

Set before loading the plugin:

```zsh
export PI_BIN="/path/to/pi"
export PI_MODEL="anthropic/claude-sonnet-4"
export PI_PROVIDER="anthropic"
export PI_THINKING="medium"
export PI_SHELL_SESSION_DIR="$HOME/.pi/agent/shell-sessions"
export PI_EDITOR="$EDITOR"
```

## Notes

- Agents map to normal pi prompts.
- Workspace sync is a no-op; pi reads context live from the current directory.
- `:suggest` asks pi to output a shell command.
- `:commit-preview` asks pi for a commit message and inserts a `git commit` command.
