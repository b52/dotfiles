import XMonad
import XMonad.Actions.CopyWindow
import XMonad.Actions.WindowNavigation
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Hooks.UrgencyHook
import XMonad.Layout.ResizableTile
import XMonad.Layout.Grid
import XMonad.Layout.LayoutHints
import XMonad.Layout.LayoutModifier
import XMonad.Layout.Named
import XMonad.Layout.NoBorders
import XMonad.Layout.PerWorkspace
import XMonad.Layout.Spacing
import XMonad.Layout.ToggleLayouts
import XMonad.Util.EZConfig
import XMonad.Util.Run

import Graphics.X11.Xlib.Extras

import qualified Data.List as L
import qualified Data.Map as M
import qualified XMonad.Layout.WorkspaceDir as WD
import qualified XMonad.StackSet as W


-- Visual settings used by e.g. dmenu
myFont         = "xft:ProggyTiny:pixelsize=9"
myBgColor      = "#1b1d1e"
myFgColor      = "#bbbbbb"
mySelFgColor   = "#ffffff"
mySelBgColor   = "#333333"
myBorderColor  = "#40464b"
myFocusedColor = "#839cad"
myCurrentColor = "#cd5c5c"
myEmptyColor   = "#4c4c4c"
myHiddenColor  = "#dddddd"
myLayoutColor  = "#839cad"
myUrgentColor  = "#2b9ac8"
myTitleColor   = "#ffffff"
mySepColor     = "#58504c"


-- Some basic defaults
myWorkspaces  = ["main", "web", "dev", "misc"]
myTerminal    = "urxvt"
myBorderWidth = 2
myModMask     = mod4Mask


-- All types of layouts
myLayoutHook = lessBorders OnlyFloat $ grid ||| tall ||| full
  where myNamed n = named n . avoidStruts
        grid      = myNamed "grid" Grid
        tall      = myNamed "tall" $ Tall 1 (3/100) (1/2)
        full      = myNamed "full" Full


-- Rules to handle the windows
myManageHook = composeAll $
    [ isFullscreen --> doFullFloat
    , isDialog     --> doFloat
    , className =? "MPlayer" --> doFloat <+> doF copyToAll
    , className =? "mplayer2" --> doFloat <+> doF copyToAll
    , className =? "Smplayer" --> doFloat <+> doF copyToAll
    , className =? "Steam" --> doFloat
    , className =? "stalonetray" --> doIgnore
    ] ++
    [ className =? n --> doFloat | n <- dialogCFs ] ++
    [ title =? n --> doFloat | n <- dialogNFs ] ++
    [ className =? "Firefox" <&&> resource =? r --> doFloat | r <- ffResources ]
  where
    dialogCFs = ["Pinentry-gtk-2"]
    dialogNFs = ["Ordner wählen"]
    ffResources = ["Download", "Dialog"]


-- All keyboard shortcuts
myKeys conf = mkKeymap conf $
    [ ("M-q", kill)
    , ("M-e", spawn "gmrun")
    , ("M-<Return>", spawn $ terminal conf)
    , ("M-S-q", spawn "exec killall stalonetray" >> restart "xmonad" True)
    , ("M-m", windows W.shiftMaster)
    , ("M-t", withFocused $ windows . W.sink)
    , ("M-,", sendMessage Shrink)
    , ("M-.", sendMessage Expand)
    , ("M-l", spawn "sleep 1;notify-send asd")
    , ("M-<Space>", sendMessage NextLayout)
    , ("M-<Tab>", windows W.focusDown)
    , ("M-S-<Tab>", windows W.focusUp)
    , ("<XF86AudioMute>", spawn "amixer set Master toggle")
    , ("<XF86AudioLowerVolume>", spawn "amixer set Master 5%-")
    , ("<XF86AudioRaiseVolume>", spawn "amixer set Master 5%+")
    ]
    ++
    [ (m ++ [i], f w) | (i, w) <- zip ['1'..] $ workspaces conf
                      , (m, f) <- [ ("M-", windows . W.greedyView)
                                  , ("M-S-", windows . W.shift)
                                  ]
    ]


-- A simple xmobar statusbar controlled by XMonad
myStatusBar = statusBar "xmobar" myPP toggleStrutsKey
  where
    myPP = defaultPP
         { ppCurrent = xmobarColor myCurrentColor ""
         , ppHidden = xmobarColor myHiddenColor ""
         , ppHiddenNoWindows = xmobarColor myEmptyColor ""
         , ppUrgent = xmobarColor myUrgentColor "" . xmobarStrip
         , ppLayout = xmobarColor myLayoutColor ""
         , ppWsSep = "  "
         , ppSep = xmobarColor mySepColor "" "   |   "
         , ppTitle = xmobarColor myTitleColor "" . shorten 120 . trim
         }
    toggleStrutsKey XConfig {modMask = modm} = (modm, xK_b)


-- EWMH sets the wmname, therefor we have to override that
ewmhWithJava = (\cfg -> cfg { startupHook = startupHook cfg <+> setWMName "LG3D" }) . ewmh

main = do
    stalonetray <- spawnPipe "stalonetray"
    config <- withWindowNavigation (xK_k, xK_h, xK_j, xK_l) $ ewmhWithJava defaultConfig
        { workspaces = myWorkspaces
        , terminal = myTerminal
        , borderWidth = myBorderWidth
        , modMask = myModMask
        , normalBorderColor = myBorderColor
        , focusedBorderColor = myFocusedColor
        , keys = myKeys
        , handleEventHook = handleEventHook defaultConfig <+> fullscreenEventHook
        , layoutHook = myLayoutHook
        , manageHook = myManageHook <+> manageDocks
        }
    xmonad . withUrgencyHook NoUrgencyHook =<< myStatusBar config

