#!/bin/bash

set -e

PID=$(pgrep gnome-session)
export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$PID/environ | tr '\0' '\n'| cut -d= -f2-)

declare -A dark light

# theme properties
dark+=(["dark_mode_on"]=true
       ["gtk_theme"]=""
       ["icon_theme"]=""
       ["tilix_theme"]=""
       ["plank_theme"]=""
       ["wallpaper"]=""
       ["sublime_theme"]=""
    )

light+=(["dark_mode_on"]=false
        ["gtk_theme"]=""
        ["icon_theme"]=""
        ["tilix_theme"]=""
        ["plank_theme"]=""
        ["wallpaper"]=""
        ["sublime_theme"]=""
    )

THEMES_FOLDER=${HOME}/.themes
CURRENT_THEME_FILE=${THEMES_FOLDER}/current_theme
AUTO_SWITCH_THEME_FILE=${THEMES_FOLDER}/auto_theme
SUBLIME_CONFIG_FILE=~/.config/sublime-text-3/Packages/User/Preferences.sublime-settings
TIME_RANGE=( 08:00 17:00 )
WALLPAPER_FILE="file:///${HOME}/Pictures/wallpapers/wallpaper_%index%.jpeg"

WALLPAPER_MAX_INDEX=16 
# generate time ranges for wallpaper switching 
TIME_RANGES=( $(seq -f "%02g:00" -s " " 07 22) )

current_theme=$(cat ${CURRENT_THEME_FILE}) 
current_time=$(date +%H:%M)

function set_appearance()
{
    # skip if the theme is currenlty set
    [[ ! -z "${current_theme}" && "${current_theme}" == "$1" ]] && exit 1

    echo "Applying $1 theme..."
    var=$(declare -p "$1")
    eval "declare -A theme_props="${var#*=}

    gsettings set com.solus-project.budgie-panel dark-theme ${theme_props[dark_mode_on]} &
    gsettings set org.gnome.desktop.interface gtk-theme ${theme_props[gtk_theme]} &
    gsettings set org.gnome.desktop.interface icon-theme ${theme_props[icon_theme]} &
    gsettings set com.gexperts.Tilix.Settings theme-variant ${theme_props[tilix_theme]} &
    dconf write /net/launchpad/plank/docks/dock1/theme "\"${theme_props[plank_theme]}\"" &
    sed -i -E "s/[a-zA-Z ]*.sublime-theme/${theme_props[sublime_theme]}.sublime-theme/g" ${SUBLIME_CONFIG_FILE} &
    
    echo "$1" > ${CURRENT_THEME_FILE}
}

# Simple implementation of dynamic wallpaper functionality.
function set_wallpaper()
{
    # find time range based on current time
    if [[ ! "${current_time}" < "${TIME_RANGES[-1]}" || "${current_time}" < "${TIME_RANGES[0]}" ]]; then
        i=$WALLPAPER_MAX_INDEX
    else
        for index in "${!TIME_RANGES[@]}"; do
            if [[ ! "$current_time" < "${TIME_RANGES[$index]}" ]] && [[ "$current_time" < "${TIME_RANGES[$index+1]}" ]]; then            
                i=$((index+1))
                break;
            fi
        done
    fi
    picture_uri=$(echo ${WALLPAPER_FILE} | sed -E "s/%index%/$i/g")

    gsettings set org.gnome.desktop.background picture-uri ${picture_uri} &
    gsettings set org.gnome.desktop.screensaver picture-uri ${picture_uri} &
}

function main()
{
    usage="Usage: theme light|dark|auto|time-based
    light/dark - set light or dark appearance
    auto       - enable automatic theme switching based on time
    time-based - set theme depending on the current time of the day"

    if [ "$#" -ne 1 ]; then
        echo "${usage}"
        exit 1
    fi

    set_wallpaper
    case $1 in
        light | dark)
            # disable auto theme
            [[ -f ${AUTO_SWITCH_THEME_FILE} ]] && rm ${AUTO_SWITCH_THEME_FILE}
            set_appearance "$1"
            ;;
        time-based)
            if [[ -f ${AUTO_SWITCH_THEME_FILE} ]]; then 
                if [[ "$current_time" > ${TIME_RANGE[0]} ]] && [[ ! "$current_time" > ${TIME_RANGE[1]} ]]; then
                    set_appearance light
                else
                    set_appearance dark
                fi
            fi
            ;;
        auto)
            echo 'Automatic theme switch is enabled.'
            touch ${AUTO_SWITCH_THEME_FILE}
            ;;
        *)
            echo "Incorrect value \"$1\"".
            echo "${usage}"
            ;;
        esac
}

main $@


