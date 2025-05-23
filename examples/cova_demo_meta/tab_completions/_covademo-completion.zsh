#compdef covademo

# This Tab Completion script was generated by the Cova Library.
# Details at https://github.com/00JCIV00/cova


# Zsh Completion Installation Instructions for covademo
# 1. Place this script in a directory specified in your $fpath, or a new one such as
#    ~/.zsh/completion/
#
# 2. Ensure the script has executable permissions:
#    chmod +x _covademo-completion.zsh
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
    "covademo" "sub-cmd basic nest-1 struct-cmd union-cmd fn-cmd add-user help usage --string --int --float --file --ordinal --cardinal --toggle --bool --verbosity --help --usage"
    "covademo_sub-cmd" "help usage --nested_str --help --usage"
    "covademo_basic" "help usage --help --usage"
    "covademo_nest-1" "nest-2 help usage --help --usage"
    "covademo_nest-1_nest-2" "nest-3 help usage --help --usage"
    "covademo_nest-1_nest-2_nest-3" "nest-4 help usage --inheritable --help --usage"
    "covademo_nest-1_nest-2_nest-3_nest-4" "help usage --help --usage"
    "covademo_struct-cmd" "inner-cmd help usage --int --str --str2 --flt --int2 --multi-int --multi-str --rgb-enum --struct-bool --struct-str --struct-int --help --usage"
    "covademo_struct-cmd_inner-cmd" "help usage --in-bool --in-float --h-string --help --usage"
    "covademo_union-cmd" "help usage --int --str --help --usage"
    "covademo_fn-cmd" "help usage --help --usage"
    "covademo_add-user" "help usage --fname --lname --age --admin --ref-ids --help --usage"
)
# Generic function for command completions
_covademo_completions() {
    local -a completions
    # Determine the current command context
    local context="covademo"
    for word in "${words[@]:1:$CURRENT-1}"; do
        if [[ -n $cmd_args[${context}_${word}] ]]; then
            context="${context}_${word}"
        fi
    done
    # Generate completions for the current context
    completions=(${(s: :)cmd_args[$context]})
    if [[ -n $completions ]]; then
        _describe -t commands "covademo" completions && return 0
    fi
}
_covademo_completions "$@"