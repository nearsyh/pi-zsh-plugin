#!/usr/bin/env zsh

# Core utility functions for pi shell plugin.
# Function names keep the old _forge_* prefix to minimise churn.

function _forge_get_commands() {
    if [[ -z "$_FORGE_COMMANDS" ]]; then
        _FORGE_COMMANDS=$'new\ninfo\nsession\nresume\nmodel\nscoped-models\nsettings\nlogin\nlogout\ncopy\ncompact\nexport\nhelp\nedit\nsuggest'
    fi
    echo "$_FORGE_COMMANDS"
}

function _pi_shell_ensure_session_file() {
    if [[ -n "$_PI_SHELL_SESSION_FILE" ]]; then
        return 0
    fi

    mkdir -p "$_PI_SHELL_SESSION_DIR" || {
        _forge_log error "Failed to create session directory: $_PI_SHELL_SESSION_DIR"
        return 1
    }

    local timestamp
    timestamp="$(date '+%Y%m%d-%H%M%S')"
    _PI_SHELL_SESSION_FILE="${_PI_SHELL_SESSION_DIR}/${timestamp}-$$.jsonl"
    _FORGE_CONVERSATION_ID="$_PI_SHELL_SESSION_FILE"
}

function _pi_shell_set_session_file() {
    local session_file="$1"
    [[ -z "$session_file" ]] && return 1

    if [[ -n "$_PI_SHELL_SESSION_FILE" && "$_PI_SHELL_SESSION_FILE" != "$session_file" ]]; then
        _PI_SHELL_PREVIOUS_SESSION_FILE="$_PI_SHELL_SESSION_FILE"
        _FORGE_PREVIOUS_CONVERSATION_ID="$_PI_SHELL_SESSION_FILE"
    fi

    _PI_SHELL_SESSION_FILE="$session_file"
    _FORGE_CONVERSATION_ID="$session_file"
}

function _pi_shell_clear_session() {
    if [[ -n "$_PI_SHELL_SESSION_FILE" ]]; then
        _PI_SHELL_PREVIOUS_SESSION_FILE="$_PI_SHELL_SESSION_FILE"
        _FORGE_PREVIOUS_CONVERSATION_ID="$_PI_SHELL_SESSION_FILE"
    fi
    _PI_SHELL_SESSION_FILE=""
    _FORGE_CONVERSATION_ID=""
}

function _pi_shell_base_cmd() {
    reply=($_FORGE_BIN)
    [[ -n "$_FORGE_SESSION_PROVIDER" ]] && reply+=(--provider "$_FORGE_SESSION_PROVIDER")
    [[ -n "$_FORGE_SESSION_MODEL" ]] && reply+=(--model "$_FORGE_SESSION_MODEL")
    [[ -n "$_FORGE_SESSION_REASONING_EFFORT" ]] && reply+=(--thinking "$_FORGE_SESSION_REASONING_EFFORT")
}

function _pi_shell_print_cmd() {
    _pi_shell_ensure_session_file || return 1
    _pi_shell_base_cmd
    reply+=(--session "$_PI_SHELL_SESSION_FILE" -p)
}

function _forge_exec() {
    local -a cmd
    _pi_shell_base_cmd
    cmd=(${reply[@]})
    cmd+=("$@")
    "${cmd[@]}"
}

function _forge_exec_interactive() {
    local -a cmd
    _pi_shell_print_cmd || return 1
    cmd=(${reply[@]})
    cmd+=("$@")
    "${cmd[@]}" </dev/tty >/dev/tty
}

function _pi_shell_command_line() {
    local -a cmd
    cmd=("$@")
    REPLY="${(j: :)${(@q)cmd}}"
}

function _pi_shell_accept_command() {
    _pi_shell_command_line "$@"
    BUFFER="$REPLY"
    CURSOR=${#BUFFER}
    _PI_SHELL_ACCEPTED_LINE=1
    zle accept-line
}

function _pi_shell_accept_prompt_as_command() {
    local prompt="$1"
    local -a cmd
    _pi_shell_print_cmd || return 1
    cmd=(${reply[@]})
    cmd+=("$prompt")
    _pi_shell_accept_command "${cmd[@]}"
}

function _pi_shell_send_prompt() {
    local prompt="$1"
    local -a cmd
    _pi_shell_print_cmd || return 1
    cmd=(${reply[@]})
    cmd+=("$prompt")
    "${cmd[@]}"
}

function _forge_select() {
    case "$1" in
        command)
            _forge_get_commands
        ;;
        model)
            $_FORGE_BIN --list-models "${2:-}" 2>/dev/null
        ;;
        *)
            return 1
        ;;
    esac
}

function _forge_select_global() {
    _forge_select "$@"
}

function _forge_select_with_query() {
    local query="$1"
    shift

    case "$1" in
        command)
            _forge_get_commands | grep -i -- "$query" | head -n 1
        ;;
        model)
            $_FORGE_BIN --list-models "$query" 2>/dev/null | head -n 1
        ;;
        *)
            return 1
        ;;
    esac
}

function _forge_select_with_query_global() {
    _forge_select_with_query "$@"
}

function _forge_select_model_pair() {
    local result
    result=$(_forge_select_with_query "$1" model)

    if [[ -z "$result" ]]; then
        reply=()
        return 1
    fi

    reply=("${result%% *}")
    [[ ${#reply[@]} -ge 1 ]]
}

function _forge_select_model_pair_global() {
    _forge_select_model_pair "$@"
}

function _forge_reset() {
  BUFFER=""
  CURSOR=0
  zle -I
  zle reset-prompt
}

function _forge_log() {
    local level="$1"
    local message="$2"
    local timestamp="\033[90m[$(date '+%H:%M:%S')]\033[0m"

    case "$level" in
        error)
            echo "\033[31m⏺\033[0m ${timestamp} \033[31m${message}\033[0m"
            ;;
        info)
            echo "\033[37m⏺\033[0m ${timestamp} \033[37m${message}\033[0m"
            ;;
        success)
            echo "\033[33m⏺\033[0m ${timestamp} \033[37m${message}\033[0m"
            ;;
        warning)
            echo "\033[93m⚠️\033[0m ${timestamp} \033[93m${message}\033[0m"
            ;;
        debug)
            echo "\033[36m⏺\033[0m ${timestamp} \033[90m${message}\033[0m"
            ;;
        *)
            echo "${message}"
            ;;
    esac
}

function _forge_is_workspace_indexed() {
    return 1
}

function _forge_start_background_sync() {
    return 0
}

function _forge_start_background_update() {
    return 0
}
