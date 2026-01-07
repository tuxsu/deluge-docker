#!/command/with-contenv sh
PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "正在配置用户权限 (UID: $PUID, GID: $PGID)..."

if ! getent group deluge >/dev/null; then
    addgroup -g "$PGID" -S deluge
else
    groupmod -g "$PGID" deluge
fi

if ! id -u deluge >/dev/null 2>&1; then
    adduser -u "$PUID" -G deluge -S -D -H deluge
else
    usermod -u "$PUID" -g "$PGID" deluge
fi

mkdir -p "$DELUGE_CONFIG_DIR" "$DELUGE_DOWNLOAD_DIR"
chown -R deluge:deluge "$DELUGE_CONFIG_DIR" "$DELUGE_DOWNLOAD_DIR"
