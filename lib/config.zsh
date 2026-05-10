#!/usr/bin/env zsh

# Configuration variables for pi shell plugin

typeset -h _PI_SHELL_BIN="${PI_BIN:-pi}"
typeset -h _PI_CONVERSATION_PATTERN=":"
typeset -h _PI_MAX_COMMIT_DIFF="${PI_MAX_COMMIT_DIFF:-100000}"

typeset -h _PI_COMMANDS=""
typeset -h _PI_CONVERSATION_ID
typeset -h _PI_PREVIOUS_CONVERSATION_ID

typeset -h _PI_SESSION_MODEL="${PI_MODEL:-}"

typeset -h _PI_SHELL_SESSION_FILE="${PI_SHELL_SESSION_FILE:-}"
typeset -h _PI_SHELL_PREVIOUS_SESSION_FILE=""
typeset -h _PI_SHELL_SESSION_DIR="${PI_SHELL_SESSION_DIR:-${PI_CODING_AGENT_SESSION_DIR:-${HOME}/.pi/agent/shell-sessions}}"
typeset -h _PI_SHELL_PENDING_ACTION=""
typeset -h _PI_SHELL_PENDING_INPUT=""

