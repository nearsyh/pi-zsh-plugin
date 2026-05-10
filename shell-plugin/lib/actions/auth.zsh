#!/usr/bin/env zsh

# Authentication action handlers for pi

function _forge_action_login() {
    echo
    _pi_shell_send_prompt "/login"
}

function _forge_action_logout() {
    echo
    _pi_shell_send_prompt "/logout"
}
