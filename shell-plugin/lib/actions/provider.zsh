#!/usr/bin/env zsh

# Provider selection action handlers for pi

function _pi_action_session_provider() {
    local input_text="$1"
    echo

    if [[ -z "$input_text" ]]; then
        _pi_log info "Usage: :provider <provider-name>"
        return 0
    fi

    _PI_SESSION_PROVIDER="$input_text"
    _pi_log success "Provider set to \033[1m${input_text}\033[0m"
}
