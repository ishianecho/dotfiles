_set_proxy() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "$prev" in
        --http | --socks | --no-proxy)
            return 0
            ;;
    esac

    COMPREPLY=($(compgen -W "--http --socks --no-proxy --clear --show --sync -h --help" -- "$cur"))
}

complete -F _set_proxy set-proxy
