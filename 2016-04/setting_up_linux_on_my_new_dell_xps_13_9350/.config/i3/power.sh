lock() {
	# Only have one instance of i3lock running
	pgrep i3lock
	if [ $? -eq 0 ]; then
		return
	fi
	# Blur desktop
	scrot /tmp/screenshot.png
	convert /tmp/screenshot.png -filter box -blur 0x3 /tmp/screenshot.png
	i3lock --image /tmp/screenshot.png --show-failed-attempts
}

case "$1" in
	lock)
		lock
		;;
	logout)
		i3msg exit
		;;
	suspend)
		lock && systemctl suspend
		;;
	hibernate)
		lock && systemctl hibernate
		;;
	poweroff)
		poweroff
		;;
	reboot)
		reboot
		;;
	*)
		echo "Usage: $0 {lock|logout|hibernate|poweroff|reboot}"
		exit 2
esac
