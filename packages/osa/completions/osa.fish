function __osa_seen_command
    set -l commands update update-switch update-boot switch boot build-iso build-installer help
    for word in (commandline -opc)
        contains -- $word $commands; and return 0
    end
    return 1
end

function __osa_needs_configuration
    set -l words (commandline -opc)
    for command in update-switch update-boot switch boot build-iso build-installer
        contains -- $command $words; and return 0
    end
    return 1
end

function __osa_configuration_names
    set -l words (commandline -opc)
    set -l config_dir $HOME/osa-user

    for i in (seq (count $words))
        switch $words[$i]
            case -c --config
                set -l next (math $i + 1)
                test $next -le (count $words); and set config_dir $words[$next]
            case '--config=*'
                set config_dir (string replace -- '--config=' '' $words[$i])
        end
    end

    nix eval --raw "$config_dir#nixosConfigurations" \
        --apply 'x: builtins.concatStringsSep "\n" (builtins.attrNames x)' 2>/dev/null
end

complete -c osa -f
complete -c osa -n 'not __osa_seen_command' -a update -d 'Regenerate flake.nix and update flake.lock'
complete -c osa -n 'not __osa_seen_command' -a update-switch -d 'Update and activate the configuration now'
complete -c osa -n 'not __osa_seen_command' -a update-boot -d 'Update and activate the configuration on next boot'
complete -c osa -n 'not __osa_seen_command' -a switch -d 'Build and activate the configuration now'
complete -c osa -n 'not __osa_seen_command' -a boot -d 'Build and activate the configuration on next boot'
complete -c osa -n 'not __osa_seen_command' -a build-iso -d 'Build a bootable system image'
complete -c osa -n 'not __osa_seen_command' -a build-installer -d 'Build an installer package'
complete -c osa -n 'not __osa_seen_command' -a help -d 'Show help'
complete -c osa -s c -l config -r -a '(__fish_complete_directories)' -d 'Configuration flake'
complete -c osa -s h -l help -d 'Show help'
complete -c osa -n __osa_needs_configuration -a '(__osa_configuration_names)' -d Configuration
