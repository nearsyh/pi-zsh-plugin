#!/usr/bin/env zsh

# TODO: Update prompt content after plugin-scoped session metadata lands.
# Enable prompt substitution for RPROMPT
setopt PROMPT_SUBST

# Returns ZSH-formatted string ready for use in RPROMPT
function _pi_prompt_info() {
    local _model="${_PI_SESSION_MODEL:-${PI_ZSH_MODEL:-}}"
    local model_part="${_model:+ ${_model}}"
    local session_part="${_PI_SHELL_SESSION_FILE:t}"
    [[ -n "$session_part" ]] && session_part=" ${session_part}"
    echo "%F{cyan}π%f%F{244}${model_part}${session_part}%f"
}

# Right prompt: pi session info
# Set RPROMPT if empty, otherwise append to existing value
if [[ -z "$_PI_THEME_LOADED" ]]; then
    RPROMPT='$(_pi_prompt_info)'"${RPROMPT:+ ${RPROMPT}}"
    _PI_THEME_LOADED=1
fi
