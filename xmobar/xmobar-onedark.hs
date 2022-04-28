Config { 

   -- appearance
   -- font =         "xft:FiraCode Nerd Font:size=10:antialias=true:autohinting=true:Regular"
   font =         "xft:FantasqueSansMono Nerd Font:size=12:antialias=true:autohinting=true:Regular"

    --font =         "xft:cozette:size=11:antialias=true:autohinting=true:Regular"
   , additionalFonts =           ["xft:PowerlineSymbols:size=10"]
   --, bgColor =      "#282c34"
   , bgColor =      "#282c34"
   , fgColor =      "#bbc2cf"
   , position =   Top,
   --, alpha = 175
   --, border =       BottomB
   , borderColor =  "#646464"
   -- }{ %battery%  %multicpu% | %memory% %dynnetwork% | %date%
   -- layout
   , sepChar =  "%"   -- delineator between plugin names and straight text
   , alignSep = "}{"  -- separator between left-right alignment
    , template = "<fc=#98be65> </fc> %XMonadLog% } %date%  { %battery%<fc=#5B6268></fc>%dynnetwork% <fc=#5B6268></fc> %multicpu% <fc=#5B6268></fc> %memory% <fc=#5B6268></fc> %trayerpad%"
   -- general behavior
   -- , allDesktops =      True    -- show on all desktops
   -- , pickBroadest =     False   -- choose widest display (multi-monitor)
   , persistent =       True    -- enable/disable hiding (True = disabled)
   , hideOnStart =      False   -- start with window unmapped (hidden)
   , overrideRedirect = True-- set the Override Redirect flag (Xlib)
   , lowerOnStart =     True    -- send to bottom of window stack on start
   , commands = 
     -- network activity monitor (dynamic interface resolution)
        [
    -- weather monitor
    --    Run Weather "VICG" [ "--template", "<skyCondition> | <fc=#4682B4><tempC></fc>°C | <fc=#4682B4><rh></fc>% | <fc=#4682B4><pressure></fc>hPa"
    --                         ] 100
     Run DynNetwork     [ "--template" , "<fc=#5B6268></fc> <fc=#da8548> <rx>kB/s  <tx>kB/s </fc>"
                              , "--Low"      , "1000"       -- units: B/s
                             , "--High"     , "5000"       -- units: B/s
                             ] 50
                
        --battery monitor
     ,Run Battery        [ "--template" , "<fc=#98be65> <left>%, <timeleft> </fc>"
                           , "--Low"      , "10"        -- units: %
                             , "--High"     , "80"        -- units: %
                             ] 100

         -- cpu activity monitor
     , Run MultiCpu       [ "--template" , "<fc=#46d9ff> <total>% </fc>"
                             , "--Low"      , "50"         -- units: %
                             , "--High"     , "85"         -- units: %
                             ] 20
               -- memory usage monitor
        , Run Memory         [ "--template" ,"<fc=#c678dd>  <used>M/<total>M </fc>"
                             , "--Low"      , "1000"        -- units: M
                             , "--High"     , "6000"        -- units: M

                             ] 50

        , Run Com "/home/drishal/dotfiles/trayer-padding-icon.sh" [] "trayerpad" 20
        -- time and date indicator 
        --   (%F = d-m-y date, %a = day of week, %T = h:m:s time)
        , Run Date           "<fc=#a9a1e1>  %F (%a) %T</fc>" "date" 10
      
        , Run Com "uname" ["-r"] "" 3600
        , Run Com "bash /home/drishal/Desktop/suckless/scripts/dwm_battery.sh" [] "batt" 10
      --, Run Com "acpi" [] "batt" 10

        ,  Run UnsafeStdinReader
        , Run XMonadLog
        ]
   }
