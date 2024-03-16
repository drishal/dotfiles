/* See LICENSE file for copyright and license details. */

/* appearance */
static const unsigned int borderpx  = 1;        /* border pixel of windows */
static const unsigned int gappx     = 8;        /* gaps between windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const unsigned int systraypinning = 0;   /* 0: sloppy systray follows selected monitor, >0: pin systray to monitor X */
static const unsigned int systrayonleft = 0;   	/* 0: systray in the right corner, >0: systray on left of status text */
static const unsigned int systrayspacing = 2;   /* systray spacing */
static const int systraypinningfailfirst = 1;   /* 1: if pinning fails, display systray on the first monitor, False: display systray on the last monitor*/
static const int showsystray        = 1;     /* 0 means no systray */
static const int showbar            = 1;     /* 0 means no bar */
static const int topbar             = 1;     /* 0 means bottom bar */
static const char col_gray1[]       = "#222222";
static const char col_gray2[]       = "#444444";
static const char col_gray3[]       = "#bbbbbb";
static const char col_gray4[]       = "#eeeeee";
static const char *fonts[]          = { "FantasqueSansM Nerd Font:size=12", "Noto Color Emoji:size=9:antialias=true:autohint=true"};
static const char dmenufont[]       = "FantasqueSansM Nerd Font:size=12";
/* static const char col_cyan[]        = "#005577"; */

// dracula
/*
static const char col_gray1[]       = "#282a36";
static const char col_gray2[]       = "#282a36";
static const char col_gray3[]       = "#f8f8f2";
static const char col_gray4[]       = "#282a36";
static const char col_gray5[]       = "#bd93f9";
static const char col_cyan[]        = "#bd93f9";
*/

//onedark
static const char col_bg[]          = "#282a36"; 
static const char col_bg2[]         = "#44475a"; 
static const char col_fg[]          = "#f8f8f2"; 
static const char col_grey[]         = "#6272a4"; 
static const char col_cyan[]          = "#8be9fd"; 
static const char col_green2[]         = "#50fa7b"; 
static const char col_orange[]          = "#ffb86c"; 
static const char col_pink[]         = "#ff79c6"; 
static const char col_purple[]          = "#bd93f9"; 
static const char col_red[]         = "#ff5555"; 
static const char col_yellow[]         =  "#f1fa8c";



//Palenight
/*
static const char col_gray1[]       = ""; 
static const char col_gray2[]       = ""; 
static const char col_gray3[]       = ""; 
static const char col_gray4[]       = ""; 
static const char col_gray5[]       = ""; 
static const char col_cyan[]        = ""; 
*/
static const char *colors[][3]      = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_fg, col_bg, col_bg },
	[SchemeSel]  = { col_fg, col_grey,  col_purple},
	[SchemeTitle]  = { col_purple, col_bg,  col_purple},
};


/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class      instance    title       tags mask     isfloating   monitor */
	/* { "Gimp",     NULL,       NULL,       0,            1,           -1 }, */
	/* { "Firefox",  NULL,       NULL,       1 << 8,       0,           -1 }, */
	{ "zoom",     NULL,       NULL,       0,            1,           -1 },
};

/* layout(s) */
static const float mfact     = 0.50; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 1;    /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default */
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_bg, "-nf", col_fg, "-sb", col_purple, "-sf", col_bg, NULL };
static const char *termcmd[]  = { "alacritty", NULL };
static const char *roficmd[]  = { "rofi", "-show", "drun","-icon-theme"," Papirus", "-show-icons" ,NULL };
static const char *nmcmd[]  = { "nmcli-rofi", NULL };
static const char *powercmd[]  = { "rofi", "-show", "power-menu", "-modi", "power-menu:~/Desktop/rofis/rofi-power-menu/rofi-power-menu", NULL };
static const char *mysystray[]  = {"stalonetray",NULL};
static const char *files[]  = {"nemo",NULL};
static const char *browser[]  = {"firefox",NULL};
//static const char *deadd[]  = {"bash","/home/drishal/dotfiles/config/suckless/dwm-6.2/deadd.sh",NULL};
static const char *menu[]  = {"bash","/home/drishal/menu.sh",NULL};
static const char *emacs[]  = {"emacsclient", "-c",NULL};
static const char *pavucontrol[]  = {"pavucontrol",NULL};
static const char *screenshot[]  = {"spectacle",NULL};
static const char *lock[]  = {"slock",NULL};


static const Key keys[] = {
	/* modifier                     key        function        argument */
        // Applications
        { MODKEY,                       XK_d,      spawn,          {.v = roficmd } },
	{ MODKEY,                       XK_s,      spawn,           {.v = screenshot} },
	{ MODKEY,                       XK_a,      spawn,      {.v = emacs} },
	{ MODKEY,                       XK_v,      spawn,      {.v = pavucontrol} },
        { MODKEY,                       XK_e,      spawn,      {.v = files} },
	{ MODKEY,                       XK_r,      spawn,      {.v = dmenucmd} },
	{ MODKEY,                       XK_Return, spawn,          {.v = termcmd } },
	{ MODKEY|ShiftMask,             XK_l,      spawn,      {.v = lock}},
	// { MODKEY,                       XK_p,      spawn,          {.v = powercmd } },
	{ MODKEY|ShiftMask,             XK_f,      spawn,      {.v = browser }},

	{ MODKEY,                       XK_b,      togglebar,      {0} },

	// stack commands
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },

	// master commands
	{ MODKEY,                       XK_bracketleft,      incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_bracketright,      incnmaster,     {.i = -1 } },

	// resize 
	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
	/* { MODKEY,                       XK_Return, zoom,           {0} }, */
	{ MODKEY,                       XK_Tab,    view,           {0} },
	{ MODKEY,                       XK_q,      killclient,     {0} },
	{ MODKEY,                       XK_i,      setlayout,      {.v = &layouts[0]} },
	{ MODKEY,                       XK_o,      setlayout,      {.v = &layouts[1]} },
	{ MODKEY,                       XK_p,      setlayout,      {.v = &layouts[2]} },

	//rotate stack
	{ MODKEY|ShiftMask,             XK_j,      rotatestack,    {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_k,      rotatestack,    {.i = -1 } },

	// resetting layouts
	/* https://www.reddit.com/r/suckless/comments/s2ch3f/comment/hsep6mg/?utm_source=share&utm_medium=web2x&context=3 */
	// { MODKEY|ShiftMask,             XK_m,      reset,    {0} },
	{ MODKEY|ShiftMask,             XK_m,      resetlayout,    {0} },

	// layouts
	{ MODKEY,                       XK_space,  setlayout,      {0} },
	{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },
	{ MODKEY,                       XK_f,      togglefullscr,  {0} },
	/* { MODKEY,                       XK_0,      view,           {.ui = ~0 } }, */
	/* { MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } }, */
	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },
	{ MODKEY,                       XK_minus,  setgaps,        {.i = -1 } },
	{ MODKEY,                       XK_equal,  setgaps,        {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_equal,  setgaps,        {.i = 0  } },
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
	{ MODKEY|ShiftMask,             XK_q,      quit,           {0} },

};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};

