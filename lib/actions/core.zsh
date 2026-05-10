#!/usr/bin/env zsh

# Core action handlers for basic pi operations

function _pi_action_new() {
    local input_text="$1"

    _pi_shell_clear_session
    if [[ -n "$input_text" ]]; then
        _pi_shell_send_prompt "$input_text"
    else
        echo
        _pi_log success "Started new pi session"
    fi
}

function _pi_action_info() {
    echo
    _pi_action_session
}

function _pi_action_session() {
    echo
    if [[ -n "$_PI_SHELL_SESSION_FILE" ]]; then
        _pi_log info "Session: $_PI_SHELL_SESSION_FILE"
    else
        _pi_log info "No active pi shell session"
    fi
}

function _pi_action_dump() {
    local output_file="$1"
    echo

    if [[ -z "$_PI_SHELL_SESSION_FILE" ]]; then
        _pi_log error "No active session. Start a session first."
        return 0
    fi

    if [[ -n "$output_file" ]]; then
        $_PI_SHELL_BIN --export "$_PI_SHELL_SESSION_FILE" "$output_file"
    else
        $_PI_SHELL_BIN --export "$_PI_SHELL_SESSION_FILE"
    fi
}

function _pi_action_compact() {
    _pi_handle_conversation_command "/compact"
}

function _pi_action_retry() {
    _pi_log warning "Retry is not supported by pi print mode"
}

function _pi_action_help() {
    echo
    $_PI_SHELL_BIN --help
}

function _pi_handle_conversation_command() {
    local command_text="$1"
    shift

    if [[ -z "$_PI_SHELL_SESSION_FILE" ]]; then
        echo
        _pi_log error "No active session. Start a session first."
        return 0
    fi

    _pi_shell_send_prompt "$command_text $*"
}
