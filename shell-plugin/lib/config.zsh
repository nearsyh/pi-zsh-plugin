#!/usr/bin/env zsh

# Configuration variables for pi shell plugin
# Keep the historic _FORGE_* names as compatibility aliases for existing code.

typeset -h _FORGE_BIN="${PI_BIN:-${FORGE_BIN:-pi}}"
typeset -h _FORGE_CONVERSATION_PATTERN=":"
typeset -h _FORGE_MAX_COMMIT_DIFF="${PI_MAX_COMMIT_DIFF:-${FORGE_MAX_COMMIT_DIFF:-100000}}"

typeset -h _FORGE_COMMANDS=""
typeset -h _FORGE_CONVERSATION_ID
typeset -h _FORGE_ACTIVE_AGENT="pi"
typeset -h _FORGE_PREVIOUS_CONVERSATION_ID

typeset -h _FORGE_SESSION_MODEL="${PI_MODEL:-}"
typeset -h _FORGE_SESSION_PROVIDER="${PI_PROVIDER:-}"
typeset -h _FORGE_SESSION_REASONING_EFFORT="${PI_THINKING:-}"

typeset -h _PI_SHELL_SESSION_FILE="${PI_SHELL_SESSION_FILE:-}"
typeset -h _PI_SHELL_PREVIOUS_SESSION_FILE=""
typeset -h _PI_SHELL_SESSION_DIR="${PI_SHELL_SESSION_DIR:-${PI_CODING_AGENT_SESSION_DIR:-${HOME}/.pi/agent/shell-sessions}}"

typeset -h _FORGE_TERM="${PI_TERM:-${FORGE_TERM:-true}}"
typeset -h _FORGE_TERM_MAX_COMMANDS="${PI_TERM_MAX_COMMANDS:-${FORGE_TERM_MAX_COMMANDS:-5}}"
typeset -h _FORGE_TERM_OSC133="${PI_TERM_OSC133:-${FORGE_TERM_OSC133:-auto}}"
typeset -ha _FORGE_TERM_COMMANDS=()
typeset -ha _FORGE_TERM_EXIT_CODES=()
typeset -ha _FORGE_TERM_TIMESTAMPS=()
