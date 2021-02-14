---IMPORTS
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
import XMonad.Prompt.Shell
import XMonad.Prompt.Ssh
import XMonad.Prompt.XMonad
import XMonad.Prompt.AppLauncher
import Control.Arrow (first)
import Data.Char

    -- Utilities
import XMonad.Util.EZConfig (additionalKeysP, additionalMouseBindings)
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run (runProcessWithInput, safeSpawn, spawnPipe)
import XMonad.Util.SpawnOnce

-- The preferred terminal program, which is used in a binding below and by
-- certain contrib modules.
--
fontFamily = "xft:Hack Nerd Font:size=10:antialias=true:hinting=true"
fontFamilyLarge = "xft:Hack Nerd Font:size=16:style=Bold:antialias=true:hinting=true"

myTerminal :: String
myTerminal      = "alacritty"

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
myNormalBorderColor  = "#44475a"
myFocusedBorderColor = "#bd93f9"

--Layouts
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

myManageHook = composeAll
    [ className =? "MPlayer"        --> doFloat
    , className =? "Gimp"           --> doFloat
    , className =? "pavucontrol"           --> doFloat
    , className =? "virtualbox"           --> doFloat
   , className =? "thunar"           --> doFloat
    , resource  =? "desktop_window" --> doIgnore
    , resource  =? "kdesktop"       --> doIgnore
    , isFullscreen                  --> doFullFloat ] -- this one

---------------------------
--Prompts
---------------------------
promptConfig = def
  { font                = fontFamily
  , bgColor             = "#282a36"
  , fgColor             = "#f8f8f2"
  , bgHLight            = "#bd93f9"
  , fgHLight            = "#282a36"
  , borderColor         = "#bd93f9"
  , promptBorderWidth   = 0
  , position            = Top
  , height              = 20
  , historySize         = 256
  , historyFilter       = id
  , showCompletionOnTab = False
  , searchPredicate     = fuzzyMatch
  , sorter              = fuzzySort
  , defaultPrompter     = id $ map toLower
  , alwaysHighlight     = True
  , maxComplRows        = Just 5
  }
-----------------------
--Borders/Gaps
-----------------------
mySpacing :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing i = spacingRaw False (Border i i i i) True (Border i i i i) True

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
        spawnOnce "trayer --edge top --align right --widthtype request --SetDockType true --SetPartialStrut true --expand true  --transparent true  --tint 0x282a36 --alpha 0 --height 20 --padding 4"
        --spawnOnce "stalonetray"
        --spawnOnce "pasystray"
        spawnOnce "nm-applet"
        spawnOnce "mate-power-manager"
        spawnOnce "xfce4-clipman"
        spawnOnce "redshift -O 4500"
        spawnOnce "volumeicon"
-------------------------
--My Keys--
-------------------------
myKeys :: [(String, X ())]
myKeys =
  [
   --xmonad
    ("M-S-r", spawn "xmonad --recompile; xmonad --restart")
  , ("M-S-q", io exitSuccess)

  --Prompts
    , ("M-d",                        shellPrompt promptConfig) --normal run prompt
    , ("M-r m",                        manPrompt promptConfig) --normal run prompt
   --Rofi Stuff
  --, ("M-d", spawn "rofi -show drun -icon-theme Papirus -show-icons")
  , ("M-p", spawn " rofi -show powermenu -modi powermenu:~/Desktop/rofis/rofi-power-menu/rofi-power-menu")

  --Some Applications
  , ("M-S-f", spawn "firefox")
  , ("M-e", spawn "thunar")

  --emacs
  , ("M-a", spawn "emacsclient -c")

  --terminal
  , ("M-<Return>", spawn myTerminal)

  --window management
    --close
  , ("M-q", kill)
    --Rotate through the available layout algorithms
  , ("M-<Space>", sendMessage NextLayout)
  --  Reset the layouts on the current workspace to default
   -- , ("M-C-<Space>" , setLayout $ XMonad.layoutHook conf)

    -- Resize viewed windows to the correct size
    , ("M-n", refresh)

    -- Move focus to the next window
    , ("M-<Tab>" , windows W.focusDown)

    -- Move focus to the next window
    , ("M-j", windows W.focusDown)

    -- Move focus to the previous window
    , ("M-k", windows W.focusUp  )

    -- Move focus to the master window
    , ("M-m", windows W.focusMaster  )

    -- Swap the focused window and the master window
    , ("M-C-m", windows W.swapMaster)

    -- Swap the focused window with the next window
    , ("M-C-j", windows W.swapDown  )

    -- Swap the focused window with the previous window
    , ("M-C-k", windows W.swapUp    )

    -- Shrink the master area
    , ("M-S-h", sendMessage Shrink)

    -- Expand the master area
    , ("M-S-l", sendMessage Expand)

    -- Push window back into tiling
    , ("M-S-<Space>", withFocused $ windows . W.sink)

    -- Increment the number of windows in the master area
    , ("M-,", sendMessage (IncMasterN 1))

    -- Deincrement the number of windows in the master area
    , ("M-.", sendMessage (IncMasterN (-1)))

  ]
  ++

  [ (otherModMasks ++ "M-" ++ key, action tag)
        | (tag, key) <- zip(map show [1..9]) (map (\x -> show x) ([1..9]))
        , (otherModMasks, action) <- [ ("", windows . W.greedyView)
                                     , ("S-", windows . W.shift)]
        ]

---------------
--Mouse--
---------------
myMouseBindings =
    [ ((modkey, button1), (\w -> focus w >> mouseMoveWindow w >> windows W.shiftMaster))
    , ((modkey, button2), (\w -> focus w >> windows W.shiftMaster))
    , ((modkey .|. shiftMask, button1), (\w -> focus w >> mouseResizeWindow w >> windows W.shiftMaster)) ]
  where
    modkey = mod4Mask
------------------------------
-- Adding Fullscreen Support--
------------------------------

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

-----------------
--the real event
-----------------

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
        --keys               = myKeys,
        --mouseBindings      = myMouseBindings,

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
        }  `additionalKeysP` myKeys `additionalMouseBindings` myMouseBindings
