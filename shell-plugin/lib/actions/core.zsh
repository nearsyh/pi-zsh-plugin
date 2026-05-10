#!/usr/bin/env zsh

# Core action handlers for basic pi operations

function _forge_action_new() {
    local input_text="$1"

    _pi_shell_clear_session
    _FORGE_ACTIVE_AGENT="pi"

    echo

    if [[ -n "$input_text" ]]; then
        _pi_shell_send_prompt "$input_text"
    else
        _forge_log success "Started new pi session"
    fi
}

function _forge_action_info() {
    echo
    _forge_action_session
}

function _forge_action_session() {
    echo
    if [[ -n "$_PI_SHELL_SESSION_FILE" ]]; then
        _forge_log info "Session: $_PI_SHELL_SESSION_FILE"
    else
        _forge_log info "No active pi shell session"
    fi
}

function _forge_action_dump() {
    local output_file="$1"
    echo

    if [[ -z "$_PI_SHELL_SESSION_FILE" ]]; then
        _forge_log error "No active session. Start a session first."
        return 0
    fi

    if [[ -n "$output_file" ]]; then
        $_FORGE_BIN --export "$_PI_SHELL_SESSION_FILE" "$output_file"
    else
        $_FORGE_BIN --export "$_PI_SHELL_SESSION_FILE"
    fi
}

function _forge_action_compact() {
    _forge_handle_conversation_command "/compact"
}

function _forge_action_retry() {
    _forge_log warning "Retry is not supported by pi print mode"
}

function _forge_action_help() {
    echo
    $_FORGE_BIN --help
}

function _forge_handle_conversation_command() {
    local command_text="$1"
    shift

    echo

    if [[ -z "$_PI_SHELL_SESSION_FILE" ]]; then
        _forge_log error "No active session. Start a session first."
        return 0
    fi

    _pi_shell_send_prompt "$command_text $*"
}
