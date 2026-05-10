#!/usr/bin/env zsh

# Main command dispatcher and widget registration for pi

function _pi_action_default() {
    local user_action="$1"
    local input_text="$2"

    if [[ -n "$user_action" ]]; then
        input_text="/${user_action}${input_text:+ ${input_text}}"
    fi

    if [[ -z "$input_text" ]]; then
        return 0
    fi

    _pi_shell_set_pending_action "$user_action" "$input_text"
    _pi_shell_accept_original_line
}

function pi-accept-line() {
    local original_buffer="$BUFFER"
    local user_action=""
    local input_text=""

    if [[ "$BUFFER" =~ "^:([a-zA-Z][a-zA-Z0-9_-]*)( (.*))?$" ]]; then
        user_action="${match[1]}"
        if [[ -n "${match[2]}" ]]; then
            input_text="${match[3]}"
        else
            input_text=""
        fi
    elif [[ "$BUFFER" =~ "^: (.*)$" ]]; then
        user_action=""
        input_text="${match[1]}"
    else
        zle accept-line
        return
    fi

    case "$user_action" in
        ask|plan)
            user_action=""
        ;;
    esac

    case "$user_action" in
        new|n)
            if [[ -n "$input_text" ]]; then
                _pi_shell_set_pending_action "$user_action" "$input_text"
                _pi_shell_accept_original_line
            else
                _pi_action_new "$input_text"
            fi
        ;;
        info|i|session)
            _pi_action_info
        ;;
        dump|d|export)
            _pi_action_dump "$input_text"
        ;;
        compact)
            _pi_shell_set_pending_action "$user_action" "$input_text"
            _pi_shell_accept_original_line
        ;;
        retry|r)
            _pi_action_retry
        ;;
        help)
            _pi_action_help
        ;;
        conversation|c|resume)
            _pi_action_conversation "$input_text"
        ;;
        model|m)
            _pi_action_model "$input_text"
        ;;
        commit)
            _pi_action_commit "$input_text"
        ;;
        commit-preview)
            _pi_action_commit_preview "$input_text"
            local action_status=$?
            return $action_status
        ;;
        clone)
            _pi_action_clone "$input_text"
        ;;
        rename|rn)
            _pi_action_rename "$input_text"
        ;;
        conversation-rename)
            _pi_action_conversation_rename "$input_text"
        ;;
        copy)
            _pi_action_copy
        ;;
        *)
            _pi_action_default "$user_action" "$input_text"
        ;;
    esac

    local action_status=$?

    if [[ -n "$_PI_SHELL_ACCEPTED_LINE" ]]; then
        _PI_SHELL_ACCEPTED_LINE=""
        return $action_status
    fi

    print -s -- "$original_buffer"
    _pi_reset
    return $action_status
}
