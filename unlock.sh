#!/bin/bash

dbus-monitor --session "type='signal',interface='org.gnome.ScreenSaver'" |
  while read x; do
    case "$x" in
      *"boolean true"*);;
      *"boolean false"*) theme.sh time-based;;
    esac
  done
