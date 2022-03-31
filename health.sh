#!/bin/ash

# Get mount point used by Fuse
_MOUNT_POINT="$(awk '{if ($3 == "fuse") {print $2}}' /proc/mounts)"
[ -z "${_MOUNT_POINT}" ] && (printf "No fuse mount point\n"; exit 1)

# Check if directory is not null
[ -n "$(ls -1A "${_MOUNT_POINT}")" ] || exit 2
