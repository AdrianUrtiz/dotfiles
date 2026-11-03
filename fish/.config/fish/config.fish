# Base de CachyOS (solo existe ahí; en Fedora se omite sin romper nada)
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# overwrite greeting
# potentially disabling fastfetch
function fish_greeting
end

if status is-interactive
    starship init fish | source
end
