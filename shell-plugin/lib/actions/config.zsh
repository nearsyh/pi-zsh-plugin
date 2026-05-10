#!/usr/bin/env zsh

# Configuration action handlers for pi

function _forge_action_agent() {
    local input_text="$1"
    echo

    if [[ -n "$input_text" && "$input_text" != "pi" ]]; then
        _forge_log warning "pi does not support Forge agents from the shell plugin; using pi"
    fi

    _FORGE_ACTIVE_AGENT="pi"
    _forge_log success "Active assistant set to pi"
}

function _forge_action_model() {
    local input_text="$1"
    echo

    if [[ -n "$input_text" ]]; then
        _FORGE_SESSION_MODEL="$input_text"
        _forge_log success "Model set to \033[1m${_FORGE_SESSION_MODEL}\033[0m"
        return 0
    fi

    $_FORGE_BIN --list-models
}

function _forge_action_commit_model() {
    _forge_action_model "$@"
}

function _forge_action_suggest_model() {
    _forge_action_model "$@"
}

function _forge_action_sync() {
    echo
    _forge_log info "pi has no workspace sync command; context is read live from the current directory"
}

function _forge_action_sync_init() {
    _forge_action_sync
}

function _forge_action_sync_status() {
    _forge_action_sync
}

function _forge_action_sync_info() {
    _forge_action_sync
}

function _forge_action_session_model() {
    _forge_action_model "$@"
}

function _forge_action_config_reload() {
    echo

    if [[ -z "$_FORGE_SESSION_MODEL" && -z "$_FORGE_SESSION_PROVIDER" && -z "$_FORGE_SESSION_REASONING_EFFORT" ]]; then
        _forge_log info "No session overrides active"
        return 0
    fi

    _FORGE_SESSION_MODEL=""
    _FORGE_SESSION_PROVIDER=""
    _FORGE_SESSION_REASONING_EFFORT=""

    _forge_log success "Session overrides cleared"
}

function _forge_action_reasoning_effort() {
    local input_text="$1"
    echo

    if [[ -z "$input_text" ]]; then
        _forge_log info "Usage: :reasoning-effort <off|minimal|low|medium|high|xhigh>"
        return 0
    fi

    _FORGE_SESSION_REASONING_EFFORT="$input_text"
    _forge_log success "Thinking level set to \033[1m${input_text}\033[0m"
}

function _forge_action_config_reasoning_effort() {
    _forge_action_reasoning_effort "$@"
}

function _forge_action_config() {
    echo
    $_FORGE_BIN config
}

function _forge_action_config_edit() {
    _forge_action_config
}

function _forge_action_tools() {
    echo
    $_FORGE_BIN --help | sed -n '/Built-in Tool Names:/,$p'
}

function _forge_action_skill() {
    echo
    _forge_log info "Use pi --skill <path> or pi config to manage skills"
}
