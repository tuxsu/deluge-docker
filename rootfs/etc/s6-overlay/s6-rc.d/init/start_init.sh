#!/command/with-contenv sh

PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Checking permissions (Target UID: $PUID, GID: $PGID)..."

if [ "$PUID" -eq 0 ] || [ "$PGID" -eq 0 ]; then
    echo "PUID/PGID set to 0. Running as root."
    mkdir -p "$DELUGE_CONFIG_DIR" "$DELUGE_DOWNLOAD_DIR"
    exit 0
fi

if ! grep -q "^deluge:" /etc/group; then
    EXISTING_GROUP=$(grep ":$PGID:" /etc/group | cut -d: -f1)
    if [ -n "$EXISTING_GROUP" ]; then
        echo "Warning: GID $PGID is used by '$EXISTING_GROUP'. Renaming..."
        sed -i "s/^$EXISTING_GROUP:/deluge:/" /etc/group
    else
        echo "Creating group 'deluge' with GID $PGID..."
        addgroup -g "$PGID" -S deluge 2>/dev/null || groupadd -g "$PGID" deluge
    fi
else
    sed -i "s/^deluge:x:[0-9]\+:/deluge:x:$PGID:/" /etc/group
fi

if ! grep -q "^deluge:" /etc/passwd; then
    EXISTING_USER=$(grep "x:$PUID:" /etc/passwd | cut -d: -f1)
    if [ -n "$EXISTING_USER" ]; then
        echo "Warning: UID $PUID is used by '$EXISTING_USER'. Renaming..."
        sed -i "s/^$EXISTING_USER:/deluge:/" /etc/passwd
    else
        echo "Creating user 'deluge' with UID $PUID..."
        adduser -u "$PUID" -G deluge -S -D -H deluge 2>/dev/null || \
        useradd -u "$PUID" -g deluge -m -s /bin/sh deluge
    fi
else
    sed -i "s/^deluge:x:[0-9]\+:[0-9]\+:/deluge:x:$PUID:$PGID:/" /etc/passwd
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
