#!/usr/bin/env zsh

# Lightweight shell command history for pi prompts.
# Records recent command text, exit code, cwd, and timestamp for this shell only.

function _pi_history_preexec() {
    [[ "${PI_ZSH_HISTORY_ENABLED:-true}" != "true" ]] && return 0
    _PI_HISTORY_PENDING_CMD="$1"
    _PI_HISTORY_PENDING_CWD="$PWD"
    _PI_HISTORY_PENDING_TS="$(date '+%Y-%m-%d %H:%M:%S')"
}

function _pi_history_precmd() {
    local last_exit=$?

    [[ "${PI_ZSH_HISTORY_ENABLED:-true}" != "true" ]] && return 0
    [[ -z "$_PI_HISTORY_PENDING_CMD" ]] && return 0

    _PI_HISTORY_COMMANDS+=("$_PI_HISTORY_PENDING_CMD")
    _PI_HISTORY_EXIT_CODES+=("$last_exit")
    _PI_HISTORY_CWDS+=("$_PI_HISTORY_PENDING_CWD")
    _PI_HISTORY_TIMESTAMPS+=("$_PI_HISTORY_PENDING_TS")

    while (( ${#_PI_HISTORY_COMMANDS} > ${PI_ZSH_HISTORY_MAX_COMMANDS:-5} )); do
        shift _PI_HISTORY_COMMANDS
        shift _PI_HISTORY_EXIT_CODES
        shift _PI_HISTORY_CWDS
        shift _PI_HISTORY_TIMESTAMPS
    done

    _PI_HISTORY_PENDING_CMD=""
    _PI_HISTORY_PENDING_CWD=""
    _PI_HISTORY_PENDING_TS=""
}

function _pi_history_recent_context() {
    [[ "${PI_ZSH_HISTORY_ENABLED:-true}" != "true" ]] && return 0
    (( ${#_PI_HISTORY_COMMANDS} == 0 )) && return 0

    echo "Recent shell commands from this zsh session:"

    local index
    for index in {1..${#_PI_HISTORY_COMMANDS}}; do
        echo "- [${_PI_HISTORY_TIMESTAMPS[$index]}] cwd=${_PI_HISTORY_CWDS[$index]} exit=${_PI_HISTORY_EXIT_CODES[$index]} cmd=${_PI_HISTORY_COMMANDS[$index]}"
    done
}

if [[ "${PI_ZSH_HISTORY_ENABLED:-true}" == "true" ]]; then
    preexec_functions+=(_pi_history_preexec)
    precmd_functions=(_pi_history_precmd "${precmd_functions[@]}")
fi
