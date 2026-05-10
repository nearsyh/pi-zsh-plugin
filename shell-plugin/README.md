# Pi ZSH Plugin

ZSH helper plugin for `pi`. It maps `:` commands in your shell to `pi -p` calls and keeps a per-shell pi session file for continuity.

## Prerequisites

- `zsh`
- `pi` in `PATH`

## Install

### Manual

```zsh
source /path/to/shell-plugin/pi.plugin.zsh
source /path/to/shell-plugin/pi.theme.zsh  # optional right prompt
```

### Oh My Zsh custom plugin

Clone or symlink this directory as `$ZSH_CUSTOM/plugins/pi-zsh`, then enable it:

```zsh
plugins=(... pi-zsh)
```

The Oh My Zsh entrypoint is `pi-zsh.plugin.zsh`.

## Usage

```zsh
: explain this repository
: new task in a fresh session
:new
:conversation
:model anthropic/claude-sonnet-4
:copy
:export session.html
:commit-preview
```

Plain `: prompt` sends the prompt to `pi -p --session <session-file>`. The session file is created under `~/.pi/agent/shell-sessions` by default.

## Configuration

Set before loading the plugin:

```zsh
export PI_BIN="/path/to/pi"
export PI_MODEL="anthropic/claude-sonnet-4"
export PI_SHELL_SESSION_DIR="$HOME/.pi/agent/shell-sessions"
```

## Notes

- `:model <model>` sets the model for subsequent plugin-driven pi calls in the current shell.
- `:commit-preview` asks pi for a commit message and inserts a `git commit` command.
- `pi.theme.zsh` and `lib/highlight.zsh` are intentionally kept but need updates after session management settles.
