# dotfiles

Configuraciones personales gestionadas con [GNU Stow](https://www.gnu.org/software/stow/).
Cada carpeta es un paquete independiente que se enlaza a `$HOME`.

## Paquetes

| Paquete      | Destino                                        | Notas                                                |
|--------------|------------------------------------------------|------------------------------------------------------|
| `fish`       | `~/.config/fish/config.fish`                   | Starship + sin fastfetch                             |
| `starship`   | `~/.config/starship.toml`                      | Prompt azul dos líneas, letra blanca                 |
| `git`        | `~/.gitconfig`                                 | Aliases `co, st, lg...` (el `includeIf` freelance vive fuera, en `~/.gitconfig-freelance`) |
| `hypr`       | `~/.config/hypr/`                              | Solo CachyOS/Hyprland. Atajo `SUPER+G` → Antigravity |
| `kitty`      | `~/.config/kitty/`                             | Terminal de CachyOS                                  |
| `ghostty`    | `~/.config/ghostty/`                           | Terminal de Fedora/GNOME                             |
| `antigravity`| `~/.config/Antigravity IDE/User/settings.json` | Solo ajustes (enlace manual, la ruta lleva espacio)  |

## Uso

```bash
git clone <este-repo> ~/dotfiles
cd ~/dotfiles
./install.sh              # menú interactivo, preselecciona según tu escritorio
./install.sh --all        # todo
./install.sh --cachy      # preset CachyOS/Hyprland
./install.sh --fedora     # preset Fedora/GNOME
./install.sh fish starship git   # solo esos
```

El instalador (bash puro, sin dependencias extra):
1. Detecta distro (`pacman`/`dnf`) y escritorio para sugerir selección.
2. Instala dependencias (`fish`, `starship`, `stow`, terminal...).
3. Guarda backup `.bak.<fecha>` de lo que pise (si es idéntico, lo reemplaza sin backup).
4. Enlaza con `stow` (Antigravity con `ln -s` directo).

## Flujo diario

Edita normal (`~/.config/starship.toml`, etc.): como son symlinks al repo,
luego `git commit + push` en `~/dotfiles` y queda guardado.
