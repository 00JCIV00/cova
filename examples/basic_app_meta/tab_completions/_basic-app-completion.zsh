#compdef basic-app

# This Tab Completion script was generated by the Cova Library.
# Details at https://github.com/00JCIV00/cova


# Zsh Completion Installation Instructions for basic-app
# 1. Place this script in a directory specified in your $fpath, or a new one such as
#    ~/.zsh/completion/
#
# 2. Ensure the script has executable permissions:
#    chmod +x _basic-app-completion.zsh
#
# 3. Add the script's directory to your $fpath in your .zshrc if not already included:
#    fpath=(~/.zsh/completion $fpath)
#
# 4. Enable and initialize completion in your .zshrc if you haven't already (oh-my-zsh does this automatically):
#    autoload -Uz compinit && compinit
#
# 5. Restart your terminal session or source your .zshrc again:
#    source ~/.zshrc


# Associative array to hold Commands, Options, and their descriptions with arbitrary depth
typeset -A cmd_args
cmd_args=(
    "basic-app" "new open list clean view-lists help usage --help --usage"
    "basic-app_new" "help usage --first-name --last-name --age --phone --address --help --usage"
    "basic-app_open" "help usage --help --usage"
    "basic-app_list" "filter help usage --help --usage"
    "basic-app_list_filter" "help usage --id --admin --age --first-name --last-name --phone --address --help --usage"
    "basic-app_clean" "help usage --file --help --usage"
    "basic-app_view-lists" "help usage --help --usage"
)
# Generic function for command completions
_basic-app_completions() {
    local -a completions
    # Determine the current command context
    local context="basic-app"
    for word in "${words[@]:1:$CURRENT-1}"; do
        if [[ -n $cmd_args[${context}_${word}] ]]; then
            context="${context}_${word}"
        fi
    done
    # Generate completions for the current context
    completions=(${(s: :)cmd_args[$context]})
    if [[ -n $completions ]]; then
        _describe -t commands "basic-app" completions && return 0
    fi
}
_basic-app_completions "$@"