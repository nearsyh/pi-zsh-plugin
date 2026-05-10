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
            _pi_action_new "$input_text"
        ;;
        compact)
            _pi_action_compact
        ;;
        *)
            _pi_shell_run_prompt_action "$user_action" "$input_text"
        ;;
    esac
}

function _pi_shell_pending_precmd() {
    # Restore options that were temporarily disabled by
    # _pi_shell_accept_original_line to handle special characters.
    (( _PI_SHELL_RESTORE_NOMATCH )) && { _PI_SHELL_RESTORE_NOMATCH=0; setopt nomatch; }
    (( _PI_SHELL_RESTORE_BANGHIST )) && { _PI_SHELL_RESTORE_BANGHIST=0; setopt banghist; }

    [[ -z "$_PI_SHELL_PENDING_ACTION" && -z "$_PI_SHELL_PENDING_INPUT" ]] && return 0
    _pi_shell_dispatch_pending_action
}

precmd_functions=(_pi_shell_pending_precmd "${precmd_functions[@]}")
