#!/usr/bin/env bash

# github: @plgbrlism
# tiktok: @fuzzbuzz.tech

# ~~ variables ~~
theme="$HOME/.config/rofi/config.rasi"

options=(
	"  Idle"
    "  Lock"
    "  Logout"
    "  Restart"
    "  Shutdown"
)

yes="yes"
no="no"

# ~~ launch rofis ~~
rofi_cmd() {
    rofi -dmenu \
        -theme "${theme}" \
        -theme-str 'window { width: 250; }' \
        -theme-str 'mainbox { children: [ message, listview ]; }' \
        -theme-str 'listview { columns: 1; lines: 5; }'
}

confirm_cmd() {
    rofi -dmenu \
        -p 'Confirmation' \
        -mesg 'are you deadass sure???' \
        -theme "${theme}" \
        -theme-str 'window { width: 350; }' \
        -theme-str 'mainbox { children: [ message, listview ]; }' \
        -theme-str 'listview { columns: 2; lines: 1; }' \
        -theme-str 'element-text { horizontal-align: 0.5; }' \
        -theme-str 'textbox { horizontal-align: 0.5; }'
}

confirm_exit() {
    printf "%s\n%s\n" "$yes" "$no" | confirm_cmd
}

# ~~ helpers
screensaver() {
    # interchange with whatever cli-tool screensaver (eg. cmatrix, cava, lavat)
    local app="${1:-lavat}"

	# to-do: get $TERMINAL from envs/rc instead.

    # kitty
    if command -v kitty >/dev/null; then
        kitty --start-as fullscreen -e "$app"  
        return
    fi

    # ghostty
        if command -v ghostty >/dev/null; then
            ghostty --fullscreen=true -e "$app"
            return
        fi
    
    # alacritty
    if command -v alacritty >/dev/null; then
        alacritty -e "$app"
        return
    fi

    # xterm
    if command -v xterm >/dev/null; then
        xterm -fullscreen -e "$app"
        return
    fi

    echo "No supported terminal found!"
}


quit_session() {
    if pgrep -x openbox > /dev/null; then openbox exit
    elif pgrep -x bspwm > /dev/null; then bspc quit
    elif pgrep -x i3 > /dev/null; then i3-msg exit
    elif pgrep -x sway > /dev/null; then swaymsg exit
    elif pgrep -x niri > /dev/null; then niri msg action quit --skip-confirmation
    fi
}

lock_screen() {
    if [[ $XDG_SESSION_TYPE == "wayland" ]]; then
    	if command -v hyprlock >/dev/null 2>&1; then
    		hyprlock
    	elif command -v veila >/dev/null 2>&1; then
    		"$HOME/.config/rofi/scripts/session_manager/veila-lock-custom/veila.sh"
    	else
        	swaylock
        fi
    elif [[ $XDG_SESSION_TYPE == "x11" ]]; then
    	if pgrep -x i3 >/dev/null && command -v i3lock-fancy-rapid >/dev/null 2>&1; then
    		"$HOME/.config/rofi/scripts/session_manager/i3lock-custom/i3lock.sh"
        else
            i3lock
        fi
    fi
}

# ~~ selection ~~
run_action() {
    case "$1" in
    	*"Idle")	 screensaver ;;
        *"Shutdown") selected="$(confirm_exit)"; [[ "$selected" == "$yes" ]] && systemctl poweroff ;;
        *"Restart")  selected="$(confirm_exit)"; [[ "$selected" == "$yes" ]] && systemctl reboot ;;
        *"Logout")   selected="$(confirm_exit)"; [[ "$selected" == "$yes" ]] && quit_session ;;
        *"Lock")     lock_screen ;;
    esac
}

chosen=$(printf "%s\n" "${options[@]}" | rofi_cmd)
run_action "$chosen"
