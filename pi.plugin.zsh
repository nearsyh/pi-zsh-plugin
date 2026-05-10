#!/usr/bin/env zsh

# Documentation in [README.md](./README.md)

# Modular pi shell plugin - sources all required modules

# Configuration variables
source "${0:A:h}/lib/config.zsh"

# Syntax highlighting
source "${0:A:h}/lib/highlight.zsh"

# Core utilities (includes logging)
source "${0:A:h}/lib/helpers.zsh"

# Shell command history capture
source "${0:A:h}/lib/history.zsh"

# Pending prompt dispatch outside ZLE
source "${0:A:h}/lib/pending.zsh"

# Completion widget
source "${0:A:h}/lib/completion.zsh"

# Action handlers
source "${0:A:h}/lib/actions/core.zsh"
source "${0:A:h}/lib/actions/config.zsh"
source "${0:A:h}/lib/actions/conversation.zsh"
source "${0:A:h}/lib/actions/git.zsh"

# Main dispatcher and widget registration
source "${0:A:h}/lib/dispatcher.zsh"

# Key bindings and widget registration
source "${0:A:h}/lib/bindings.zsh"

# Right prompt theme
source "${0:A:h}/pi.theme.zsh"

_PI_PLUGIN_LOADED=1
