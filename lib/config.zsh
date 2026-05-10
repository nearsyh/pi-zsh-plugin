#!/usr/bin/env zsh

# Configuration variables for pi shell plugin

typeset -h _PI_CONVERSATION_PATTERN=":"

typeset -h _PI_COMMANDS=""
typeset -h _PI_CONVERSATION_ID
typeset -h _PI_PREVIOUS_CONVERSATION_ID

typeset -h _PI_SESSION_MODEL=""

typeset -h _PI_SHELL_SESSION_FILE="${PI_SHELL_SESSION_FILE:-}"
typeset -h _PI_SHELL_PREVIOUS_SESSION_FILE=""

typeset -h _PI_SHELL_PENDING_ACTION=""
typeset -h _PI_SHELL_PENDING_INPUT=""


typeset -h _PI_HISTORY_PENDING_CMD=""
typeset -h _PI_HISTORY_PENDING_CWD=""
typeset -h _PI_HISTORY_PENDING_TS=""
typeset -ha _PI_HISTORY_COMMANDS=()
typeset -ha _PI_HISTORY_EXIT_CODES=()
typeset -ha _PI_HISTORY_CWDS=()
typeset -ha _PI_HISTORY_TIMESTAMPS=()

