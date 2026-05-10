#!/usr/bin/env zsh

# Run pending pi actions from precmd, after zsh has accepted the original ':' line.

function _pi_shell_set_pending_action() {
    _PI_SHELL_PENDING_ACTION="$1"
    _PI_SHELL_PENDING_INPUT="$2"
}

function _pi_shell_run_prompt_action() {
    local user_action="$1"
    local input_text="$2"

    if [[ -n "$user_action" ]]; then
        input_text="/${user_action}${input_text:+ ${input_text}}"
    fi

    [[ -z "$input_text" ]] && return 0
    _pi_shell_send_prompt "$input_text"
}

function _pi_shell_dispatch_pending_action() {
    local user_action="$_PI_SHELL_PENDING_ACTION"
    local input_text="$_PI_SHELL_PENDING_INPUT"

    _PI_SHELL_PENDING_ACTION=""
    _PI_SHELL_PENDING_INPUT=""

    case "$user_action" in
        new|n)
            _forge_action_new "$input_text"
        ;;
        compact)
            _forge_action_compact
        ;;
        provider-login|login)
            _forge_action_login "$input_text"
        ;;
        logout)
            _forge_action_logout "$input_text"
        ;;
        *)
            _pi_shell_run_prompt_action "$user_action" "$input_text"
        ;;
    esac
}

function _pi_shell_pending_precmd() {
    [[ -z "$_PI_SHELL_PENDING_ACTION" && -z "$_PI_SHELL_PENDING_INPUT" ]] && return 0
    _pi_shell_dispatch_pending_action
}

precmd_functions=(_pi_shell_pending_precmd "${precmd_functions[@]}")
