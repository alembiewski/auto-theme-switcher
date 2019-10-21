# Automatic theme switcher

Set of scripts to customize the appearance of a desktop.
Tested on Ubuntu 19.04 with Budgie desktop.

The script applies a set of predefined themes and properties for the following components:

- GTK
- Icon theme
- Plank
- Tilix 
- Sublime
- Budgie panel 'Dark mode'
- Wallpaper

Properties for light and dark appearance are defined inside [theme-settings.json](theme-settings.json)

### Usage
```
theme light|dark|auto|time-based
    light/dark - set light or dark appearance
    auto       - enable automatic theme switching based on time
    time-based - set theme depending on the current time of the day
```

The script can be periodically executed via `cron` job:
```
crontab -e
```
Add the following line (executed each 5 minutes):
```
*/5 * * * * /path/to/theme.sh time-based 
```

### Dynamic wallpaper

Script implements a simple dynamic wallpaper functionality based on time range, current time and set of wallpapers. 

