import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
import Service from 'resource:///com/github/Aylur/ags/service.js';

class Brightness extends Service {
    static {
        Service.register(this, {}, {
            'screen': ['float', 'rw'],
        });
    }

    #screen = 0;

    #interface = Utils.exec("sh -c 'ls -w1 /sys/class/backlight | head -1'");
    #max = Number(Utils.exec('brightnessctl max'));

    get screen() { return this.#screen; }

    set screen(percent) {
        if (percent < 0)
            percent = 0;

        if (percent > 1)
            percent = 1;

        Utils.execAsync(`brightnessctl s ${percent * 100}% -q`)
            .then(() => {
                this.#screen = percent;
                this.changed('screen');
            })
            .catch(console.error);
    }

    constructor() {
        super();
        const brightness = `/sys/class/backlight/${this.#interface}/brightness`;
        Utils.monitorFile(brightness, () => this.#onChange());

        // initialize
        this.#onChange();
    }

    #onChange() {
        this.#screen = Number(Utils.exec('brightnessctl get')) / this.#max;
        this.changed('screen');
    }
}

export default new Brightness();