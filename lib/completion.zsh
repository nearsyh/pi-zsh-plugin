#!/usr/bin/env zsh

# TODO: Rebuild completion for the simplified pi plugin command set.
# For now, leave Tab behavior unchanged to avoid surprising shell completion.

function pi-completion() {
    zle expand-or-complete
}
