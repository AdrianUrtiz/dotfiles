#!/usr/bin/env bash
# Instalador interactivo de dotfiles (sin dependencias extra, solo bash).
# Uso:
#   ./install.sh                  -> menú interactivo (marcar/desmarcar con números)
#   ./install.sh --all            -> instala todo
#   ./install.sh --cachy          -> preset CachyOS/Hyprland
#   ./install.sh --fedora         -> preset Fedora/GNOME
#   ./install.sh fish starship git ... -> solo esos paquetes
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(fish starship git hypr kitty ghostty antigravity)

desc() {
    case "$1" in
        fish)        echo "Fish shell (~/.config/fish/config.fish)" ;;
        starship)    echo "Prompt Starship (~/.config/starship.toml)" ;;
        git)         echo "Aliases git (~/.gitconfig: co, st, lg...)" ;;
        hypr)        echo "Hyprland CachyOS, atajo SUPER+G (~/.config/hypr/)" ;;
        kitty)       echo "Terminal Kitty (~/.config/kitty/)" ;;
        ghostty)     echo "Terminal Ghostty, Fedora/GNOME (~/.config/ghostty/)" ;;
        antigravity) echo "Antigravity settings.json (solo ajustes, sin cachés)" ;;
    esac
}

# --- Detección de sistema ---
# shellcheck disable=SC1091
source /etc/os-release 2>/dev/null || true
DISTRO="${ID:-desconocida}"
FAMILY="otra"
case "${ID_LIKE:-} ${ID:-}" in
    *arch*)   FAMILY="arch" ;;
    *fedora*|*rhel*) FAMILY="fedora" ;;
esac
DE="${XDG_CURRENT_DESKTOP:-desconocido}"

if [[ "$FAMILY" == "arch" ]]; then
    PM_INSTALL=(sudo pacman -S --needed --noconfirm)
elif [[ "$FAMILY" == "fedora" ]]; then
    PM_INSTALL=(sudo dnf install -y)
else
    echo "Distro no reconocida ($DISTRO): instalaré dependencias a mano si hace falta."
    PM_INSTALL=(sudo)
fi

# Dependencias por paquete y familia (vacío = nada que instalar)
pkg_deps() {
    case "$1:$FAMILY" in
        fish:*)        echo "fish" ;;
        starship:*)    echo "starship" ;;
        git:arch)      echo "git libsecret" ;;
        git:fedora)    echo "git libsecret" ;;
        git:*)         echo "git" ;;
        kitty:*)       echo "kitty" ;;
        ghostty:*)     echo "ghostty" ;;
        hypr:arch)     echo "" ;;
        hypr:*)        echo "__UNSUPPORTED__" ;;
        antigravity:*) echo "" ;;
    esac
}

PRESET_CACHY=(fish starship git hypr kitty antigravity)
PRESET_FEDORA=(fish starship git ghostty antigravity)

default_selection() {
    case "$DE" in
        *Hyprland*) echo "${PRESET_CACHY[@]}" ;;
        *GNOME*)    echo "${PRESET_FEDORA[@]}" ;;
        *)          echo "fish starship git antigravity" ;;
    esac
}

# --- Selección de paquetes ---
selected=()
is_selected() {
    local p="$1" s
    for s in "${selected[@]}"; do [[ "$s" == "$p" ]] && return 0; done
    return 1
}
toggle() {
    local p="$1" out=() s
    if is_selected "$p"; then
        for s in "${selected[@]}"; do [[ "$s" != "$p" ]] && out+=("$s"); done
        selected=("${out[@]}")
    else
        selected+=("$p")
    fi
}

usage() {
    echo "Uso: $0 [--all|--cachy|--fedora|--help|paquete...]"
    echo "Paquetes: ${PACKAGES[*]}"
}

if [[ $# -gt 0 ]]; then
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --all)    selected=("${PACKAGES[@]}") ;;
        --cachy)  selected=("${PRESET_CACHY[@]}") ;;
        --fedora) selected=("${PRESET_FEDORA[@]}") ;;
        *)
            for p in "$@"; do
                valid=0
                for q in "${PACKAGES[@]}"; do [[ "$p" == "$q" ]] && valid=1; done
                if (( valid )); then selected+=("$p");
                else echo "Paquete desconocido: $p"; usage; exit 1; fi
            done ;;
    esac
elif [[ ! -t 0 ]]; then
    echo "Sin terminal interactiva: indica paquetes o usa --all."
    usage; exit 1
else
    # shellcheck disable=SC2207
    selected=($(default_selection))
    while true; do
        echo
        echo "Sistema: $DISTRO / $DE  (sugerencia precargada, cámbiala a gusto)"
        echo "Escribe un número para marcar/desmarcar:"
        menu=()
        for p in "${PACKAGES[@]}"; do
            if is_selected "$p"; then mark="[x]"; else mark="[ ]"; fi
            menu+=("$mark $p — $(desc "$p")")
        done
        menu+=(">>> Instalar selección" ">>> Salir sin hacer nada")
        PS3="Opción: "
        select choice in "${menu[@]}"; do
            n="$REPLY"
            if (( n >= 1 && n <= ${#PACKAGES[@]} )); then
                toggle "${PACKAGES[n-1]}"; break
            elif (( n == ${#PACKAGES[@]} + 1 )); then
                break 2
            elif (( n == ${#PACKAGES[@]} + 2 )); then
                echo "Cancelado."; exit 0
            else
                echo "Número no válido."; break
            fi
        done
    done
fi

if (( ${#selected[@]} == 0 )); then echo "Nada seleccionado."; exit 0; fi
echo
echo "Se instalará: ${selected[*]}"

# --- Instalación ---
install_deps() {
    local pkgs=("$@") p deps d install_list=()
    for p in "${pkgs[@]}"; do
        deps="$(pkg_deps "$p")"
        if [[ "$deps" == "__UNSUPPORTED__" ]]; then
            echo "AVISO: '$p' es config de CachyOS/Hyprland, en $DISTRO/$DE se omite su instalación de dependencias."
            continue
        fi
        for d in $deps; do install_list+=("$d"); done
    done
    # stow siempre hace falta
    command -v stow >/dev/null || install_list+=("stow")
    if (( ${#install_list[@]} > 0 )); then
        # deduplicar
        mapfile -t install_list < <(printf '%s\n' "${install_list[@]}" | sort -u)
        echo "+ ${PM_INSTALL[*]} ${install_list[*]}"
        "${PM_INSTALL[@]}" "${install_list[@]}" || {
            echo "AVISO: falló algún paquete (${install_list[*]}). Sigo con los enlaces; instala a mano lo que falte."
        }
    fi
}

backup_target() {
    # $1 = ruta destino en $HOME, $2 = ruta origen en el repo (para comparar)
    local target="$1" src="$2" bak
    if [[ -L "$target" && "$(readlink "$target")" == "$src" ]]; then
        echo "  ya enlazado: $target"
        return 0
    fi
    if [[ -e "$target" || -L "$target" ]]; then
        if [[ -f "$target" && -f "$src" ]] && cmp -s "$target" "$src"; then
            rm -f "$target"
        else
            bak="$target.bak.$(date +%Y%m%d%H%M%S)"
            mv "$target" "$bak"
            echo "  backup: $target -> $bak"
        fi
    fi
}

link_antigravity() {
    # La ruta lleva espacio ("Antigravity IDE"): enlace manual, sin stow.
    local dest="$HOME/.config/Antigravity IDE/User/settings.json"
    local src="$DOTFILES_DIR/antigravity/settings.json"
    mkdir -p "$(dirname "$dest")"
    backup_target "$dest" "$src"
    ln -sfn "$src" "$dest"
    echo "  enlazado: $dest"
}

stow_file() {
    # $1 = paquete, $2 = ruta relativa (p.ej. fish .config/fish/config.fish)
    local pkg="$1" rel="$2"
    local src="$DOTFILES_DIR/$pkg/$rel" dest="$HOME/$rel"
    mkdir -p "$(dirname "$dest")"
    backup_target "$dest" "$src"
    ( cd "$DOTFILES_DIR" && stow -R -t "$HOME" "$pkg" )
    echo "  stow: $pkg ($rel)"
}

stow_dir() {
    # $1 = paquete, $2 = directorio relativo (p.ej. hypr .config/hypr)
    local pkg="$1" rel="$2" bak
    local src="$DOTFILES_DIR/$pkg/$rel" dest="$HOME/$rel"
    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
        echo "  ya enlazado: $dest"
    else
        if [[ -e "$dest" || -L "$dest" ]]; then
            bak="$dest.bak.$(date +%Y%m%d%H%M%S)"
            mv "$dest" "$bak"
            echo "  backup: $dest -> $bak"
        fi
        mkdir -p "$(dirname "$dest")"
    fi
    ( cd "$DOTFILES_DIR" && stow -R -t "$HOME" "$pkg" )
    echo "  stow: $pkg ($rel)"
}

install_deps "${selected[@]}"

for p in "${selected[@]}"; do
    echo "Paquete: $p"
    case "$p" in
        fish)       stow_file fish .config/fish/config.fish ;;
        starship)   stow_file starship .config/starship.toml ;;
        git)        stow_file git .gitconfig ;;
        hypr)
            if [[ "$DE" != *Hyprland* ]]; then
                echo "  AVISO: config de Hyprland (CachyOS); en $DE solo la enlazo, no tendrá efecto."
            fi
            stow_dir hypr .config/hypr ;;
        kitty)      stow_dir kitty .config/kitty ;;
        ghostty)    stow_dir ghostty .config/ghostty ;;
        antigravity) link_antigravity ;;
    esac
done

if [[ " ${selected[*]} " == *" antigravity "* ]]; then
    echo
    echo "Nota Antigravity: el repo solo guarda settings.json."
    echo "  CachyOS: sudo snap install antigravity-ide-snap (snap/antigravity-ide-snap.antigravity-ide)"
    echo "  Fedora:  instala el .rpm de la web de Google Antigravity."
fi

echo
echo "Hecho. Recarga con: exec fish   (y en Hyprland: hyprctl reload)"
