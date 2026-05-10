#!/usr/bin/env zsh

# Authentication action handlers for pi

function _forge_action_login() {
    _pi_shell_accept_prompt_as_command "/login"
}

function _forge_action_logout() {
    _pi_shell_accept_prompt_as_command "/logout"
}
