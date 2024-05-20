import Service from 'resource:///com/github/Aylur/ags/service.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';

class auto_cpufreqService extends Service {

    static {
        Service.register(
            this,
            {},
            {
                'governor': ['string', 'rw']
            }
        );
    }

    #governor = 'Default';

    get governor() { return this.#governor; }

    set governor(governor) {
        if (governor == 'Default') {
            governor = 'reset'
        }
        Utils.execAsync(`pkexec auto-cpufreq --force=${governor.toLowerCase()}`)
            .then(() => {
                this.#governor = governor;
                this.changed('governor');
            })
            .catch(console.error);
    }

    constructor() {
        super();
        const governor_file = '/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor';
        Utils.monitorFile(governor_file, () => this.#onChange());
        
        this.#onChange();
    }

    #onChange() {
        Utils.execAsync('auto-cpufreq --get-state')
            .then((governor) => {
                this.#governor = governor;
                this.changed('governor');
            })
            .catch(console.error);
    }

};

export default new auto_cpufreqService;