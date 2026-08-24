#!/usr/bin/env bash

# github: @plgbrlism
# tiktok: @fuzzbuzz.tech

# ~~ variables ~~
style="$HOME/.config/wofi/style-narrow.css"
style_confirm="$HOME/.config/wofi/style-confirm.css"

options=(
	"  Idle"
    "  Lock"
    "  Logout"
    "  Restart"
    "  Shutdown"
)

yes="yes"
no="no"

# ~~ launch wofi ~~
wofi_cmd() {
    wofi --dmenu \
        --style "$style" \
        --width 250 \
        --prompt "󰿨 " \
        --define "dmenu-print_line_num=true"
}

confirm_cmd() {
    wofi --dmenu \
        --style "$style_confirm" \
        --width 350 \
        --prompt "Confirmation" \
        --define "dmenu-print_line_num=true"
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
    		"$HOME/.config/wofi/scripts/session_manager/veila-lock-custom/veila.sh"
    	else
        	swaylock
        fi
    elif [[ $XDG_SESSION_TYPE == "x11" ]]; then
    	if pgrep -x i3 >/dev/null && command -v i3lock-fancy-rapid >/dev/null 2>&1; then
    		"$HOME/.config/wofi/scripts/session_manager/i3lock-custom/i3lock.sh"
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

chosen=$(printf "%s\n" "${options[@]}" | wofi_cmd)
run_action "$chosen"
