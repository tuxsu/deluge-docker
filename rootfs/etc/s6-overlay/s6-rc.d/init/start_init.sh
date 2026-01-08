#!/command/with-contenv sh

PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Checking permissions (Target UID: $PUID, GID: $PGID)..."

if [ "$PUID" -eq 0 ] || [ "$PGID" -eq 0 ]; then
    echo "PUID/PGID set to 0. Running as root."
    mkdir -p "$CONFIG_DIR" "$DOWNLOAD_DIR"
    exit 0
fi

if ! getent group deluge > /dev/null; then
    EXISTING_GROUP=$(getent group "$PGID" | cut -d: -f1)
    if [ -n "$EXISTING_GROUP" ]; then
        echo "Warning: GID $PGID is used by '$EXISTING_GROUP'. Renaming..."
        groupmod -n deluge "$EXISTING_GROUP"
    else
        echo "Creating group 'deluge' with GID $PGID..."
        addgroup -g "$PGID" -S deluge
    fi
else
    groupmod -g "$PGID" deluge
fi

if ! getent passwd deluge > /dev/null; then
    EXISTING_USER=$(getent passwd "$PUID" | cut -d: -f1)
    if [ -n "$EXISTING_USER" ]; then
        echo "Warning: UID $PUID is used by '$EXISTING_USER'. Renaming..."
        usermod -l deluge -g "$PGID" "$EXISTING_USER"
    else
        echo "Creating user 'deluge' with UID $PUID..."
        adduser -u "$PUID" -G deluge -S -D -H deluge
    fi
else
    usermod -u "$PUID" -g "$PGID" deluge
fi

echo "Applying file permissions..."
mkdir -p "$CONFIG_DIR" "$DOWNLOAD_DIR"

chown -R deluge:deluge "$CONFIG_DIR"
chown deluge:deluge "$DOWNLOAD_DIR"

echo "Permission configuration complete."
