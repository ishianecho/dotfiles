_xrayctl() {
    local cur prev state_file
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    state_file="${XDG_CONFIG_HOME:-$HOME/.config}/xray/state.json"

    case "$prev" in
        --address | --port | --uuid | --sni | --public-key | --short-id | --socks | --tproxy)
            return 0
            ;;
    esac

    case "$COMP_CWORD" in
        1)
            COMPREPLY=($(compgen -W "node route port status restart test tproxy direct init --no-restart -h --help" -- "$cur"))
            ;;
        2)
            case "${COMP_WORDS[1]}" in
                node) COMPREPLY=($(compgen -W "add rm list use show set" -- "$cur")) ;;
                route) COMPREPLY=($(compgen -W "add rm list" -- "$cur")) ;;
                port) COMPREPLY=($(compgen -W "set" -- "$cur")) ;;
                tproxy) COMPREPLY=($(compgen -W "status" -- "$cur")) ;;
            esac
            ;;
        3)
            case "${COMP_WORDS[1]}:${COMP_WORDS[2]}" in
                route:add) COMPREPLY=($(compgen -W "direct proxy block" -- "$cur")) ;;
                route:rm)
                    [ -r "$state_file" ] && COMPREPLY=($(compgen -W "$(jq -r '.routes[].matcher' "$state_file" 2>/dev/null)" -- "$cur"))
                    ;;
                node:add) COMPREPLY=($(compgen -W "--use --address --port --uuid --sni --public-key --short-id" -- "$cur")) ;;
                node:rm | node:use | node:show | node:set)
                    [ -r "$state_file" ] && COMPREPLY=($(compgen -W "$(jq -r '.nodes[].tag' "$state_file" 2>/dev/null)" -- "$cur"))
                    ;;
                port:set) COMPREPLY=($(compgen -W "--socks --tproxy" -- "$cur")) ;;
            esac
            ;;
        *)
            case "${COMP_WORDS[1]}:${COMP_WORDS[2]}" in
                node:set) COMPREPLY=($(compgen -W "--address --port --uuid --sni --public-key --short-id" -- "$cur")) ;;
            esac
            ;;
    esac
}

complete -F _xrayctl xrayctl
