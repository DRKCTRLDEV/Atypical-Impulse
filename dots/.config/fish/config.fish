if status is-interactive
    # No greeting
    set fish_greeting

    # Colors from quickshell theme
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Starship prompt (skip in vscode, zed, and linux VT)
    if not contains -- $TERM_PROGRAM vscode zed; and test "$TERM" != linux
        function starship_transient_prompt_func
            starship module character
        end
        starship init fish | source
    end

    # Aliases
    alias cls 'clear'
    alias q 'qs -c ii'

    if command -q eza
        alias ls 'eza --icons'
    end
end
