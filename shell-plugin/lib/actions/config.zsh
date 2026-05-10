#!/usr/bin/env zsh

# Configuration action handlers for pi

function _pi_action_agent() {
    local input_text="$1"
    echo

    if [[ -n "$input_text" && "$input_text" != "pi" ]]; then
        _pi_log warning "Agent selection is not supported by the pi shell plugin; using pi"
    fi

    _PI_ACTIVE_AGENT="pi"
    _pi_log success "Active assistant set to pi"
}

function _pi_action_model() {
    local input_text="$1"
    echo

    if [[ -n "$input_text" ]]; then
        _PI_SESSION_MODEL="$input_text"
        _pi_log success "Model set to \033[1m${_PI_SESSION_MODEL}\033[0m"
        return 0
    fi

    $_PI_SHELL_BIN --list-models
}

function _pi_action_commit_model() {
    _pi_action_model "$@"
}

function _pi_action_suggest_model() {
    _pi_action_model "$@"
}

function _pi_action_sync() {
    echo
    _pi_log info "pi has no workspace sync command; context is read live from the current directory"
}

function _pi_action_sync_init() {
    _pi_action_sync
}

function _pi_action_sync_status() {
    _pi_action_sync
}

function _pi_action_sync_info() {
    _pi_action_sync
}

function _pi_action_session_model() {
    _pi_action_model "$@"
}

function _pi_action_config_reload() {
    echo

    if [[ -z "$_PI_SESSION_MODEL" && -z "$_PI_SESSION_PROVIDER" && -z "$_PI_SESSION_REASONING_EFFORT" ]]; then
        _pi_log info "No session overrides active"
        return 0
    fi

    _PI_SESSION_MODEL=""
    _PI_SESSION_PROVIDER=""
    _PI_SESSION_REASONING_EFFORT=""

    _pi_log success "Session overrides cleared"
}

function _pi_action_reasoning_effort() {
    local input_text="$1"
    echo

    if [[ -z "$input_text" ]]; then
        _pi_log info "Usage: :reasoning-effort <off|minimal|low|medium|high|xhigh>"
        return 0
    fi

    _PI_SESSION_REASONING_EFFORT="$input_text"
    _pi_log success "Thinking level set to \033[1m${input_text}\033[0m"
}

function _pi_action_config_reasoning_effort() {
    _pi_action_reasoning_effort "$@"
}

function _pi_action_config() {
    echo
    $_PI_SHELL_BIN config
}

function _pi_action_config_edit() {
    _pi_action_config
}

function _pi_action_tools() {
    echo
    $_PI_SHELL_BIN --help | sed -n '/Built-in Tool Names:/,$p'
}

function _pi_action_skill() {
    echo
    _pi_log info "Use pi --skill <path> or pi config to manage skills"
}
