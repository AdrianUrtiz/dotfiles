# dotfiles

Configuraciones personales.
Cada paquete replica la ruta de `$HOME` y se enlaza archivo por archivo.

## Paquetes

| Paquete      | Destino                                        | Notas                                                |
|--------------|------------------------------------------------|------------------------------------------------------|
| `fish`       | `~/.config/fish/`                          | `config.fish` + `conf.d/cachy-base.fish` portable (sin Arch-only) + `done.fish` |
| `starship`   | `~/.config/starship.toml`                      | Prompt azul dos líneas, compartido                   |
| `git`        | `~/.gitconfig` + `~/.gitconfig-{work,personal}`| Común sin `[user]`; identidad manual vía `~/.gitconfig.identity` |
| `hypr`       | `~/.config/hypr/`                              | Solo CachyOS/Hyprland. Atajo `SUPER+G` → Antigravity |
| `kitty`      | `~/.config/kitty/`                             | Solo CachyOS                                         |
| `ghostty`    | `~/.config/ghostty/`                           | Fedora/GNOME: config + `themes/catppuccin-mocha` + `custom.css` |
| `antigravity`| `~/.config/Antigravity IDE/User/settings.json` | Fuente de la verdad: el repo (se sobrescribe local)  |
| `zsh`        | `~/.zshrc`                                     | Fedora: oh-my-zsh + starship + zoxide (ver nota)     |
| `gnome`      | dconf + `~/.config/tiling-assistant/` + ext `herdr-focus@local` | Keybindings, dash, interface; Super+Shift+Enter enfoca Ghostty+herdr (`~/.local/bin/herdr-focus`); `monitors.xml` y `mimeapps.list` NO se versionan |
| `bin`        | `~/.local/bin/ant`                             | Wrapper `ant .` → Antigravity snap (snap en ambas distros; instala `snapd` si falta) |
| `herdr`      | `~/.config/herdr/config.toml`                  | Workspace manager: theme, ui, toast (logs/socks/sesiones NO se versionan) |

## Uso

```bash
git clone <este-repo> ~/dotfiles
cd ~/dotfiles
./install.sh                            # menú interactivo, preselecciona según tu escritorio
./install.sh --all                      # todo
./install.sh --cachy                    # preset CachyOS/Hyprland (git: work)
./install.sh --fedora                   # preset Fedora/GNOME (git: personal)
./install.sh --fedora --git-work        # Fedora pero con identidad trabajo
./install.sh fish starship git          # solo esos (git pregunta work/personal)
```

## git: identidad manual

`git/.gitconfig` es común y no lleva `[user]`. Termina con:

```ini
[include]
    path = ~/.gitconfig.identity
```

* `git/.gitconfig-work`: user trabajo + `includeIf gitdir:~/dev/freelance/` → `~/.gitconfig-freelance` (vive fuera del repo).
* `git/.gitconfig-personal`: user `AdrianUrtiz`/noreply + `includeIf gitdir:~/dev/employee/` → `~/.gitconfig-work`.
* Al instalar `git`, el instalador crea `~/.gitconfig.identity` → work o personal.
  Cambiar después: `ln -sf ~/.gitconfig-work ~/.gitconfig.identity` (o `-personal`).
* Presets: `--cachy` sugiere work, `--fedora` sugiere personal; `--git-work`/`--git-personal` lo fuerzan.

El instalador:
1. Detecta distro (`pacman`/`dnf`) y escritorio para sugerir selección.
2. Instala solo los programas que falten (si `fish`, `starship`... ya existen, no pide sudo).
3. Guarda backup `.bak.<fecha>` de lo que pise (si es idéntico, lo reemplaza sin backup).
4. Enlaza cada archivo del paquete a su ruta en `$HOME` con `ln -s`.

## Flujo diario

Edita normal (`~/.config/starship.toml`, etc.): como son symlinks al repo,
luego `git commit + push` en `~/dotfiles` y queda guardado.
