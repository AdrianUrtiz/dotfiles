#!/usr/bin/env bash
# Instalador de dotfiles: bash puro, cero dependencias externas.
# Cada paquete replica la ruta de $HOME y se enlaza archivo por archivo con ln -s.
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
    *arch*)        FAMILY="arch" ;;
    *fedora*|*rhel*) FAMILY="fedora" ;;
esac
DE="${XDG_CURRENT_DESKTOP:-desconocido}"

# Paquetes de la distro necesarios si falta el binario (vacío = nada)
pkg_distro_pkgs() {
    case "$1:$FAMILY" in
        fish:*)     echo "fish" ;;
        starship:*) echo "starship" ;;
        git:*)      echo "git libsecret" ;;
        kitty:*)    echo "kitty" ;;
        ghostty:*)  echo "ghostty" ;;
        *)          echo "" ;;
    esac
}
pkg_bin() {
    case "$1" in
        fish|starship|git|kitty|ghostty) echo "$1" ;;
        *) echo "" ;;
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

# --- Dependencias: solo instala lo que falte (binario ausente) ---
install_missing_deps() {
    local pkgs=("$@") p bin cmd pkgs_to_install=()
    for p in "${pkgs[@]}"; do
        bin="$(pkg_bin "$p")"
        [[ -z "$bin" ]] && continue
        if command -v "$bin" >/dev/null 2>&1; then continue; fi
        for cmd in $(pkg_distro_pkgs "$p"); do pkgs_to_install+=("$cmd"); done
    done
    if (( ${#pkgs_to_install[@]} == 0 )); then
        echo "Dependencias: todo lo necesario ya está instalado."
        return 0
    fi
    mapfile -t pkgs_to_install < <(printf '%s\n' "${pkgs_to_install[@]}" | sort -u)
    if [[ "$FAMILY" == "arch" ]]; then
        echo "+ sudo pacman -S --needed ${pkgs_to_install[*]}"
        sudo pacman -S --needed --noconfirm "${pkgs_to_install[@]}"
    elif [[ "$FAMILY" == "fedora" ]]; then
        echo "+ sudo dnf install -y ${pkgs_to_install[*]}"
        sudo dnf install -y "${pkgs_to_install[@]}"
    else
        echo "AVISO: distro no reconocida ($DISTRO). Instala a mano: ${pkgs_to_install[*]}"
    fi
}

# --- Enlazado nativo (equivale al "folding" de stow, sin stow) ---
link_package() {
    local pkg="$1" src dest rel bak
    while IFS= read -r -d '' src; do
        rel="${src#$DOTFILES_DIR/$pkg/}"
        dest="$HOME/$rel"
        if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
            echo "  ya enlazado: $dest"
            continue
        fi
        if [[ -d "$dest" && ! -L "$dest" ]]; then
            echo "  AVISO: $dest es un directorio real, no puedo poner un archivo encima. Revísalo a mano."
            continue
        fi
        if [[ -e "$dest" || -L "$dest" ]]; then
            if cmp -s "$dest" "$src" 2>/dev/null; then
                rm -f "$dest"
            else
                bak="$dest.bak.$(date +%Y%m%d%H%M%S)"
                mv "$dest" "$bak"
                echo "  backup: $dest -> $bak"
            fi
        fi
        mkdir -p "$(dirname "$dest")"
        ln -s "$src" "$dest"
        echo "  enlazado: $dest"
    done < <(find "$DOTFILES_DIR/$pkg" -type f -print0)
}

install_missing_deps "${selected[@]}"

for p in "${selected[@]}"; do
    echo "Paquete: $p"
    if [[ "$p" == "hypr" && "$DE" != *Hyprland* ]]; then
        echo "  AVISO: config de Hyprland (CachyOS); en $DE solo la enlazo, no tendrá efecto."
    fi
    link_package "$p"
done

if [[ " ${selected[*]} " == *" antigravity "* ]]; then
    echo
    echo "Nota Antigravity: el repo solo guarda settings.json."
    echo "  CachyOS: la app ya está (snap/antigravity-ide-snap.antigravity-ide)."
    echo "  Fedora:  instala el .rpm de la web de Google Antigravity."
fi
if [[ " ${selected[*]} " == *" git "* ]] && ! command -v git-credential-libsecret >/dev/null 2>&1; then
    echo "Nota git: el helper 'libsecret' se instaló con git; si 'git push' pide usuario siempre, avísame."
fi

echo
echo "Hecho. Recarga con: exec fish   (y en Hyprland: hyprctl reload)"
