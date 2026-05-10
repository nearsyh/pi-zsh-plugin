#!/usr/bin/env zsh

# Provider selection action handlers for pi

function _forge_action_session_provider() {
    local input_text="$1"
    echo

    if [[ -z "$input_text" ]]; then
        _forge_log info "Usage: :provider <provider-name>"
        return 0
    fi

    _FORGE_SESSION_PROVIDER="$input_text"
    _forge_log success "Provider set to \033[1m${input_text}\033[0m"
}
