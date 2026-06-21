//Modify this file to change what commands output to your statusbar, and recompile using the make command.
static const Block blocks[] = {
	/*Icon*/	/*Command*/		/*Update Interval*/	/*Update Signal*/	
	/*{"", "scripts/dwm_weather.sh",					1000,		0},*/	
	{"", "bash /home/drishal/dotfiles/suckless/dwmblocks/scripts/dwm_battery.sh ",					1,		0},
	{"", "bash /home/drishal/dotfiles/suckless/dwmblocks/scripts/sb-internet",                            1,          0},
	{"", "bash /home/drishal/dotfiles/suckless/dwmblocks/scripts/cpu.sh",                            1,          0},
	{"", "bash /home/drishal/dotfiles/suckless/dwmblocks/scripts/memory.sh",	5,		0},
	{"", "bash /home/drishal/dotfiles/suckless/dwmblocks/scripts/dwm_date.sh",					1,		0},
};

//sets delimeter between status commands. NULL character ('\0') means no delimeter.
static char delim[] = "^c#5B6268^  ";
static unsigned int delimLen = 100;
#define CMDLENGTH		10000

