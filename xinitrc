#!/bin/sh

# global startup scripts
if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

# Read Xresources
xrdb -merge ~/.Xresources

# Key management
gpg_agent_info="${HOME}/.gnupg/gpg-agent.info"
if pgrep -u "${USER}" gpg-agent >/dev/null 2>&1; then
    eval `cat ${gpg_agent_info}`
    eval `cut -d= -f1 ${gpg_agent_info} | xargs echo export`
else
    eval `gpg-agent --enable-ssh-support --write-env-file=${gpg_agent_info} --daemon`
fi

# Some visuals i wanna have really fast
compton --vsync opengl-swc --backend glx --unredir-if-possible --glx-no-stencil &
xsetroot -cursor_name left_ptr &
hsetroot -fill ~/.wallpapers/current &

# Blend Qt into GTK environment
export GTK2_RC_FILES="${HOME}/.gtkrc-2.0"
# Some xmonad related bonus
export _JAVA_AWT_WM_NONREPARENTING=1
export _JAVA_OPTIONS='-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel -Dswing.crossplatformlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel'

# key repeating
xset r rate 200 35 &

# Connection management
wicd-client -t &
# Clipboard synchronization
parcellite &
# Auto locker
xautolock -detectsleep &
# audio
start-pulseaudio-x11 -D &
pasystray &
# display management
xrr-events --daemonize &
# keyboard
xmodmap ~/.Xmodmap &

# Source device dependent xinitrc
. ${HOME}/.xinitrc.local

# Start xmonad
exec xmonad
