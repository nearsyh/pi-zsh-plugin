#!/usr/bin/env zsh

# Session management action handlers for pi

function _pi_switch_conversation() {
    _pi_shell_set_session_file "$1"
}

function _pi_clear_conversation() {
    _pi_shell_clear_session
}

function _pi_action_conversation() {
    local input_text="$1"
    echo

    if [[ "$input_text" == "-" ]]; then
        if [[ -z "$_PI_SHELL_PREVIOUS_SESSION_FILE" ]]; then
            _pi_log error "No previous session tracked"
            return 0
        fi

        local current="$_PI_SHELL_SESSION_FILE"
        _PI_SHELL_SESSION_FILE="$_PI_SHELL_PREVIOUS_SESSION_FILE"
        _PI_SHELL_PREVIOUS_SESSION_FILE="$current"
        _PI_CONVERSATION_ID="$_PI_SHELL_SESSION_FILE"
        _PI_PREVIOUS_CONVERSATION_ID="$_PI_SHELL_PREVIOUS_SESSION_FILE"
        _pi_log success "Switched to session \033[1m${_PI_SHELL_SESSION_FILE}\033[0m"
        return 0
    fi

    if [[ -n "$input_text" ]]; then
        _pi_shell_set_session_file "$input_text"
        _pi_log success "Switched to session \033[1m${_PI_SHELL_SESSION_FILE}\033[0m"
        return 0
    fi

    if [[ -n "$_PI_SHELL_SESSION_FILE" ]]; then
        _pi_log info "Current session: $_PI_SHELL_SESSION_FILE"
    else
        _pi_log info "No active session"
    fi
    _pi_log info "Use :conversation <session-file-or-id> to switch"
}

function _pi_action_clone() {
    local input_text="$1"
    echo

    local source="${input_text:-$_PI_SHELL_SESSION_FILE}"
    if [[ -z "$source" ]]; then
        _pi_log error "No active session to clone"
        return 0
    fi

    local session_dir="${PI_ZSH_SESSION_DIR:-${PI_CODING_AGENT_SESSION_DIR:-${HOME}/.pi/agent/shell-sessions}}"
    mkdir -p "$session_dir" || return 1
    local target="${session_dir}/$(date '+%Y%m%d-%H%M%S')-clone-$$.jsonl"
    cp "$source" "$target" || {
        _pi_log error "Failed to clone session: $source"
        return 1
    }

    _pi_shell_set_session_file "$target"
    _pi_log success "Cloned and switched to session \033[1m${target}\033[0m"
}

function _pi_action_copy() {
    echo

    if [[ -z "$_PI_SHELL_SESSION_FILE" ]]; then
        _pi_log error "No active session"
        return 0
    fi

    local content
    content=$(${PI_ZSH_BIN:-pi} --export "$_PI_SHELL_SESSION_FILE" 2>/dev/null)

    if [[ -z "$content" ]]; then
        _pi_log error "No session content found"
        return 0
    fi

    if command -v pbcopy &>/dev/null; then
        echo -n "$content" | pbcopy
    elif command -v xclip &>/dev/null; then
        echo -n "$content" | xclip -selection clipboard
    elif command -v xsel &>/dev/null; then
        echo -n "$content" | xsel --clipboard --input
    else
        _pi_log error "No clipboard utility found (pbcopy, xclip, or xsel required)"
        return 0
    fi

    _pi_log success "Copied session export to clipboard"
}

function _pi_action_rename() {
    _pi_log warning "Rename is not supported for pi shell sessions"
}

function _pi_action_conversation_rename() {
    _pi_action_rename
}

function _pi_clone_and_switch() {
    _pi_action_clone "$@"
}
