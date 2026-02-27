#!/usr/bin/env bash
# kwin_restart.sh - Restart KWin and Plasma Shell to apply changes

(kwin_wayland --replace &) && systemctl --user restart plasma-plasmashell

