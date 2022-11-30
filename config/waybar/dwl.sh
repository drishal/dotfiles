#!/bin/sh

set -e
echo '| 1!| 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |'
fname="/tmp/dwltags-$WAYLAND_DISPLAY";
while true
do
    #make sure the file exists
    while [ ! -f $fname ]
    do
        inotifywait -qqe create `dirname $fname`
    done;

    #wait for dwl to close it after writing
    inotifywait -qqe close_write $fname

    titleline=$1
    tagline=$((titleline+1))

    title=`sed "$titleline!d" $fname`
    taginfo=`sed "$tagline!d" $fname`

    isactive=`echo "$taginfo" | cut -d ' ' -f 1`

    ctags=`echo "$taginfo" | cut -d ' ' -f 2`

    mtags=`echo "$taginfo" | cut -d ' ' -f 3`

    layout=`echo "$taginfo" | cut -d ' ' -f 4-`

    for i in {0..8};
    do

        mask=$((1<<i))
        if (( "$ctags" & $mask ));
        then
            n="*$((i+1))"
        else
            n=" $((i+1))"
        fi
        if (( "$mtags" & $mask ));
        then
            echo -n "|$n!"
        else
            echo -n "|$n "
        fi
    done
    echo "| $layout $title"


done
