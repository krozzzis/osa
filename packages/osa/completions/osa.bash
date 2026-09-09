_osa_configuration_names() {
  local config_dir=$HOME/osa-user i word

  for ((i = 1; i < COMP_CWORD; i++)); do
    word=${COMP_WORDS[i]}
    case $word in
      -c|--config)
        ((i++))
        config_dir=${COMP_WORDS[i]}
        ;;
      --config=*) config_dir=${word#*=} ;;
    esac
  done

  config_dir=${config_dir/#\~/$HOME}
  nix eval --raw "$config_dir#nixosConfigurations" \
    --apply 'x: builtins.concatStringsSep "\n" (builtins.attrNames x)' 2>/dev/null
}

_osa() {
  local cur prev command word
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD - 1]}

  if [[ $prev == -c || $prev == --config ]]; then
    compopt -o filenames
    COMPREPLY=($(compgen -d -- "$cur"))
    return
  fi

  for word in "${COMP_WORDS[@]:1}"; do
    case $word in
      update|update-switch|update-boot|switch|boot|build-iso|build-installer|help)
        command=$word
        break
        ;;
    esac
  done

  if [[ -z $command ]]; then
    COMPREPLY=($(compgen -W 'update update-switch update-boot switch boot build-iso build-installer help' -- "$cur"))
  elif [[ $cur == -* ]]; then
    COMPREPLY=($(compgen -W '-c --config -h --help --' -- "$cur"))
  elif [[ $command != update && $command != help ]]; then
    COMPREPLY=($(compgen -W "$(_osa_configuration_names)" -- "$cur"))
  fi
}

complete -F _osa osa
