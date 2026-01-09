#!/command/with-contenv sh
CONFIG_DIR=${CONFIG_DIR:-/config}
if [ "$PUID" -eq 0 ] || [ "$PGID" -eq 0 ]; then
	exec deluge-web -c "$CONFIG_DIR" -L info 2>&1
else
	exec s6-setuidgid deluge deluge-web -c "$CONFIG_DIR" -L info 2>&1
fi
