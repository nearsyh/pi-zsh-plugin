#!/usr/bin/env zsh

# Core utility functions for pi shell plugin.

function _pi_get_commands() {
    if [[ -z "$_PI_COMMANDS" ]]; then
        _PI_COMMANDS=$'new\ninfo\nsession\nresume\nmodel\ncopy\ncompact\nexport\nhelp\ncommit\ncommit-preview\nclone\nrename\nconversation-rename'
    fi
    echo "$_PI_COMMANDS"
}

function _pi_shell_ensure_session_file() {
    if [[ -n "$_PI_SHELL_SESSION_FILE" ]]; then
        return 0
    fi

    local session_dir="${PI_ZSH_SESSION_DIR:-${PI_CODING_AGENT_SESSION_DIR:-${HOME}/.pi/agent/shell-sessions}}"
    mkdir -p "$session_dir" || {
        _pi_log error "Failed to create session directory: $session_dir"
        return 1
    }

    local timestamp
    timestamp="$(date '+%Y%m%d-%H%M%S')"
    _PI_SHELL_SESSION_FILE="${session_dir}/${timestamp}-$$.jsonl"
    _PI_CONVERSATION_ID="$_PI_SHELL_SESSION_FILE"
}

function _pi_shell_set_session_file() {
    local session_file="$1"
    [[ -z "$session_file" ]] && return 1

    if [[ -n "$_PI_SHELL_SESSION_FILE" && "$_PI_SHELL_SESSION_FILE" != "$session_file" ]]; then
        _PI_SHELL_PREVIOUS_SESSION_FILE="$_PI_SHELL_SESSION_FILE"
        _PI_PREVIOUS_CONVERSATION_ID="$_PI_SHELL_SESSION_FILE"
    fi

    _PI_SHELL_SESSION_FILE="$session_file"
    _PI_CONVERSATION_ID="$session_file"
}

function _pi_shell_clear_session() {
    if [[ -n "$_PI_SHELL_SESSION_FILE" ]]; then
        _PI_SHELL_PREVIOUS_SESSION_FILE="$_PI_SHELL_SESSION_FILE"
        _PI_PREVIOUS_CONVERSATION_ID="$_PI_SHELL_SESSION_FILE"
    fi
    _PI_SHELL_SESSION_FILE=""
    _PI_CONVERSATION_ID=""
}

function _pi_shell_base_cmd() {
    reply=(${PI_ZSH_BIN:-pi})
    [[ -n "${_PI_SESSION_MODEL:-${PI_ZSH_MODEL:-}}" ]] && reply+=(--model "${_PI_SESSION_MODEL:-${PI_ZSH_MODEL:-}}")
}

function _pi_shell_print_cmd() {
    _pi_shell_ensure_session_file || return 1
    _pi_shell_base_cmd
    reply+=(--session "$_PI_SHELL_SESSION_FILE" -p)
}

function _pi_exec() {
    local -a cmd
    _pi_shell_base_cmd
    cmd=(${reply[@]})
    cmd+=("$@")
    "${cmd[@]}"
}

function _pi_exec_interactive() {
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

function _pi_shell_accept_original_line() {
    _PI_SHELL_ACCEPTED_LINE=1
    zle accept-line
}

function _pi_shell_prompt_with_history() {
    local prompt="$1"
    local history_context

    history_context="$(_pi_history_recent_context)"
    if [[ -z "$history_context" ]]; then
        REPLY="$prompt"
        return 0
    fi

    REPLY="${prompt}

<recent-zsh-commands>
${history_context}
</recent-zsh-commands>"
}

function _pi_shell_send_prompt() {
    local prompt="$1"
    local -a cmd
    _pi_shell_print_cmd || return 1
    cmd=(${reply[@]})
    cmd+=(--mode json)
    _pi_shell_prompt_with_history "$prompt"
    cmd+=("$REPLY")
    "${cmd[@]}" | python3 "${_PI_PLUGIN_DIR}/lib/pi-stream-render.py"
}

function _pi_shell_capture_text() {
    local prompt="$1"
    local -a cmd
    _pi_shell_print_cmd || return 1
    cmd=(${reply[@]})
    cmd+=(--mode json)
    _pi_shell_prompt_with_history "$prompt"
    cmd+=("$REPLY")
    "${cmd[@]}" | python3 "${_PI_PLUGIN_DIR}/lib/pi-stream-render.py" --text-only
}

function _pi_reset() {
  BUFFER=""
  CURSOR=0
  zle -I
  zle reset-prompt
}

function _pi_log() {
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

