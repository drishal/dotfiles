from typing import List  # noqa: F401
import os
from libqtile import bar, layout, widget
from libqtile.config import Click, Drag, Group, Key, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
from libqtile import hook
#import psutil
mod = "mod4"
terminal = "alacritty"

keys = [
    # Switch between windows in current stack pane
    Key([mod], "k", lazy.layout.down(),
        desc="Move focus down in stack pane"),
    Key([mod], "j", lazy.layout.up(),
        desc="Move focus up in stack pane"),
    # Switch from float to tile
    Key( [mod, "shift"], "space", lazy.window.toggle_floating(), desc='Make window floating.'),

    # Move windows up or down in current stack
    Key([mod, "control"], "k", lazy.layout.shuffle_down(),
        desc="Move window down in current stack "),
    Key([mod, "control"], "j", lazy.layout.shuffle_up(),
        desc="Move window up in current stack "),

    # Switch window focus to other pane(s) of stack
    Key([mod], "space", lazy.layout.next(),
        desc="Switch window focus to other pane(s) of stack"),

    # Swap panes of split stack
    #Key([mod, "shift"], "space", lazy.layout.rotate(),
    #    desc="Swap panes of split stack"),

    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key([mod, "shift"], "Return", lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack"),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    #some programs
    Key([mod, "shift"], "f", lazy.spawn("firefox"), desc="Firefox"),
    Key([mod], "a", lazy.spawn("emacsclient -c"), desc="Emacs"),
    #run
     Key([mod], "d", lazy.spawn("rofi -show drun -icon-theme Papirus -show-icons"), desc="Firefox"),
    Key([mod], "p", lazy.spawn("rofi -show powermenu -modi powermenu:~/Desktop/rofis/rofi-power-menu/rofi-power-menu"), desc="Emacs"),

    # Toggle between different layouts as defined below
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),

    Key([mod, "shift"], "r", lazy.restart(), desc="Restart qtile"),
    Key([mod, "shift"], "q", lazy.shutdown(), desc="Shutdown qtile"),
    Key([mod], "r", lazy.spawncmd(),
        desc="Spawn a command using a prompt widget"),
]

groups = [Group(i) for i in "123456789"]

for i in groups:
    keys.extend([
        # mod1 + letter of group = switch to group
        Key([mod], i.name, lazy.group[i.name].toscreen(),
            desc="Switch to group {}".format(i.name)),

        # mod1 + shift + letter of group = switch to & move focused window to group
        Key([mod, "shift"], i.name, lazy.window.togroup(i.name, switch_group=True),
            desc="Switch to & move focused window to group {}".format(i.name)),
        # Or, use below if you prefer not to switch to that group.
        # # mod1 + shift + letter of group = move focused window to group
        # Key([mod, "shift"], i.name, lazy.window.togroup(i.name),
        #     desc="move focused window to group {}".format(i.name)),
    ])

layouts = [
    layout.Tile(
        ratio=0.5,
        margin = 10
    ),
    # layout.Stack(num_stacks=2),
    # Try more layouts by unleashing below layouts.
    # layout.Bsp(),
    # layout.Columns(),
    # layout.Matrix(),
    # layout.MonadTall(),
    # layout.MonadWide(),
    # layout.RatioTile(),
    # layout.Tile(),
    # layout.TreeTab(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
]

widget_defaults = dict(
    font='Hack Nerd Font',
    fontsize=12,
    padding=3,
    background="#282a36",
    foreground= "#f8f8f2",
)
extension_defaults = widget_defaults.copy()
'''
screens = [
              ]

#top.show(False)
'''

screens = [
    Screen(
        top=bar.Bar(
            [
                widget.CurrentLayout(
                    foreground="#50fa7b",
                ),
                widget.GroupBox(
                       fontsize = 9,
                       margin_y = 3,
                       margin_x = 3,
                       padding_y = 5,
                       padding_x = 5,
                       borderwidth = 3,
                       active = "#f8f8f2",
                       inactive = "#6272a4",
                       rounded = False,
                       highlight_color = "#44475a" ,
                       highlight_method = "line",
                       #this_current_screen_border = colors[3],
                       #this_screen_border = colors [4],
                       #other_current_screen_border = colors[0],
                       #other_screen_border = colors[0],
                       foreground = "#f8f8f2",
                       background = "#282a36",
                       #padding = 5

                ),
                widget.Prompt(),
                widget.WindowName(
                     foreground="#ff79c6",
                ),
                widget.Chord(
                    chords_colors={
                        'launch': ("#ff0000", "#ffffff"),
                    },
                    name_transform=lambda name: name.upper(),
                ),

                widget.CPU(
                    foreground="#f1fa8c",
                    format='  {freq_current}GHz {load_percent}%',
                ),
                 widget.TextBox(
                       text = '  ',
                       padding = 3,
                       fontsize = 16,
                       ),
                widget.Memory(
                    foreground="#8be9fd",
                    format='  {MemUsed}M/{MemTotal}M',
                ),
                 widget.TextBox(
                       text = '  ',
                       padding = 3,
                       fontsize = 16,
                       ),
                widget.Net(
                    format='{interface}: {down}  {up}',
                    foreground="#ff79c6"
                ),
                 widget.TextBox(
                       text = '  ',
                       padding = 3,
                       fontsize = 16,
                       ),
                widget.Clock(format='  %Y-%m-%d %a %I:%M %p',
                             foreground="#bd93f9"),
                 widget.TextBox(
                       text = '  ',
                       padding = 3,
                       fontsize = 16,
                       ),


                widget.Systray(),
            ],
            24,
        ),
    ),
]

# Drag floating layouts.
mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(),
         start=lazy.window.get_position()),
    Drag([mod,"shift"], "Button1", lazy.window.set_size_floating(),
         start=lazy.window.get_size()),
    Click([mod], "Button2", lazy.window.bring_to_front())
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: List
main = None  # WARNING: this is deprecated and will be removed soon
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False


'''
floating_layout = layout.Floating(float_rules=[
    # Run the utility of `xprop` to see the wm class and name of an X client.
    {'wmclass': 'confirm'},
    {'wmclass': 'dialog'},
    {'wmclass': 'download'},
    {'wmclass': 'error'},
    {'wmclass': 'file_progress'},
    {'wmclass': 'notification'},
    {'wmclass': 'splash'},
    {'wmclass': 'toolbar'},
    {'wmclass': 'confirmreset'},  # gitk
    {'wmclass': 'makebranch'},  # gitk
    {'wmclass': 'maketag'},  # gitk
    {'wname': 'branchdialog'},  # gitk
    {'wname': 'pinentry'},  # GPG key password entry
    {'wmclass': 'ssh-askpass'},  # ssh-askpass
])
'''
'''
floating_layout = layout.Floating(float_rules=[
    {'wmclass': 'confirm'},
    {'wmclass': 'dialog'},
    {'wmclass': 'download'},
    {'wmclass': 'error'},
    {'wmclass': 'file_progress'},
    {'wmclass': 'notification'},
    {'wmclass': 'splash'},
    {'wmclass': 'toolbar'},
    {'wmclass': 'confirmreset'},
    {'wmclass': 'makebranch'},
    {'wmclass': 'maketag'},
    {'wmclass': 'Arandr'},
    {'wmclass': 'feh'},
    {'wmclass': 'Galculator'},
    {'wmclass': 'Oblogout'},
    {'wname': 'branchdialog'},
    {'wname': 'Open File'},
    {'wname': 'pinentry'},
    {'wmclass': 'ssh-askpass'},

])
'''
auto_fullscreen = True
focus_on_window_activation = "smart"

@hook.subscribe.client_new
def set_floating(window):
    normal_hints = window.window.get_wm_normal_hints()
    if normal_hints and normal_hints["max_width"]:
        window.floating = True

# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
os.system("bash ~/.config/qtile/autostart.sh")
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
wmname = "LG3D"
