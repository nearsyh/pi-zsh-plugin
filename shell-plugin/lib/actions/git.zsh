#!/usr/bin/env zsh

# Git integration action handlers for pi

function _forge_action_commit() {
    local additional_context="$1"
    local prompt="Write a concise git commit message for the current staged changes. Output only the commit message."
    [[ -n "$additional_context" ]] && prompt+=" Extra context: ${additional_context}"

    echo
    local commit_message
    commit_message=$(_pi_shell_send_prompt "$prompt")

    if [[ -n "$commit_message" ]]; then
        git commit -m "$commit_message"
    else
        _forge_log error "Failed to generate commit message"
    fi

    _forge_reset
}

function _forge_action_commit_preview() {
    local additional_context="$1"
    local prompt="Write a concise git commit message for the current changes. Output only the commit message."
    [[ -n "$additional_context" ]] && prompt+=" Extra context: ${additional_context}"

    echo
    local commit_message
    commit_message=$(_pi_shell_send_prompt "$prompt")

    if [[ -n "$commit_message" ]]; then
        if git diff --staged --quiet; then
            BUFFER="git commit -am ${(qq)commit_message}"
        else
            BUFFER="git commit -m ${(qq)commit_message}"
        fi
        CURSOR=${#BUFFER}
        zle reset-prompt
    else
        _forge_reset
    fi
}
