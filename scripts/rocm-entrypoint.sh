#!/bin/sh
set -e
# Docker creates named volumes root-owned on first use. Nothing else in this
# image chowns them, so a fresh /app/data or HF cache volume is unwritable
# once we drop to the non-root voicebox user below -- fix that here.
chown -R voicebox:voicebox /app/data /home/voicebox/.cache 2>/dev/null || true

# Join whatever groups own the mounted GPU nodes so /dev/kfd and /dev/dri work
# on any host (no RENDER_GID/VIDEO_GID needed), then drop to the app user.
for dev in /dev/kfd /dev/dri/render*; do
    [ -e "$dev" ] || continue
    gid=$(stat -c %g "$dev")
    grp=$(getent group "$gid" | cut -d: -f1)
    [ -n "$grp" ] || {
        grp="gpu$gid"
        groupadd -g "$gid" "$grp"
    }
    usermod -aG "$grp" voicebox
done
exec gosu voicebox "$@"
