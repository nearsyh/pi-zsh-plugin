#!/usr/bin/env zsh

# Main command dispatcher and widget registration for pi

function _forge_action_default() {
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

function forge-accept-line() {
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

    _forge_osc133_emit "B"
    _forge_osc133_emit "C"

    case "$user_action" in
        new|n)
            if [[ -n "$input_text" ]]; then
                _pi_shell_set_pending_action "$user_action" "$input_text"
                _pi_shell_accept_original_line
            else
                _forge_action_new "$input_text"
            fi
        ;;
        info|i|session)
            _forge_action_info
        ;;
        dump|d|export)
            _forge_action_dump "$input_text"
        ;;
        compact)
            _pi_shell_set_pending_action "$user_action" "$input_text"
            _pi_shell_accept_original_line
        ;;
        retry|r)
            _forge_action_retry
        ;;
        help)
            _forge_action_help
        ;;
        agent|a)
            _forge_action_agent "$input_text"
        ;;
        conversation|c|resume)
            _forge_action_conversation "$input_text"
        ;;
        config-model|cm|model|m)
            _forge_action_session_model "$input_text"
        ;;
        provider)
            _forge_action_session_provider "$input_text"
        ;;
        config-reload|cr|model-reset|mr)
            _forge_action_config_reload
        ;;
        reasoning-effort|re|thinking)
            _forge_action_reasoning_effort "$input_text"
        ;;
        config-reasoning-effort|cre)
            _forge_action_config_reasoning_effort "$input_text"
        ;;
        config-commit-model|ccm)
            _forge_action_commit_model "$input_text"
        ;;
        config-suggest-model|csm)
            _forge_action_suggest_model "$input_text"
        ;;
        tools|t)
            _forge_action_tools
        ;;
        config|env|e|settings)
            _forge_action_config
        ;;
        config-edit|ce)
            _forge_action_config_edit
        ;;
        skill)
            _forge_action_skill
        ;;
        edit|ed)
            _forge_action_editor "$input_text"
            local action_status=$?
            _forge_osc133_emit "D;$action_status"
            _forge_osc133_emit "A"
            return $action_status
        ;;
        commit)
            _forge_action_commit "$input_text"
        ;;
        commit-preview)
            _forge_action_commit_preview "$input_text"
            local action_status=$?
            _forge_osc133_emit "D;$action_status"
            _forge_osc133_emit "A"
            return $action_status
        ;;
        suggest|s)
            _forge_action_suggest "$input_text"
            local action_status=$?
            _forge_osc133_emit "D;$action_status"
            _forge_osc133_emit "A"
            return $action_status
        ;;
        clone)
            _forge_action_clone "$input_text"
        ;;
        rename|rn)
            _forge_action_rename "$input_text"
        ;;
        conversation-rename)
            _forge_action_conversation_rename "$input_text"
        ;;
        copy)
            _forge_action_copy
        ;;
        workspace-sync|sync|workspace-init|sync-init|workspace-status|sync-status|workspace-info|sync-info)
            _forge_action_sync
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
            _forge_action_default "$user_action" "$input_text"
        ;;
    esac

    local action_status=$?

    if [[ -n "$_PI_SHELL_ACCEPTED_LINE" ]]; then
        _PI_SHELL_ACCEPTED_LINE=""
        return $action_status
    fi

    print -s -- "$original_buffer"
    _forge_osc133_emit "D;$action_status"
    _forge_osc133_emit "A"

    _forge_reset
    return $action_status
}
