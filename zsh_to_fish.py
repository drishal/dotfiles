import os
import re


def zsh_to_fish(cmd):
    return (cmd.replace('&&', '; and ')
               .replace('||', '; or '))


def is_valid_fish(cmd):
    for reg in r'^\S+=', r'\$\(', r'\[ ', r'`', r'\\$':
        if re.match(reg, cmd):
            return False
    return True


with open(os.path.expanduser('~/.local/share/fish/fish_history'), 'a') as o:
    with open(os.path.expanduser('~/.zsh_history')) as f:
        for line in f:
            line = line.strip()
            if line and re.match('^:\s+\d+:\d;', line):
                meta, command = line.split(';', 1)
                command = zsh_to_fish(command)
                if is_valid_fish(command):
                    time = meta.split(':')[1].strip()
                    print('Add', command)
                    o.write('- cmd: %s\n   when: %s\n' % (command, time))
