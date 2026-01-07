#!/command/with-contenv sh

PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Checking permissions (Target UID: $PUID, GID: $PGID)..."

if [ "$PUID" -eq 0 ] || [ "$PGID" -eq 0 ]; then
    echo "PUID/PGID set to 0. Running as root."
    mkdir -p "$DELUGE_CONFIG_DIR" "$DELUGE_DOWNLOAD_DIR"
    exit 0
fi

if ! getent group deluge >/dev/null; then
    EXISTING_GROUP=$(getent group "$PGID" | cut -d: -f1)
    if [ -n "$EXISTING_GROUP" ]; then
        echo "Warning: GID $PGID is already used by group '$EXISTING_GROUP'. Renaming to 'deluge'..."
        groupmod -n deluge "$EXISTING_GROUP"
    else
        echo "Creating group 'deluge' with GID $PGID..."
        addgroup -g "$PGID" -S deluge
    fi
else
    CURRENT_GID=$(getent group deluge | cut -d: -f3)
    if [ "$CURRENT_GID" != "$PGID" ]; then
        echo "Updating GID for 'deluge' from $CURRENT_GID to $PGID..."
        groupmod -g "$PGID" deluge
    fi
fi

if ! id -u deluge >/dev/null 2>&1; then
    EXISTING_USER=$(getent passwd "$PUID" | cut -d: -f1)
    if [ -n "$EXISTING_USER" ]; then
        echo "Warning: UID $PUID is already used by user '$EXISTING_USER'. Renaming to 'deluge'..."
        usermod -l deluge "$EXISTING_USER"
        usermod -g "$PGID" deluge
    else
        echo "Creating user 'deluge' with UID $PUID..."
        adduser -u "$PUID" -G deluge -S -D -H deluge
    fi
else
    CURRENT_UID=$(id -u deluge)
    CURRENT_USER_GID=$(id -g deluge)
    if [ "$CURRENT_UID" != "$PUID" ] || [ "$CURRENT_USER_GID" != "$PGID" ]; then
        echo "Updating 'deluge' user (UID: $CURRENT_UID->$PUID, GID: $CURRENT_USER_GID->$PGID)..."
        usermod -u "$PUID" -g "$PGID" deluge
    fi
fi

echo "Applying file permissions..."
mkdir -p "$DELUGE_CONFIG_DIR" "$DELUGE_DOWNLOAD_DIR"

if [ "$(stat -c %u "$DELUGE_CONFIG_DIR")" != "$PUID" ]; then
    echo "Fixing ownership for config directory..."
    chown -R deluge:deluge "$DELUGE_CONFIG_DIR"
fi

if [ "$(stat -c %u "$DELUGE_DOWNLOAD_DIR")" != "$PUID" ]; then
    echo "Fixing ownership for download directory..."
    chown deluge:deluge "$DELUGE_DOWNLOAD_DIR"
fi

echo "Permission configuration complete."
