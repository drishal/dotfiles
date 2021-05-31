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
-- import qualified DBus as D
-- import qualified DBus.Client as D
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
import XMonad.Layout.Renamed

--import XMonad.Layout.Fullscreen as FS
    -- Layouts modifiers
import XMonad.Layout.LayoutModifier
import XMonad.Layout.LimitWindows (limitWindows, increaseLimit, decreaseLimit)
--import XMonad.Layout.Magnifier
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
import XMonad.Prompt.Workspace
import Data.Char

    -- Utilities
import XMonad.Util.EZConfig (additionalKeysP, additionalMouseBindings)
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run (runProcessWithInput, safeSpawn, spawnPipe)
import XMonad.Util.SpawnOnce

--Others
import XMonad.Layout.MultiToggle.Instances
import XMonad.Layout.MultiToggle

fontFamily :: String
fontFamilyLarge :: String
fontFamily = "xft:FiraCode Nerd Font:size=10:antialias=true:hinting=true"
fontFamilyLarge = "xft:FiraCode Nerd Font:size=16:style=Bold:antialias=true:hinting=true"

myTerminal :: String
myTerminal = "kitty"

myFocusFollowsMouse :: Bool
myFocusFollowsMouse = True

myClickJustFocuses :: Bool
myClickJustFocuses = False

myBorderWidth   = 1

myModMask       = mod4Mask

myWorkspaces    = ["1","2","3","4","5","6","7","8","9"]

myNormalBorderColor  = "#44475a"
myFocusedBorderColor = "#bd93f9"

myLayout =  renamed [CutWordsLeft 1] ( mySpacing 8  (smartBorders(avoidStruts (  tiled ||| simplestFloat )))) ||| smartBorders Full
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

mySpacing :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing i = spacingRaw False (Border i i i i) True (Border i i i i) True

myStartupHook = do
       -- spawnOnce "/usr/lib/notification-daemon-1.0/notification-daemon"
	-- spawnOnce "/usr/libexec/notification-daemon"
	spawnOnce "deadd-notification-center&"
	spawnOnce "xsetroot -cursor_name left_ptr"
	-- spawnOnce "lxqt-notificationd&"
	--  spawnOnce "/usr/libexec/notification-daemon"
	spawnOnce "lxpolkit"
	spawnOnce "trayer --edge top --align right --widthtype request --SetDockType true --SetPartialStrut true --expand true  --transparent true  --tint 0x282a36 --alpha 0 --height 20 --padding 3 --iconspacing 3"
	--spawnOnce "polybar xmonad"
	spawnOnce "picom --experimental-backends"
	--spawnOnce "picom"
	spawnOnce "nitrogen --restore"
	--spawnOnce "trayer --edge top --align right --widthtype request --SetDockType true --SetPartialStrut true --expand true  --transparent true  --tint 0x292d3e  --alpha 0 --height 20 --padding 1"
	--spawnOnce "stalonetray"
	--spawnOnce "pasystray"
	spawnOnce "nm-applet"
	-- spawnOnce "xiccd"
	-- spawnOnce "mate-power-manager"
	spawnOnce "xfce4-power-manager"
	spawnOnce "xfce4-clipman"
	spawnOnce "redshift -O 5000"
	spawnOnce "volumeicon"
	--spawnOnce "play  -v0.05  ~/Desktop/95.mp3"

myKeys :: [(String, X ())]
myKeys =
  [
   --xmonad
    ("M-S-r", spawn "xmonad --recompile; xmonad --restart")
  , ("M-S-q", io exitSuccess)

  --Prompts
    , ("M-w 1",                        shellPrompt promptConfig) --normal run prompt
    , ("M-w 2",                        manPrompt promptConfig) -- man prompt
    , ("M-w 3",                        xmonadPrompt promptConfig)       -- xmonadPrompt
   --Rofi Stuff
  , ("M-d", spawn "rofi -show drun -icon-theme Papirus -show-icons")
  , ("M-p", spawn " rofi -show powermenu -modi powermenu:~/Desktop/rofis/rofi-power-menu/rofi-power-menu")

  --Some Applications
  , ("M-S-f", spawn "firefox")
  , ("M-e", spawn "thunar")

  --emacs
  , ("M-a", spawn "emacs")

  --terminal
  , ("M-<Return>", spawn myTerminal)

  --window management
    --close
  , ("M-q", kill)
    --Rotate through the available layout algorithms
  , ("M-<Space>", sendMessage NextLayout)
  --  Reset the layouts on the current workspace to default
   --, ("M-S-<Tab>" , setLayout $ XMonad.layoutHook myLayout)

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
    , ("M-S-m", windows W.swapMaster)

    -- Swap the focused window with the next window
    , ("M-S-j", windows W.swapDown  )

    -- Swap the focused window with the previous window
    , ("M-S-k", windows W.swapUp    )

    -- Shrink the master area
    , ("M-C-h", sendMessage Shrink)

    -- Expand the master area
    , ("M-C-l", sendMessage Expand)
    --reset layout
    , ("M-C-<Space>",  setLayout $ Layout myLayout)
    --toogle fullscreen
    --, ("M-f", sendMessage $ Toggle FULL )

    -- Push window back into tiling
    , ("M-S-<Space>", withFocused $ windows . W.sink)
    --reset layout
    --, ("M-S-<Tab>", setLayout $ XMonad.)
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

myMouseBindings =
    [ ((modkey, button1), (\w -> focus w >> mouseMoveWindow w >> windows W.shiftMaster))
    , ((modkey, button2), (\w -> focus w >> windows W.shiftMaster))
    , ((modkey .|. shiftMask, button1), (\w -> focus w >> mouseResizeWindow w >> windows W.shiftMaster)) ]
  where
    modkey = mod4Mask

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

main =  do
      --xmproc <- spawnPipe "polybar xmonad"
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
        layoutHook         =  mkToggle (NOBORDERS ?? FULL ?? EOT) $ myLayout ,
        --layoutHook         =   myLayout ,
        --manageHook         =  placeHook simpleSmart <+> manageHook def ,
       -- manageHook = ( isFullscreen --> doFullFloat ) <+> myManageHook <+> manageDocks,
        --logHook            = myLogHook,
        --logHook            = dynamicLogWithPP $ defaultPP { ppOutput = hPutStrLn h },
        -- manageHook = manageDocks <+> (isFullscreen --> doFullFloat),
        manageHook = manageDocks,
        handleEventHook    = handleEventHook def <+> fullscreenEventHook,
        --handleEventHook = ewmhDesktopsEventHook,
        -- startupHook        = myStartupHook,
        startupHook=   setFullscreenSupported >> setWMName "LG3D" <+> myStartupHook,
        logHook = dynamicLogWithPP xmobarPP
                         { ppOutput = hPutStrLn xmproc
                        , ppCurrent = xmobarColor "#f1fa8c" "" . wrap "[" "]"
                        , ppHiddenNoWindows = xmobarColor "#6272a4" ""
                        , ppTitle   = xmobarColor "#ff79c6"  "" . shorten 40
                        , ppVisible = wrap "(" ")"
                        , ppUrgent  = xmobarColor "#ff5555" "#f1fa8c"
                        , ppLayout  = xmobarColor "#8be9fd" ""
                        }
        }  `additionalKeysP` myKeys `additionalMouseBindings` myMouseBindings
