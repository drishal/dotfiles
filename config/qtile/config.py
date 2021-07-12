from typing import List  # noqa: F401
import os
import subprocess
from libqtile import bar, layout, widget
from libqtile.config import Click, Drag, Group, Key, Screen, Match, KeyChord
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
from libqtile import hook

mod = "mod4"
terminal = "kitty"

dracula = [
   "#282a36",  # 0  Background
   "#44475a",  # 1  current line/lighter_black
   "#f8f8f2",  # 2  foreground
   "#6272a4",  # 3  comment/dark_grey
   "#8be9fd",  # 4  cyan
   "#50fa7b",  # 5  green
   "#ffb86c",  # 6  orange 
   "#ff79c6",  # 7  pink    
   "#bd93f9",  # 8  purple
   "#ff5555",  # 9  red
   "#f1fa8c",  # 10 yellow 
]

onedark = [
   "#282c34", # 0 background
   "#3f444a", # 1 bg-alt
   "#bbc2cf", # 2 foreground
   "#5B6268", # 3 dark grey / comments
   "#46d9ff", # 4 cyan
   "#98be65", # 5 green 
   "#da8548", # 6 orange 
   "#c678dd", # 7 magenta
   "#a9a1e1", # 8 violet
   "#ff6c6b", # 9 red 
   "#ecbe7b", # 10 yellow 
      ]

palenight = [
  "#292D3E", # 0 background
  "#242837", # 1 bg-alt
  "#EEFFFF", # 2 foreground
  "#676E95", # 3 dark grey / comments
  "#80cbc4", # 4 cyan
  "#c3e88d", # 5 green 
  "#f78c6c", # 6 orange 
  "#c792ea", # 7 magenta
  "#bb80b3", # 8 violet
  "#ff5370", # 9 red 
  "#ffcb6b", # 10 yellow 
     ]

gruvbox = [
  "#282828", # 0 background
  "#0d1011", # 1 bg-alt
  "#ebdbb2", # 2 foreground
  "#928374", # 3 dark grey / comments
  "#689d6a", # 4 cyan
  "#b8bb26", # 5 green 
  "#fe8019", # 6 orange 
  "#cc241d", # 7 magenta
  "#d3869b", # 8 violet
  "#fb4934", # 9 red 
  "#fabd2f", # 10 yellow 
     ]

nord = [
   "#2E3440",  # 0  Background
   "#434C5E",  # 1  current line/lighter_black
   "#ECEFF4",  # 2  foreground
   "#434C5E",  # 3  comment/dark_grey
   "#88C0D0",  # 4  cyan
   "#A3BE8C",  # 5  green
   "#D08770",  # 6  orange 
   "#B48EAD",  # 7  magenta 
   "#5D80AE",  # 8  violet
   "#BF616A",  # 9  red
   "#EBCB8B",  # 10 yellow 
]

color = dracula

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
    # Key([mod, "shift"], "Return", lazy.layout.toggle_split(),
    #     desc="Toggle between split and unsplit sides of stack"),

    # # terminal
    # Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    # # some programs
    # Key([mod, "shift"], "f", lazy.spawn("firefox"), desc="Firefox"),
    # Key([mod], "a", lazy.spawn("emacsclient -c"), desc="Emacs"),
    # # pavucontrol
    # Key([mod], "v", lazy.spawn("pavucontrol"), desc="pavucontrol"),
    # # run
    # Key([mod], "d", lazy.spawn("rofi -show drun -icon-theme Papirus -show-icons"), desc="Firefox"),
    # Key([mod], "p", lazy.spawn("rofi -show powermenu -modi powermenu:~/Desktop/rofis/rofi-power-menu/rofi-power-menu"), desc="Emacs"),
    # # thunar
    # Key([mod], "e", lazy.spawn("thunar"), desc="file manager"),


    # # Toggle between different layouts as defined below

    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),

    Key([mod, "shift"], "r", lazy.restart(), desc="Restart qtile"),
    Key([mod, "shift"], "q", lazy.shutdown(), desc="Shutdown qtile"),
    Key([mod], "r", lazy.spawncmd(),
        desc="Spawn a command using a prompt widget"),

    KeyChord([mod], "z", [
      Key([], "x", lazy.spawn("emacsclient -c"))
  ])

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
        border_focus = color[8],
        border_normal = color[1],
        border_width = 1
    ),
    layout.Floating(
        border_focus = color[8],
        border_normal = color[1],
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
    fontsize=12,
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
                    # foreground = color[0],
                    fmt = ' {}',
                    foreground=color[6],
                    # background="",
                ),

                widget.GroupBox(
                    fontsize = 9,
                    margin_y = 3,
                    margin_x = 3,
                    padding_y = 5,
                    padding_x = 5,
                    borderwidth = 3,
                    active = color[2],
                    inactive = color[3],
                    rounded = True,
                    highlight_color = [color[1]] ,
                    highlight_method = "line",
                    this_current_screen_border = color[3],
                    # this_current_screen_border = colors[3],
                    # this_screen_border = #bd93f9,
                    # other_current_screen_border = colors[0],
                    # other_screen_border = colors[0],
                    foreground = color[2],
                    background = color[0],
                    disable_drag = True
                    # padding = 5

                ),
                widget.Prompt(
                    background=color[1],
                    foreground=color[2],
                    record_history = True
                ),
                widget.WindowName(
                    max_chars = 50,
                    padding= 5,
                    # foreground = "f8f8f8",
                    # background=color[3],
                     foreground=color[7],
                    # foreground=color[2]
                    # background=color[8],
                ),

                 widget.Clock(format='   %Y-%m-%d %a %H:%M:%S',
                              foreground=color[8],
                              # foreground=color[0],
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
              widget.Battery(
                  format='{char} {percent:2.0%} {hour:d}:{min:02d} {watt:.2f} W',
                  update_interval=10,
                  foreground=color[5],
              ),
                widget.TextBox(
                    text = '  ', # this one has a small space after the symbol to make it look more consistent with the spaces
                    foreground = color[3],
                    fontsize = 15
                ),
                # widget.TextBox(text="◤", fontsize=45, padding=-1, foreground="#bd9359",background=color[8]),

                widget.CPU(
                    #background=color[10],
                    foreground=color[4],
                    format='   {freq_current}GHz {load_percent}% ',
                ),
                widget.TextBox(
                    text = '',
                    foreground = color[3],
                    fontsize = 15
                ),

                widget.Memory(
                    #background=color[4],
                    foreground=color[10],
                    format='   {MemUsed: .0f}M /{MemTotal: .0f}M ',
                ),
                widget.TextBox(
                    text = '',
                    foreground = color[3],
                    fontsize = 15
                ),
                widget.Net(
                    format=' {down}  {up} ',
                    foreground=color[7]
                ),
                widget.TextBox(
                    text = '  ', # this one has a small space after the symbol to make it look more consistent with the spaces
                    foreground = color[3],
                    fontsize = 15
                ),

                # widget.BatteryIcon(),


                widget.Systray(padding=5,),
                widget.TextBox(
                    text = ' ', # this one has a small space after the symbol to make it look more consistent with the spaces
                    foreground = color[3],
                    fontsize = 15
                ),

            ],
            27,
            margin=[7, 10, 2, 10], # [N E S W] 
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
auto_minimize = False

floating_layout = layout.Floating(border_focus = color[8], border_normal = color[1],
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

@hook.subscribe.startup_once
def autostart():
    os.system("bash ~/.config/qtile/autostart.sh")
