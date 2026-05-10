#!/usr/bin/env zsh

# Key bindings and widget registration for pi shell plugin

# Register ZLE widgets
zle -N pi-accept-line
zle -N pi-completion

# Custom bracketed-paste handler that wraps dropped file paths in @[] syntax
# and fixes syntax highlighting after paste.
#
function pi-bracketed-paste() {
    # Call the built-in bracketed-paste widget first
    zle .$WIDGET "$@"
    
    # Explicitly redisplay the buffer to ensure paste content is visible
    # This is critical for large or multiline pastes
    zle redisplay
    
    # Reset the prompt to trigger syntax highlighting refresh
    # The redisplay before reset-prompt ensures the buffer is fully rendered
    zle reset-prompt
}

# Re-applied after zsh-vi-mode's `zvm_init` precmd hook, which rebuilds the
# main/viins/vicmd keymaps and otherwise silently clobbers these bindings.
function _pi_apply_keybindings() {
    zle -N bracketed-paste pi-bracketed-paste
    bindkey '^M' pi-accept-line
    bindkey '^J' pi-accept-line
    bindkey '^I' pi-completion
}

_pi_apply_keybindings

# Harmless no-op when zsh-vi-mode (jeffreytse/zsh-vi-mode) isn't loaded.
typeset -ga zvm_after_init_commands
zvm_after_init_commands+=('_pi_apply_keybindings')
