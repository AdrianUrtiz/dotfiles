// Herdr Focus: enfoca la ventana Ghostty que corre herdr (match por PID).
// Uso desde el atajo: el script herdr-focus llama por DBus a FocusHerdr();
// si no hay ventana, el script abre una nueva.

import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const BUS_NAME = 'dev.herdr.Focus';
const BUS_PATH = '/dev/herdr/Focus';

const IFACE_XML = `
<node>
  <interface name="dev.herdr.Focus">
    <method name="FocusHerdr">
      <arg type="b" name="focused" direction="out"/>
    </method>
  </interface>
</node>`;

function herdrGhosttyPids() {
    const pids = new Set();
    try {
        const [ok, stdout, , status] = GLib.spawn_command_line_sync('/usr/bin/pgrep -f "ghostty.*herdr"');
        if (!ok || status !== 0)
            return pids;
        const text = new TextDecoder().decode(stdout);
        for (const line of text.split('\n')) {
            const pid = parseInt(line.trim(), 10);
            if (Number.isFinite(pid) && pid > 0)
                pids.add(pid);
        }
    } catch {
        // sin pids: se devuelve el set vacío y el script abrirá herdr
    }
    return pids;
}

export default class HerdrFocusExtension extends Extension {
    enable() {
        this._impl = Gio.DBusExportedObject.wrapJSObject(IFACE_XML, this);
        this._impl.export(Gio.DBus.session, BUS_PATH);
        this._ownerId = Gio.bus_own_name(
            Gio.BusType.SESSION, BUS_NAME,
            Gio.BusNameOwnerFlags.NONE, null, null, null);
    }

    disable() {
        if (this._impl) {
            this._impl.unexport();
            this._impl = null;
        }
        if (this._ownerId) {
            Gio.bus_unown_name(this._ownerId);
            this._ownerId = 0;
        }
    }

    FocusHerdr() {
        const pids = herdrGhosttyPids();
        if (pids.size === 0)
            return false;
        const wm = global.workspace_manager;
        for (let i = 0; i < wm.get_n_workspaces(); i++) {
            const ws = wm.get_workspace_by_index(i);
            if (!ws)
                continue;
            for (const win of ws.list_windows()) {
                if (win.is_skip_taskbar())
                    continue;
                let pid = 0;
                try {
                    pid = win.get_pid();
                } catch {
                    continue;
                }
                if (pid > 0 && pids.has(pid)) {
                    // Igual que clicar su icono en el dash: cambia de
                    // workspace si hace falta y le da foco (activate() solo
                    // mostraba "está preparado" entre workspaces).
                    Main.activateWindow(win);
                    return true;
                }
            }
        }
        return false;
    }
}
