#!/bin/bash

PID=$(pgrep gnome-session)
export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$PID/environ | tr '\0' '\n'| cut -d= -f2-)

declare -A dark light DAY_TIME_RANGE

CONFIG_FOLDER="${HOME}/.config"
THEME_SETTINGS_FILE="${CONFIG_FOLDER}/theme-settings.json"
CURRENT_THEME_FLAG=${CONFIG_FOLDER}/current_theme
AUTO_SWITCH_THEME_FLAG=${CONFIG_FOLDER}/auto_switch_theme
SUBLIME_CONFIG_FILE=~/.config/sublime-text-3/Packages/User/Preferences.sublime-settings

DAY_TIME_RANGE["start"]="08:00"
DAY_TIME_RANGE["end"]="16:59"

WALLPAPER_FILE="${HOME}/Pictures/mojave/mojave_dynamic_%index%.jpeg"
WALLPAPER_MAX_INDEX=16

# generate time ranges for dynamic wallpaper
TIME_RANGES=( $(seq -f "%02g:00" -s " " 07 22) )

current_theme=$(cat ${CURRENT_THEME_FLAG}) 
current_time=$(date +%H:%M)

# initialize theme settings
while IFS== read key value; do
    light["$key"]="${value}"
done < <(jq -r '.light | to_entries | .[] | .key + "=" + .value ' ${THEME_SETTINGS_FILE})

while IFS== read key value; do
    dark["$key"]="${value}"
done < <(jq -r '.dark | to_entries | .[] | .key + "=" + .value ' ${THEME_SETTINGS_FILE})

function set_appearance()
{
    echo "Applying $1 theme..."

    var=$(declare -p "$1")
    eval "declare -A theme_props="${var#*=}

    if [[ "$2" == "fixed" ]]; then
        set_wallpaper ${theme_props[wallpaper]} 
    else
        set_wallpaper "$2"
    fi

    # skip if the theme is currenlty set
    [[ ! -z "${current_theme}" && "${current_theme}" == "$1" ]] && exit 1

    gsettings set com.solus-project.budgie-panel dark-theme ${theme_props["dark_mode_on"]} &
    gsettings set org.gnome.desktop.interface gtk-theme ${theme_props["gtk_theme"]} &
    gsettings set org.gnome.desktop.interface icon-theme ${theme_props["icon_theme"]} &
    gsettings set com.gexperts.Tilix.Settings theme-variant ${theme_props["tilix_theme"]} &
    gsettings set org.gnome.Evince.Default inverted-colors ${theme_props["dark_mode_on"]}
    dconf write /net/launchpad/plank/docks/dock1/theme "\"${theme_props[plank_theme]}\"" &
    sed -i -E "s/[a-zA-Z ]*.sublime-theme/${theme_props[sublime_theme]}.sublime-theme/g" ${SUBLIME_CONFIG_FILE} &
    
    echo "$1" > ${CURRENT_THEME_FLAG}
}

# Simple implementation of dynamic wallpaper functionality.
function set_wallpaper()
{
    if [[ "$1" == "auto" ]]; then
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
    else
        picture_uri="$1"
    fi    
    gsettings set org.gnome.desktop.background picture-uri file:///${picture_uri} &
    gsettings set org.gnome.desktop.screensaver picture-uri file:///${picture_uri} &
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

    case $1 in
        light | dark)
            # disable auto theme
            [[ -f ${AUTO_SWITCH_THEME_FLAG} ]] && rm ${AUTO_SWITCH_THEME_FLAG}
            set_appearance "$1" fixed
            ;;
        time-based)
            if [[ -f ${AUTO_SWITCH_THEME_FLAG} ]]; then
                if [[ "$current_time" > ${DAY_TIME_RANGE["start"]} ]] && [[ ! "$current_time" > ${DAY_TIME_RANGE["end"]} ]]; then
                    set_appearance light auto 
                else
                    set_appearance dark auto
                fi
            fi
            ;;
        auto)
            echo 'Automatic theme switch is enabled.'
            touch ${AUTO_SWITCH_THEME_FLAG}
            ;;
        *)
            echo "Incorrect value \"$1\"".
            echo "${usage}"
            ;;
        esac
}

main $@


