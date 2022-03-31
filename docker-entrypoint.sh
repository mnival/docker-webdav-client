#! /usr/bin/env sh

# Where are we going to mount the remote webdav resource in our container.
DEST=${WEBDRIVE_MOUNT:-/mnt/webdrive}

# Check variables and defaults
if [ -z "${WEBDRIVE_URL}" ]; then
    echo "No URL specified!"
    exit
fi
if [ -z "${WEBDRIVE_USERNAME}" ]; then
    echo "No username specified, is this on purpose?"
fi
if [ -n "${WEBDRIVE_PASSWORD_FILE}" ]; then
    WEBDRIVE_PASSWORD=$(read ${WEBDRIVE_PASSWORD_FILE})
fi
if [ -z "${WEBDRIVE_PASSWORD}" ]; then
    echo "No password specified, is this on purpose?"
fi

# Create secrets file and forget about the password once done (this will have
# proper effects when the PASSWORD_FILE-version of the setting is used)
echo "$DEST $WEBDRIVE_USERNAME $WEBDRIVE_PASSWORD" >> /etc/davfs2/secrets
unset WEBDRIVE_PASSWORD

# Add davfs2 options out of all the environment variables starting with DAVFS2_
# at the end of the configuration file. Nothing is done to check that these are
# valid davfs2 options, use at your own risk.
# Remove previous Custom configuration
sed -i '/# CUSTOM/d' /etc/davfs2/davfs2.conf
if [ -n "$(env | grep "DAVFS2_")" ]; then
    echo "[$DEST] # CUSTOM" >> /etc/davfs2/davfs2.conf
    for VAR in $(env); do
        if [ -n "$(echo "$VAR" | grep -E '^DAVFS2_')" ]; then
            OPT_NAME=$(echo "$VAR" | sed -r "s/DAVFS2_([^=]*)=.*/\1/g" | tr '[:upper:]' '[:lower:]')
            VAR_FULL_NAME=$(echo "$VAR" | sed -r "s/([^=]*)=.*/\1/g")
            VAL=$(eval echo \$$VAR_FULL_NAME)
            echo "$OPT_NAME $VAL # CUSTOM" >> /etc/davfs2/davfs2.conf
        fi
    done
fi

# Create destination directory if it does not exist.
if [ ! -d $DEST ]; then
    mkdir -p $DEST
fi

# Backwards compatibility
if [ ! -z "${OWNER}" ]; then
  UID="${OWNER}"
fi

# Default value for UID et GID
UID=${UID:-0}
GID=${GID:-100}

# Check if user and group exist
egrep -q "x:${GID}:" /etc/group
if [ $? -ne 0 ]; then
  addgroup -g ${GID} -S webdav
fi

egrep -q "x:${UID}:" /etc/passwd
if [ $? -ne 0 ]; then
  adduser -u ${UID} -S -D -H -G webdav webdav
fi

# Remove previous pid if stop is not correct
[ -n "$(ls -1 /var/run/mount.davfs/*.pid 2>/dev/null)" ] && rm /var/run/mount.davfs/*.pid

# Mount and verify that something is present. davfs2 always creates a lost+found
# sub-directory, so we can use the presence of some file/dir as a marker to
# detect that mounting was a success. Execute the command on success.
mount -t davfs $WEBDRIVE_URL $DEST -o uid=${UID},gid=${GID},dir_mode=755,file_mode=755
if [ -n "$(ls -1A $DEST)" ]; then
    echo "Mounted $WEBDRIVE_URL onto $DEST"
    . trap.sh
    tail -f /dev/null
else
    echo "Nothing found in $DEST, giving up!"
fi
