--
-- xmonad example config file.
--
-- A template showing all available configuration hooks,
-- and how to override the defaults in your own xmonad.hs conf file.
--
-- Normally, you'd only override those defaults you care about.
import XMonad
import Data.Monoid
import System.Exit
import qualified XMonad.StackSet as W
import qualified Data.Map        as M
import XMonad.Hooks.ManageDocks
import XMonad.Layout.NoBorders
import Control.Monad
import  Data.Maybe
import Data.List
  -- Base
import XMonad
import System.IO 
import System.Exit (exitSuccess)
import qualified XMonad.StackSet as W

    -- Actions
import XMonad.Actions.CopyWindow (kill1, killAllOtherCopies)
import XMonad.Actions.CycleWS (moveTo, shiftTo, WSType(..), nextScreen, prevScreen)
import XMonad.Actions.GridSelect
import XMonad.Actions.MouseResize
import XMonad.Actions.Promote
import XMonad.Actions.RotSlaves (rotSlavesDown, rotAllDown)
import qualified XMonad.Actions.TreeSelect as TS
import XMonad.Actions.WindowGo (runOrRaise)
import XMonad.Actions.WithAll (sinkAll, killAll)
import qualified XMonad.Actions.Search as S
import qualified DBus as D
import qualified DBus.Client as D
import qualified Codec.Binary.UTF8.String as UTF8
--import  XMonad.Actions.Navigation2D

    -- Data
import Data.Char (isSpace)
import Data.Monoid
import Data.Maybe (isJust)
import Data.Tree
import qualified Data.Map as M

    -- Hooks
import XMonad.Hooks.DynamicLog (dynamicLogWithPP, wrap, xmobarPP, xmobarColor,defaultPP ,shorten, PP(..))
import XMonad.Hooks.EwmhDesktops  -- for some fullscreen events, also for xcomposite in obs.
import XMonad.Hooks.FadeInactive
import XMonad.Hooks.ManageDocks 
import XMonad.Hooks.ManageHelpers 
import XMonad.Hooks.ServerMode
import XMonad.Hooks.SetWMName
import XMonad.Hooks.WorkspaceHistory
import XMonad.Hooks.Place
    -- Layouts
import XMonad.Layout.GridVariants (Grid(Grid))
import XMonad.Layout.SimplestFloat
import XMonad.Layout.Spiral
import XMonad.Layout.ResizableTile
import XMonad.Layout.Tabbed
import XMonad.Layout.ThreeColumns
import XMonad.Layout.BinarySpacePartition
import XMonad.Layout.SimpleFloat
--import XMonad.Layout.Fullscreen as FS
    -- Layouts modifiers
import XMonad.Layout.LayoutModifier
import XMonad.Layout.LimitWindows (limitWindows, increaseLimit, decreaseLimit)
import XMonad.Layout.Magnifier
import XMonad.Layout.MultiToggle (mkToggle, single, EOT(EOT), (??))
import XMonad.Layout.MultiToggle.Instances (StdTransformers(NBFULL, MIRROR, NOBORDERS))
import XMonad.Layout.NoBorders
import XMonad.Layout.Renamed (renamed, Rename(Replace))
import XMonad.Layout.ShowWName
import XMonad.Layout.Spacing
import XMonad.Layout.WindowArranger (windowArrange, WindowArrangerMsg(..))
import qualified XMonad.Layout.ToggleLayouts as T (toggleLayouts, ToggleLayout(Toggle))
import qualified XMonad.Layout.MultiToggle as MT (Toggle(..))

    -- Prompt
import XMonad.Prompt
import XMonad.Prompt.Input
import XMonad.Prompt.FuzzyMatch
import XMonad.Prompt.Man
import XMonad.Prompt.Pass
import XMonad.Prompt.Shell (shellPrompt)
import XMonad.Prompt.Ssh
import XMonad.Prompt.XMonad
import Control.Arrow (first)

    -- Utilities
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run (runProcessWithInput, safeSpawn, spawnPipe)
import XMonad.Util.SpawnOnce




-- The preferred terminal program, which is used in a binding below and by
-- certain contrib modules.
--
myTerminal      = "st"

-- Whether focus follows the mouse pointer.
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = True

-- Whether clicking on a window to focus also passes the click to the window
myClickJustFocuses :: Bool
myClickJustFocuses = False

-- Width of the window border in pixels.
--
myBorderWidth   = 1

-- modMask lets you specify which modkey you want to use. The default
-- is mod1Mask ("left alt").  You may also consider using mod3Mask
-- ("right alt"), which does not conflict with emacs keybindings. The
-- "windows key" is usually mod4Mask.
--
myModMask       = mod4Mask

-- The default number of workspaces (virtual screens) and their names.
-- By default we use numeric strings, but any string may be used as a
-- workspace name. The number of workspaces is determined by the length
-- of this list.
--
-- A tagging example:
--
-- > workspaces = ["web", "irc", "code" ] ++ map show [4..9]
--
myWorkspaces    = ["1","2","3","4","5","6","7","8","9"]

-- Border colors for unfocused and focused windows, respectively.
--
myNormalBorderColor  = "#dddddd"
myFocusedBorderColor = "#ff0000"

------------------------------------------------------------------------
-- Key bindings. Add, modify or remove key bindings here.
--
myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $

    -- launch a terminal
    [ ((modm,               xK_Return), spawn "alacritty")
     -- launch firefox
    ,((modm .|. shiftMask,             xK_f), spawn "firefox")
    --Emacs
     ,((modm,             xK_a), spawn "emacsclient -c")
     --Dmenu
     --,((modm,             xK_d), spawn "j4-dmenu-desktop")


    -- Rofi
    , ((modm,               xK_d  ), spawn "rofi -show drun -icon-theme Papirus -show-icons")
     -- dmenu2
    --, ((modm,               xK_d  ), spawn "i3-dmenu-desktop")
 
    --file manager
    , ((modm,               xK_e     ), spawn "dolphin")



    -- launch gmrun
    , ((modm,               xK_p     ), spawn "rofi -show powermenu -modi powermenu:~/Desktop/rofis/rofi-power-menu/rofi-power-menu")

    -- close focused window
    , ((modm ,              xK_q     ), kill)

     -- Rotate through the available layout algorithms
    , ((modm,               xK_space ), sendMessage NextLayout)

    --  Reset the layouts on the current workspace to default
    , ((modm .|. controlMask, xK_space ), setLayout $ XMonad.layoutHook conf)

    -- Resize viewed windows to the correct size
    , ((modm,               xK_n     ), refresh)

    -- Move focus to the next window
    , ((modm,               xK_Tab   ), windows W.focusDown)

    -- Move focus to the next window
    , ((modm,               xK_j     ), windows W.focusDown)

    -- Move focus to the previous window
    , ((modm,               xK_k     ), windows W.focusUp  )

    -- Move focus to the master window
    , ((modm,               xK_m     ), windows W.focusMaster  )

    -- Swap the focused window and the master window
    , ((modm .|. shiftMask,               xK_Return), windows W.swapMaster)

    -- Swap the focused window with the next window
    , ((modm .|. shiftMask, xK_j     ), windows W.swapDown  )

    -- Swap the focused window with the previous window
    , ((modm .|. shiftMask, xK_k     ), windows W.swapUp    )

    -- Shrink the master area
    , ((modm,               xK_h     ), sendMessage Shrink)

    -- Expand the master area
    , ((modm,               xK_l     ), sendMessage Expand)

    -- Push window back into tiling
    , ((modm .|. shiftMask, xK_space     ), withFocused $ windows . W.sink)
    --BSP
    , ((modm,               xK_Right ), sendMessage $ ExpandTowards R)
    , ((modm,               xK_Left  ), sendMessage $ ExpandTowards L)
    , ((modm,               xK_Down  ), sendMessage $ ExpandTowards D)
    , ((modm,               xK_Up    ), sendMessage $ ExpandTowards U)
    --, ((modm,               xK_r     ), sendMessage Rotate)
    , ((modm,               xK_s     ), sendMessage Swap)
    , ((modm,               xK_b     ), sendMessage FocusParent)
    , ((modm,               xK_n     ), sendMessage SelectNode)
    , ((modm,               xK_m     ), sendMessage MoveNode)
    , ((myModMask,               xK_z),     sendMessage Balance)
    , ((myModMask .|. shiftMask, xK_z),     sendMessage Equalize)

    -- Increment the number of windows in the master area
    , ((modm              , xK_comma ), sendMessage (IncMasterN 1))

    -- Deincrement the number of windows in the master area
    , ((modm              , xK_period), sendMessage (IncMasterN (-1)))

    -- Toggle the status bar gap
    -- Use this binding with avoidStruts from Hooks.ManageDocks.
    -- See also the statusBar function from Hooks.DynamicLog.
    --
    -- , ((modm              , xK_b     ), sendMessage ToggleStruts)

    -- Quit xmonad
    , ((modm .|. shiftMask, xK_q     ), io (exitWith ExitSuccess))

    -- Restart xmonad
    , ((modm .|. shiftMask       , xK_r     ), spawn "xmonad --recompile; xmonad --restart")

    ]
    ++

    --
    -- mod-[1..9], Switch to workspace N
    -- mod-shift-[1..9], Move client to workspace N
    --
    [((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    ++

    --
    -- mod-{w,e,r}, Switch to physical/Xinerama screens 1, 2, or 3
    -- mod-shift-{w,e,r}, Move client to screen 1, 2, or 3
    --
    [((m .|. modm, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_w, xK_e, xK_r] [0..]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]


------------------------------------------------------------------------
-- Mouse bindings: default actions bound to mouse events
--
myMouseBindings (XConfig {XMonad.modMask = modm}) = M.fromList $

    -- mod-button1, Set the window to floating mode and move by dragging
    [ ((modm, button1), (\w -> focus w >> mouseMoveWindow w
                                       >> windows W.shiftMaster))

    -- mod-button2, Raise the window to the top of the stack
    , ((modm, button2), (\w -> focus w >> windows W.shiftMaster))

    -- mod-button3, Set the window to floating mode and resize by dragging
    , ((modm .|. shiftMask, button1), (\w -> focus w >> mouseResizeWindow w
                                       >> windows W.shiftMaster))

    -- you may also bind events to the mouse scroll wheel (button4 and button5)
    ]

------------------------------------------------------------------------import Control.Monad

-- Layouts:

-- You can specify and transform your layouts by modifying these values.
-- If you change layout bindings be sure to use 'mod-shift-space' after
-- restarting (with 'mod-q') to reset your layout state to the new
-- defaults, as xmonad preserves your old layout settings by default.
--
-- The available layouts.  Note that each layout is separated by |||,
-- which denotes layout choice.
--
myLayout = smartBorders(avoidStruts (  tiled |||  simplestFloat ))
  where 
     -- default tiling algorithm partitions the screen into two panes
     tiled   = Tall nmaster delta ratio

     -- The default number of windows in the master pane
     nmaster = 1

     -- Default proportion of screen occupied by master pane
     ratio   = 1/2

     -- Percent of screen to increment by when resizing panes
     delta   = 3/100
     
     


------------------------------------------------------------------------
-- Window rules:

-- Execute arbitrary actions and WindowSet manipulations when managing
-- a new window. You can use this to, for example, always float a
-- particular program, or have a client always appear on a particular
-- workspace.
--
-- To find the property name associated with a program, use
-- > xprop | grep WM_CLASS
-- and click on the client you're interested in.
--
-- To match on the WM_NAME, you can use 'title' in the same way that
-- 'className' and 'resource' are used below.
--
myManageHook = composeAll
    [ className =? "MPlayer"        --> doFloat
    , className =? "Gimp"           --> doFloat
    , className =? "pavucontrol"           --> doFloat
    , className =? "virtualbox"           --> doFloat
   , className =? "thunar"           --> doFloat
    , resource  =? "desktop_window" --> doIgnore
    , resource  =? "kdesktop"       --> doIgnore
    , isFullscreen                  --> doFullFloat ] -- this one


------------------------------------------------------------------------
-- Event handling

-- * EwmhDesktops users should change this to ewmhDesktopsEventHook
--
-- Defines a custom handler function for X Events. The function should
-- return (All True) if the default handler is to be run afterwards. To
-- combine event hooks use mappend or mconcat from Data.Monoid.
--
--myEventHook = ewmhDesktopsEventHook

------------------------------------------------------------------------
-- Status bars and logging

-- Perform an arbitrary action on each internal state change or X event.
-- See the 'XMonad.Hooks.DynamicLog' extension for examples.
--
--myLogHook = return ()
--myLogHook = dynamicLogWithPP $ def { ppOutput = hPutStrLn xmproc }
--myLogHook :: X ()
--myLogHook = fadeInactiveLogHook fadeAmount
--    where fadeAmount = 1.0

mySpacing :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing i = spacingRaw False (Border i i i i) True (Border i i i i) True

-----------------------------------------
-- Startup hook

-- Perform an arbitrary action each time xmonad starts or is restarted
-- with mod-q.  Used by, e.g., XMonad.Layout.PerWorkspace to initialize
-- per-workspace layout choices.
--
-- By default, do nothing.
myStartupHook = do
        spawnOnce "/usr/lib/notification-daemon-1.0/notification-daemon"
        spawnOnce "xsetroot -cursor_name left_ptr"
        spawnOnce "/usr/libexec/notification-daemon"
        spawnOnce "lxpolkit"
        --spawnOnce "polybar xmonad"
        spawnOnce "picom --experimental-backends"
        --spawnOnce "picom"
        spawnOnce "nitrogen --restore"
        --spawnOnce "trayer --edge top --align right --widthtype request --SetDockType true --SetPartialStrut true --expand true  --transparent true  --tint 0x292d3e  --alpha 0 --height 20 --padding 1"
        spawnOnce "trayer --edge top --align right --widthtype request --SetDockType true --SetPartialStrut true --expand true  --transparent true --alpha 165 --tint 0x282a36 --height 20 --padding 4"
        --spawnOnce "stalonetray"
        --spawnOnce "pasystray"
        spawnOnce "nm-applet"
        spawnOnce "mate-power-manager"
        spawnOnce "xfce4-clipman"
        spawnOnce "redshift -O 4000"
        spawnOnce "volumeicon"

--fullLayout = noBorders (fullscreenFull Full)
------------------------------------------------------------------------
-- Now run xmonad with all the defaults we set up.

-- Run xmonad with the settings you specify. No need to modify this.
setFullscreenSupported :: X ()
setFullscreenSupported = addSupported ["_NET_WM_STATE", "_NET_WM_STATE_FULLSCREEN"]

addSupported :: [String] -> X ()
addSupported props = withDisplay $ \dpy -> do
    r <- asks theRoot
    a <- getAtom "_NET_SUPPORTED"
    newSupportedList <- mapM (fmap fromIntegral . getAtom) props
    io $ do
      supportedList <- fmap (join . maybeToList) $ getWindowProperty32 dpy a r
      changeProperty32 dpy r a aTOM propModeReplace (nub $ newSupportedList ++ supportedList)

--
main =  do
      xmproc <- spawnPipe "xmobar  ~/.xmobarrc"
      --xmproc <- spawnPipe "trayer --edge top --align right --widthtype request --SetDockType true --SetPartialStrut true --expand true  --transparent true --alpha 0 --tint 0x282a36 --height 20 --padding 4"
    -- Request access to the DBus name
      xmonad $ docks  $ ewmh def {
        terminal           = myTerminal,
        focusFollowsMouse  = myFocusFollowsMouse,
        clickJustFocuses   = myClickJustFocuses,
        borderWidth        = myBorderWidth,
        modMask            = myModMask,
        workspaces         = myWorkspaces,
        normalBorderColor  = myNormalBorderColor,
        focusedBorderColor = myFocusedBorderColor,

      -- key bindings
        keys               = myKeys,
        mouseBindings      = myMouseBindings,

      -- hooks, layouts
        layoutHook         = mySpacing 8 $ myLayout ,
        --manageHook         =  placeHook simpleSmart <+> manageHook def ,
       -- manageHook = ( isFullscreen --> doFullFloat ) <+> myManageHook <+> manageDocks,
	     --logHook            = myLogHook,
        --logHook            = dynamicLogWithPP $ defaultPP { ppOutput = hPutStrLn h },
        manageHook = manageDocks <+> (isFullscreen --> doFullFloat),
       
        --startupHook        = setFullscreenSupported <+> myStartupHook,
        --logHook = dynamicLogWithPP (myLogHook dbus)
        handleEventHook    = handleEventHook def <+> fullscreenEventHook,
        --handleEventHook = ewmhDesktopsEventHook,
        --startupHook        =  setFullscreenSupported <+> myStartupHook,
        startupHook        =   setFullscreenSupported >> setWMName "LG3D" <+> myStartupHook,
        logHook = dynamicLogWithPP xmobarPP
                        { ppOutput = hPutStrLn xmproc
                        , ppCurrent = xmobarColor "#f1fa8c" "" . wrap "[" "]"
                        , ppHiddenNoWindows = xmobarColor "#6272a4" ""
                        , ppTitle   = xmobarColor "#ff79c6"  "" . shorten 40
                        , ppVisible = wrap "(" ")"
                        , ppUrgent  = xmobarColor "#ff5555" "#f1fa8c"
                        }


	      --logHook            = dynamicLogWithPP $ xmobarPP
          --              { ppOutput = hPutStrLn xmproc
          --              , ppTitle = xmobarColor "#ff79c6" "" . shorten 50
          --             }
        --logHook = dynamicLogWithPP $ prettyPrinter xmproc
        --logHook            = dynamicLogWithPP $ defaultPP { ppOutput = hPutStrLn h },
        --startupHook        = myStartupHook
        --logHook           = myLogHook
      }  

--main = do
    -- Launching three instances of xmobar on their monitors.
--    xmproc0 <- spawnPipe "xmobar ~/.xmobarrc"
    -- the xmonad, ya know...what the WM is named after!
    --xmonad $ docks def
-- A structure containing your configuration settings, overriding
-- fields in the default config. Any you don't override, will
-- use the defaults defined in xmonad/XMonad/Config.hs
--
-- No need to modify this.
--
--defaults = def {
      -- simple stuff
--        terminal           = myTerminal,
--        focusFollowsMouse  = myFocusFollowsMouse,
 --       clickJustFocuses   = myClickJustFocuses,
--        borderWidth        = myBorderWidth,
--        modMask            = myModMask,
--        workspaces         = myWorkspaces,
--        normalBorderColor  = myNormalBorderColor,
--        focusedBorderColor = myFocusedBorderColor,

      -- key bindings
--        keys               = myKeys,
--        mouseBindings      = myMouseBindings,

      -- hooks, layouts
--        layoutHook         = myLayout,
--        manageHook         = myManageHook,
        --handleEventHook    = myEventHook,
        --logHook            = myLogHook,
        --logHook            = dynamicLogWithPP $ defaultPP { ppOutput = hPutStrLn h },
--        startupHook        = myStartupHook
--    }



