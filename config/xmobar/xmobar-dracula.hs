Config { 

   -- appearance
    font =         "xft:FiraCode Nerd Font:size=10:antialias=true:autohinting=true:Regular"

    --font =         "xft:cozette:size=11:antialias=true:autohinting=true:Regular"
   , additionalFonts =           ["xft:PowerlineSymbols:size=10"]
   --, bgColor =      "#282a36"
   , bgColor =      "#282a36"
   , fgColor =      "#f8f8f2"
   , position =   Top,
   --, alpha = 175
   --, border =       BottomB
   , borderColor =  "#646464"
   -- }{ %battery%  %multicpu% | %memory% %dynnetwork% | %date%
   -- layout
   , sepChar =  "%"   -- delineator between plugin names and straight text
   , alignSep = "}{"  -- separator between left-right alignment
    , template = "<fc=#50fa7b> </fc> %XMonadLog% } %date%  { %battery%<fc=#6272a4></fc>%dynnetwork% <fc=#6272a4></fc> %multicpu% <fc=#6272a4></fc> %memory% <fc=#6272a4></fc> %trayerpad%"
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
     Run DynNetwork     [ "--template" , "<fc=#6272a4></fc> <fc=#ffb86c> <rx>kB/s  <tx>kB/s </fc>"
                              , "--Low"      , "1000"       -- units: B/s
                             , "--High"     , "5000"       -- units: B/s
                             --, "--low"      , "#00ff00"
                             --, "--normal"   , "#ffff00"
                             --, "--high"     , "#ff0000"
                             ] 50
                
        --battery monitor
     ,Run Battery        [ "--template" , "<fc=#50fa7b> <left>%, <timeleft> </fc>"
                           , "--Low"      , "10"        -- units: %
                             , "--High"     , "80"        -- units: %
                             ] 100

         -- cpu activity monitor
     , Run MultiCpu       [ "--template" , "<fc=#8be9fd> <total>% </fc>"
                             , "--Low"      , "50"         -- units: %
                             , "--High"     , "85"         -- units: %
                             --, "--low"      , "#00ff00"
                             --, "--normal"   , "#ffff00"
                             --, "--high"     , "#ff0000"
                             ] 20
               -- memory usage monitor
        , Run Memory         [ "--template" ,"<fc=#ff79c6>  <used>M/<total>M </fc>"
                             , "--Low"      , "1000"        -- units: M
                             , "--High"     , "6000"        -- units: M
                             --, "--low"      , "#00ff00"
                             --, "--normal"   , "#ffff00"
                             --, "--high"     , "#ff0000"

                             ] 50

        , Run Com "/home/drishal/dotfiles/trayer-padding-icon.sh" [] "trayerpad" 20
        -- time and date indicator 
        --   (%F = d-m-y date, %a = day of week, %T = h:m:s time)
        , Run Date           "<fc=#bd93f9>  %F (%a) %T</fc>" "date" 10
      
        , Run Com "uname" ["-r"] "" 3600
        , Run Com "bash /home/drishal/Desktop/suckless/scripts/dwm_battery.sh" [] "batt" 10
      --, Run Com "acpi" [] "batt" 10

        --, Run UnsafeStdinReader
        , Run XMonadLog
        ]
   }
