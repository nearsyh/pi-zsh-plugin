#!/usr/bin/env zsh

# Authentication action handlers for pi

function _pi_action_login() {
    _pi_shell_send_prompt "/login"
}

function _pi_action_logout() {
    _pi_shell_send_prompt "/logout"
}
