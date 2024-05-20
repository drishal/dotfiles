import Variable from 'resource:///com/github/Aylur/ags/variable.js';
import GLib from 'gi://GLib';

// const intval = options.systemFetchInterval;

export const uptime = Variable('', {
    poll: [60_000, 'cat /proc/uptime', line => {
        const uptime = Number.parseInt(line.split('.')[0]) / 60;
        // if (uptime > 18 * 60)
        //     return 'Go Sleep';

        const h = Math.floor(uptime / 60);
        const s = Math.floor(uptime % 60);
        return `${h}:${s < 10 ? '0' + s : s}`;
    }],
});

export const distro = GLib.get_os_info('ID');

export const distroIcon = (() => {
    switch (distro) {
        case 'fedora': return '';
        case 'arch': return '';
        case 'nixos': return '';
        case 'debian': return '';
        case 'opensuse-tumbleweed': return '';
        case 'ubuntu': return '';
        case 'endeavouros': return '';
        default: return '';
    }
})();

