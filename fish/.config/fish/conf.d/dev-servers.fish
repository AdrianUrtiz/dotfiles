# Dev servers: front (node/vite/next) + back (php/laravel) por puerto.
# Mata solo los puertos de dev, nunca hace pkill node/php (eso mataría
# opencode, codex y language servers del IDE).
# Puertos: 3000/3001 (next/vite custom), 4200 (angular), 5173/5174 (vite),
# 8000 (laravel/php artisan serve), 8080 (alternativo).

set -g __dev_ports 3000 3001 4200 5173 5174 8000 8080

function devports --description "Lista qué dev servers escuchan (puertos + proceso)"
    ss -tlnp 2>/dev/null | grep -E ':(3000|3001|4200|5173|5174|8000|8080)\b' || echo "sin dev servers en puertos 3000,3001,4200,5173,5174,8000,8080"
    if command -q herdr
        echo "--- herdr (dónde corren) ---"
        herdr pane list 2>/dev/null | python3 -c "
import json,sys
try:
    d = json.load(sys.stdin)
    panes = d.get('result', {}).get('panes', d.get('result', {}).get('pane_list', []))
    if isinstance(panes, dict):
        panes = panes.get('panes', [])
    for p in panes:
        title = p.get('terminal_title_stripped') or p.get('terminal_title') or ''
        low = title.lower()
        if any(k in low for k in ('vite', 'next', 'npm run dev', 'artisan serve', 'php')) or '/client' in p.get('cwd','') or '/server' in p.get('cwd',''):
            print(p.get('pane_id'), '|', p.get('workspace_id'), '|', p.get('cwd'), '|', title)
except Exception as e:
    print('(no se pudo parsear herdr pane list)')
"
    end
end

function devkill --description "Mata solo dev servers en puertos 3000,3001,4200,5173,5174,8000,8080"
    set -l killed 0
    for port in $__dev_ports
        # fuser devuelve 0 si hay proceso escuchando; solo ahí mata
        if fuser "$port/tcp" >/dev/null 2>&1
            echo "> matando puerto $port ..."
            fuser -k "$port/tcp" 2>/dev/null
            set killed 1
        end
    end
    if test $killed -eq 0
        echo "nada escuchando en 3000,3001,4200,5173,5174,8000,8080"
    end
end
