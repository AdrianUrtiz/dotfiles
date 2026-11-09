#!/usr/bin/env bash
# Instalador de dotfiles: bash puro, cero dependencias externas.
# Cada paquete replica la ruta de $HOME y se enlaza archivo por archivo con ln -s.
# Uso:
#   ./install.sh                  -> menú interactivo (marcar/desmarcar con números)
#   ./install.sh --all            -> instala todo
#   ./install.sh --cachy          -> preset CachyOS/Hyprland (git: work)
#   ./install.sh --fedora         -> preset Fedora/GNOME (git: personal)
#   ./install.sh --git-work / --git-personal -> identidad git (combinable)
#   ./install.sh fish starship git ... -> solo esos paquetes
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(fish starship git hypr kitty ghostty antigravity zsh gnome bin herdr)

desc() {
    case "$1" in
        fish)        echo "Fish shell (config.fish + conf.d portable sin Arch-only)" ;;
        starship)    echo "Prompt Starship (~/.config/starship.toml)" ;;
        git)         echo "Aliases git + identidad work/personal (elige al instalar)" ;;
        hypr)        echo "Hyprland CachyOS, atajo SUPER+G + run-or-raise kitty+herdr (Super+Shift+Enter, ~/.local/bin/herdr-hypr-focus)" ;;
        kitty)       echo "Terminal Kitty (~/.config/kitty/)" ;;
        ghostty)     echo "Terminal Ghostty, Fedora/GNOME (~/.config/ghostty/ + themes + css)" ;;
        antigravity) echo "Antigravity settings.json (solo ajustes, sin cachés)" ;;
        zsh)         echo "Zsh + oh-my-zsh (~/.zshrc)" ;;
        gnome)       echo "GNOME: keybindings, dash, interface + tiling-assistant (dconf) + extensión herdr-focus" ;;
        bin)         echo "Comando ant -> Antigravity (wrapper snap, ~/.local/bin/)" ;;
        herdr)       echo "Herdr workspace manager (~/.config/herdr/config.toml)" ;;
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
        fish:*)     echo "fish eza bat" ;;
        starship:*) echo "starship" ;;
        git:*)      echo "git libsecret" ;;
        kitty:*)    echo "kitty" ;;
        ghostty:*)  echo "ghostty" ;;
        zsh:*)      echo "zsh" ;;
        bin:*)      echo "snapd" ;;
        *)          echo "" ;;
    esac
}
pkg_bin() {
    case "$1" in
        fish|starship|git|kitty|ghostty|zsh) echo "$1" ;;
        bin) echo "snap" ;;
        *) echo "" ;;
    esac
}
# Binarios extra que el paquete necesita además del principal
pkg_extra_bins() {
    case "$1" in
        fish) echo "eza bat" ;;
        *) echo "" ;;
    esac
}

PRESET_CACHY=(fish starship git hypr kitty antigravity bin herdr)
PRESET_FEDORA=(fish zsh starship git ghostty antigravity gnome bin herdr)

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
    echo "Uso: $0 [--all|--cachy|--fedora|--git-work|--git-personal|--help|paquete...]"
    echo "Paquetes: ${PACKAGES[*]}"
    echo "  --git-work / --git-personal: qué identidad git usar (~/.gitconfig.identity)."
    echo "  Se pueden combinar: ./install.sh --fedora --git-personal"
}

GIT_IDENTITY=""  # work | personal (se pide si se instala git y no viene dado)

if [[ $# -gt 0 ]]; then
    for arg in "$@"; do
        case "$arg" in
            -h|--help) usage; exit 0 ;;
            --all)    selected=("${PACKAGES[@]}") ;;
            --cachy)  selected=("${PRESET_CACHY[@]}"); [[ -z "$GIT_IDENTITY" ]] && GIT_IDENTITY="work" ;;
            --fedora) selected=("${PRESET_FEDORA[@]}"); [[ -z "$GIT_IDENTITY" ]] && GIT_IDENTITY="personal" ;;
            --git-work)     GIT_IDENTITY="work" ;;
            --git-personal) GIT_IDENTITY="personal" ;;
            *)
                valid=0
                for q in "${PACKAGES[@]}"; do [[ "$arg" == "$q" ]] && valid=1; done
                if (( valid )); then selected+=("$arg");
                else echo "Paquete desconocido: $arg"; usage; exit 1; fi ;;
        esac
    done
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

# --- Identidad git (manual, portable entre equipos) ---
if is_selected "git" && [[ -z "$GIT_IDENTITY" ]]; then
    if [[ -t 0 ]]; then
        echo
        echo "Identidad git para ~/.gitconfig.identity:"
        echo "  1) work     (sfa.michoacan.gob.mx + include freelance)"
        echo "  2) personal (AdrianUrtiz/noreply + include ~/dev/employee/)"
        read -rp "Elige [1/2]: " _gi </dev/tty || true
        case "${_gi:-}" in
            1) GIT_IDENTITY="work" ;;
            2) GIT_IDENTITY="personal" ;;
            *) echo "Opción no válida, usa --git-work o --git-personal."; exit 1 ;;
        esac
    else
        echo "Falta identidad git: añade --git-work o --git-personal."
        exit 1
    fi
fi
[[ -n "$GIT_IDENTITY" ]] && echo "Identidad git: $GIT_IDENTITY"

# --- Dependencias: solo instala lo que falte (binario ausente) ---
install_missing_deps() {
    local pkgs=("$@") p bin b cmd pkgs_to_install=() missing
    for p in "${pkgs[@]}"; do
        bin="$(pkg_bin "$p")"
        [[ -z "$bin" ]] && continue
        missing=0
        command -v "$bin" >/dev/null 2>&1 || missing=1
        for b in $(pkg_extra_bins "$p"); do
            command -v "$b" >/dev/null 2>&1 || missing=1
        done
        (( missing )) || continue
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
# gnome/dconf/*.dconf no se enlaza: se aplica con 'dconf load' (restore_gnome).
link_package() {
    local pkg="$1" src dest rel bak
    while IFS= read -r -d '' src; do
        rel="${src#$DOTFILES_DIR/$pkg/}"
        if [[ "$pkg" == "gnome" && "$rel" == dconf/* ]]; then
            continue
        fi
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

setup_git_identity() {
    local want="$1" target
    target="$HOME/.gitconfig-$want"
    if [[ -L "$HOME/.gitconfig.identity" && "$(readlink "$HOME/.gitconfig.identity")" == "$target" ]]; then
        echo "  identidad ya activa: $want"
        return 0
    fi
    if [[ -e "$HOME/.gitconfig.identity" || -L "$HOME/.gitconfig.identity" ]]; then
        bak="$HOME/.gitconfig.identity.bak.$(date +%Y%m%d%H%M%S)"
        mv "$HOME/.gitconfig.identity" "$bak"
        echo "  backup: ~/.gitconfig.identity -> $bak"
    fi
    ln -s "$target" "$HOME/.gitconfig.identity"
    echo "  identidad: ~/.gitconfig.identity -> $target"
}

set_default_shell() {
    local shell_bin
    shell_bin="$(command -v fish)"
    if [[ "$SHELL" == "$shell_bin" ]]; then
        echo "  shell ya es fish: $SHELL"
        return 0
    fi
    echo "  cambiando shell a fish (actual: $SHELL)..."
    if chsh -s "$shell_bin"; then
        echo "  shell por defecto: fish (aplica en el próximo login)"
    else
        echo "  AVISO: no se pudo cambiar. Hazlo a mano: chsh -s $shell_bin"
    fi
}

restore_gnome() {
    local f key
    command -v dconf >/dev/null 2>&1 || { echo "  AVISO: 'dconf' no existe, omito restore."; return 0; }
    for f in "$DOTFILES_DIR/gnome/dconf/"*.dconf; do
        case "$(basename "$f")" in
            media-keys.dconf)   key="/org/gnome/settings-daemon/plugins/media-keys/" ;;
            shell.dconf)        key="/org/gnome/shell/" ;;
            dash-to-dock.dconf) key="/org/gnome/shell/extensions/dash-to-dock/" ;;
            interface.dconf)    key="/org/gnome/desktop/interface/" ;;
            input-sources.dconf) key="/org/gnome/desktop/input-sources/" ;;
            wm-keybindings.dconf) key="/org/gnome/desktop/wm/keybindings/" ;;
            mutter.dconf)       key="/org/gnome/mutter/" ;;
            *) echo "  AVISO: sin ruta dconf para $(basename "$f"), lo omito."; continue ;;
        esac
        dconf load "$key" < "$f"
        echo "  dconf: $key <- $(basename "$f")"
    done
}

for p in "${selected[@]}"; do
    echo "Paquete: $p"
    if [[ "$p" == "hypr" && "$DE" != *Hyprland* ]]; then
        echo "  AVISO: config de Hyprland (CachyOS); en $DE solo la enlazo, no tendrá efecto."
    fi
    if [[ "$p" == "gnome" && "$DE" != *GNOME* ]]; then
        echo "  AVISO: config de GNOME; en $DE solo la enlazo, el restore dconf puede no aplicar."
    fi
    link_package "$p"
    if [[ "$p" == "git" ]]; then
        setup_git_identity "$GIT_IDENTITY"
    fi
    if [[ "$p" == "gnome" ]]; then
        restore_gnome
        if command -v gnome-extensions >/dev/null 2>&1; then
            gnome-extensions enable herdr-focus@local 2>/dev/null \
                && echo "  extensión: herdr-focus@local activada" \
                || echo "  AVISO: no se pudo activar herdr-focus@local"
        fi
    fi
    if [[ "$p" == "fish" ]]; then
        set_default_shell
    fi
done

if [[ " ${selected[*]} " == *" antigravity "* ]]; then
    echo
    echo "Nota Antigravity: el repo solo guarda settings.json."
    echo "  App por snap en ambas máquinas (snap run antigravity-ide-snap.antigravity-ide)."
    echo "  Comando 'ant' lo provee el paquete bin (bin/.local/bin/ant)."
fi
if [[ " ${selected[*]} " == *" git "* ]] && ! command -v git-credential-libsecret >/dev/null 2>&1; then
    echo "Nota git: el helper 'libsecret' se instaló con git; si 'git push' pide usuario siempre, avísame."
fi
if [[ " ${selected[*]} " == *" git "* ]]; then
    echo "Nota git: ~/.gitconfig (común) incluye ~/.gitconfig.identity -> ~/.gitconfig-$GIT_IDENTITY."
    echo "  Cambiar después: ln -sf ~/.gitconfig-work ~/.gitconfig.identity  (o -personal)"
fi
if [[ " ${selected[*]} " == *" gnome "* ]]; then
    echo "Nota gnome: dconf aplicado con 'dconf load'. Re-aplica con ./install.sh gnome."
    echo "  monitors.xml y mimeapps.list NO se versionan (hardware/apps de esta máquina)."
fi
if [[ " ${selected[*]} " == *" zsh "* ]] && [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Nota zsh: falta ~/.oh-my-zsh. Instálalo y los plugins:"
    echo "  sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
    echo "  plugins: zsh-syntax-highlighting zsh-autosuggestions zsh-history-substring-search (oh-my-zsh custom)"
fi

echo
echo "Hecho. Recarga con: exec fish   (zsh sigue disponible: exec zsh)"
