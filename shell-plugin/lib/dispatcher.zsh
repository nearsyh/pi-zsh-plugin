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

    _pi_osc133_emit "B"
    _pi_osc133_emit "C"

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
        agent|a)
            _pi_action_agent "$input_text"
        ;;
        conversation|c|resume)
            _pi_action_conversation "$input_text"
        ;;
        config-model|cm|model|m)
            _pi_action_session_model "$input_text"
        ;;
        provider)
            _pi_action_session_provider "$input_text"
        ;;
        config-reload|cr|model-reset|mr)
            _pi_action_config_reload
        ;;
        reasoning-effort|re|thinking)
            _pi_action_reasoning_effort "$input_text"
        ;;
        config-reasoning-effort|cre)
            _pi_action_config_reasoning_effort "$input_text"
        ;;
        config-commit-model|ccm)
            _pi_action_commit_model "$input_text"
        ;;
        config-suggest-model|csm)
            _pi_action_suggest_model "$input_text"
        ;;
        tools|t)
            _pi_action_tools
        ;;
        config|env|e|settings)
            _pi_action_config
        ;;
        config-edit|ce)
            _pi_action_config_edit
        ;;
        skill)
            _pi_action_skill
        ;;
        edit|ed)
            _pi_action_editor "$input_text"
            local action_status=$?
            _pi_osc133_emit "D;$action_status"
            _pi_osc133_emit "A"
            return $action_status
        ;;
        commit)
            _pi_action_commit "$input_text"
        ;;
        commit-preview)
            _pi_action_commit_preview "$input_text"
            local action_status=$?
            _pi_osc133_emit "D;$action_status"
            _pi_osc133_emit "A"
            return $action_status
        ;;
        suggest|s)
            _pi_action_suggest "$input_text"
            local action_status=$?
            _pi_osc133_emit "D;$action_status"
            _pi_osc133_emit "A"
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
        workspace-sync|sync|workspace-init|sync-init|workspace-status|sync-status|workspace-info|sync-info)
            _pi_action_sync
        ;;
        provider-login|login)
            _pi_shell_set_pending_action "$user_action" "$input_text"
            _pi_shell_accept_original_line
        ;;
        logout)
            _pi_shell_set_pending_action "$user_action" "$input_text"
            _pi_shell_accept_original_line
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
    _pi_osc133_emit "D;$action_status"
    _pi_osc133_emit "A"

    _pi_reset
    return $action_status
}
