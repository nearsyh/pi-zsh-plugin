#!/usr/bin/env zsh

# Configuration action handlers for pi

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
