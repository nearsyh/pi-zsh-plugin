#!/usr/bin/env zsh

# Enable prompt substitution for RPROMPT
setopt PROMPT_SUBST

# Returns ZSH-formatted string ready for use in RPROMPT
function _forge_prompt_info() {
    local model_part="${_FORGE_SESSION_MODEL:+ ${_FORGE_SESSION_MODEL}}"
    local session_part="${_PI_SHELL_SESSION_FILE:t}"
    [[ -n "$session_part" ]] && session_part=" ${session_part}"
    echo "%F{cyan}π%f%F{244}${model_part}${session_part}%f"
}

# Right prompt: pi session info
# Set RPROMPT if empty, otherwise append to existing value
if [[ -z "$_FORGE_THEME_LOADED" ]]; then
    RPROMPT='$(_forge_prompt_info)'"${RPROMPT:+ ${RPROMPT}}"
    _FORGE_THEME_LOADED=1
fi
