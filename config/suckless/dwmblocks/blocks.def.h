//Modify this file to change what commands output to your statusbar, and recompile using the make command.
static const Block blocks[] = {
	/*Icon*/	/*Command*/		/*Update Interval*/	/*Update Signal*/	
	/*{"", "scripts/dwm_weather.sh",					1000,		0},*/	
	{"", "bash /home/drishal/dotfiles/config/suckless/dwmblocks/scripts/dwm_battery.sh ",					1,		0},
	{"  ", "bash /home/drishal/dotfiles/config/suckless/dwmblocks/scripts/cpu.sh",                            1,          0},
	{"  ", "free -h | awk '/^Mem/ { print $3\"/\"$2 }' | sed s/i//g",	5,		0},
	{"  ", "date '+%b %d %Y %a %H:%M:%S'",					1,		0},
};

//sets delimeter between status commands. NULL character ('\0') means no delimeter.
static char delim[] = "    ";
static unsigned int delimLen = 100;
