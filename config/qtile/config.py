from typing import List  # noqa: F401
import os
import subprocess
from libqtile import bar, layout, widget
from libqtile.config import Click, Drag, Group, Key, Screen, Match
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
from libqtile import hook

mod = "mod4"
terminal = "kitty"

keys = [
    Key([mod], "h", lazy.layout.left()),
    Key([mod], "l", lazy.layout.right()),
    Key([mod], "j", lazy.layout.down()),
    Key([mod], "k", lazy.layout.up()),
    Key([mod, "shift"], "h", lazy.layout.swap_left()),
    Key([mod, "shift"], "l", lazy.layout.swap_right()),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down()),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up()),
    Key([mod, "control"], "j", lazy.layout.grow_down()),
    Key([mod, "control"], "k", lazy.layout.grow_up()),
    Key([mod, "control"], "h", lazy.layout.grow_left(), lazy.layout.decrease_ratio()),
    Key([mod, "control"], "l", lazy.layout.grow_right(),lazy.layout.increase_ratio()),
    # Key([mod], "i", lazy.layout.decrease_ratio()),
    # Key([mod], "m", lazy.layout.increase_ratio()),
    Key([mod], "n", lazy.layout.reset()),
    Key([mod], "o", lazy.layout.maximize()),
    # Key([mod, "shift"], "space", lazy.layout.flip()),
    # Switch from float to tile
    Key( [mod, "shift"], "space", lazy.window.toggle_floating(), desc='tile/float a window'),


    # Switch window focus to other pane(s) of stack
    Key([mod], "space", lazy.layout.next(),
        desc="Switch window focus to other pane(s) of stack"),

    # Swap panes of split stack
    # Key([mod, "shift"], "space", lazy.layout.rotate(),
    #    desc="Swap panes of split stack"),

    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key([mod, "shift"], "Return", lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack"),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    # some programs
    Key([mod, "shift"], "f", lazy.spawn("firefox"), desc="Firefox"),
    Key([mod], "a", lazy.spawn("emacsclient -c"), desc="Emacs"),
    # run
    Key([mod], "d", lazy.spawn("rofi -show drun -icon-theme Papirus -show-icons"), desc="Firefox"),
    Key([mod], "p", lazy.spawn("rofi -show powermenu -modi powermenu:~/Desktop/rofis/rofi-power-menu/rofi-power-menu"), desc="Emacs"),
    # thunar
    Key([mod], "e", lazy.spawn("thunar"), desc="file manager"),
    # Toggle between different layouts as defined below
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),

    Key([mod, "shift"], "r", lazy.restart(), desc="Restart qtile"),
    Key([mod, "shift"], "q", lazy.shutdown(), desc="Shutdown qtile"),
    Key([mod], "r", lazy.spawncmd(),
        desc="Spawn a command using a prompt widget"),
]

mouse = [
    Drag([mod], "Button1", lazy.window.set_position_floating(),
         start=lazy.window.get_position()),
    Drag([mod,"shift"], "Button1", lazy.window.set_size_floating(),
         start=lazy.window.get_size()),
    # Click([mod], "Button2", lazy.window.bring_to_front())
]

groups = [Group(i) for i in "123456789"]

for i in groups:
    keys.extend([
        # mod1 + letter of group = switch to group
        Key([mod], i.name, lazy.group[i.name].toscreen(toggle=False),
            desc="Switch to group {}".format(i.name)),

        # mod1 + shift + letter of group = switch to & move focused window to group
        Key([mod, "shift"], i.name, lazy.window.togroup(i.name, switch_group=False),
            desc="Switch to & move focused window to group {}".format(i.name)),
        # Or, use below if you prefer not to switch to that group.
        # # mod1 + shift + letter of group = move focused window to group
        # Key([mod, "shift"], i.name, lazy.window.togroup(i.name),
        #     desc="move focused window to group {}".format(i.name)),
    ])

layouts = [
    layout.Tile(
        ratio_increment = 0.05,
        ratio=0.5,
        margin = 10,
        border_focus = "#bd93f9",
        border_normal = "#44475a",
        border_width = 1
    ),
    layout.Floating(
        border_focus = "#bd93f9",
        border_normal = "#44475a",
        border_width = 1
    ),
    # layout.Max()
    # layout.Stack(num_stacks=2),
    # Try more layouts by unleashing below layouts.
    # layout.Bsp(margin = 10,
    #     border_focus = "#bd93f9",
    #     border_normal = "#44475a",
    #     border_width = 1),
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
    font='FiraCode Nerd Font',
    fontsize=11,
    padding=2,
    background="#282a36",
    foreground= "#282a36",
)
extension_defaults = widget_defaults.copy()

screens = [
    Screen(
        top=bar.Bar(
            [
                widget.CurrentLayout(
                    # foreground = "#282a36",
                    foreground="#50fa7b",
                    # background="",
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
                    rounded = True,
                    highlight_color = ["#44475a"] ,
                    highlight_method = "line",
                    this_current_screen_border = "#6272a4",
                    # this_current_screen_border = colors[3],
                    # this_screen_border = #bd93f9,
                    # other_current_screen_border = colors[0],
                    # other_screen_border = colors[0],
                    foreground = "#f8f8f2",
                    background = "#282a36",
                    disable_drag = True
                    # padding = 5

                ),
                widget.Prompt(
                    background="#44475a",
                    foreground="#f8f8f2",
                    record_history = True
                ),
                widget.WindowName(
                    max_chars = 50,
                    padding= 5,
                    # foreground = "f8f8f8",
                    # background="#6272a4",
                     foreground="#ff79c6",
                    # foreground="#f8f8f2"
                    # background="#bd93f9",
                ),

                 widget.Clock(format='   %Y-%m-%d %a %I:%M:%S %p ',
                             foreground="#bd93f9",
                             # foreground="#282a36",
                             ),
                widget.Spacer(
                    length = bar.STRETCH,
                ),
                widget.Chord(
                    chords_colors={
                        'launch': ("#ff0000", "#ffffff"),
                    },
                    name_transform=lambda name: name.upper(),
                ),

                widget.CPU(
                    #background="#f1fa8c",
                    foreground="#50fa7b",
                    format='   {freq_current}GHz {load_percent}% ',
                ),
                widget.TextBox(
                    text = '',
                    foreground = "#6272a4",
                    fontsize = 15
                ),

                widget.Memory(
                    #background="#8be9fd",
                    foreground="#ffb86c",
                    format='   {MemUsed: .0f}M /{MemTotal: .0f}M ',
                ),
                widget.TextBox(
                    text = '',
                    foreground = "#6272a4",
                    fontsize = 15
                ),
                widget.Net(
                    format=' {down}  {up} ',
                    foreground="#ff79c6"
                ),
                widget.TextBox(
                    text = ' ', # this one has a small space after the symbol to make it look more consistent with the spaces
                    foreground = "#6272a4",
                    fontsize = 15
                ),
                # widget.TextBox(text="◤", fontsize=45, padding=-1, foreground="#bd9359",background="#bd93f9"),


                widget.Systray(),
            ],
            21,
        ),
    ),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: List
follow_mouse_focus = True
bring_front_click = False
cursor_warp = False
auto_fullscreen = True
focus_on_window_activation = "focus"
reconfigure_screens = True

floating_layout = layout.Floating(border_focus = "#bd93f9", border_normal = "#44475a",
float_rules=[
    *layout.Floating.default_float_rules,
    Match(wm_class='confirmreset'),  # gitk
    Match(wm_class='makebranch'),  # gitk
    Match(wm_class='maketag'),  # gitk
    Match(wm_class='ssh-askpass'),  # ssh-askpass
    # Match(title='About Mozilla Firefox'),  # ssh-askpass
    Match(title='branchdialog'),  # gitk
    Match(title='pinentry'),  # GPG key password entry
]

)

auto_minimize = False
@hook.subscribe.startup_once
def autostart():
    os.system("bash ~/.config/qtile/autostart.sh")