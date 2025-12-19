#!/usr/bin/env bash
# init_inite_config.sh
# Usage:
#   ./init_inite_config.sh                # try to auto-detect removable drive
#   ./init_inite_config.sh /path/to/mount # use explicit mount path
#   ./init_inite_config.sh --force        # auto-detect and overwrite without prompt

set -euo pipefail

FORCE=0
TARGET=""

# parse args
for arg in "$@"; do
  case "$arg" in
    --force|-f) FORCE=1 ;;
    --help|-h) echo "Usage: $0 [mount_path] [--force]"; exit 0 ;;
    *) TARGET="$arg" ;;
  esac
done

# helper: detect removable mountpoint (common locations)
detect_mount() {
  # prefer /run/media/$USER/* then /media/$USER/* then /media/*
  if [ -n "${XDG_RUNTIME_DIR:-}" ]; then
    local user
    user=$(id -un)
    for base in "/run/media/$user" "/media/$user" "/media"; do
      if [ -d "$base" ]; then
        for d in "$base"/*; do
          [ -d "$d" ] && echo "$d" && return 0
        done
      fi
    done
  fi

  # fallback: use lsblk to find removable devices with mountpoint
  if command -v lsblk >/dev/null 2>&1; then
    while IFS= read -r line; do
      mountpoint=$(awk '{print $7}' <<<"$line")
      rmflag=$(awk '{print $5}' <<<"$line")
      if [ -n "$mountpoint" ] && [ "$rmflag" = "1" ]; then
        echo "$mountpoint" && return 0
      fi
    done < <(lsblk -o NAME,TYPE,RM,SIZE,RO,MOUNTPOINT -P | sed -n 's/ / /p')
  fi

  return 1
}

if [ -n "$TARGET" ]; then
  MOUNT="$TARGET"
else
  MOUNT="$(detect_mount || true)"
fi

if [ -z "$MOUNT" ]; then
  echo "Error: could not detect a removable drive. Specify the mount path as argument."
  exit 2
fi

if [ ! -d "$MOUNT" ]; then
  echo "Error: mount path '$MOUNT' does not exist or is not a directory."
  exit 3
fi

FILE="$MOUNT/inite.config"

if [ -f "$FILE" ] && [ "$FORCE" -ne 1 ]; then
  read -rp "File $FILE exists. Overwrite? (y/N) " yn
  case "$yn" in
    [Yy]*) ;;
    *) echo "Aborted."; exit 0 ;;
  esac
fi

uuid=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || (python3 - <<'PY'
import uuid,sys
print(uuid.uuid4())
PY
))
timestamp=$(date --iso-8601=seconds 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

cat > "$FILE" <<EOF
[init]
created_by = $(id -un)
created_at = $timestamp
id = $uuid
note = This is an automatically created inite.config
EOF

echo "Created $FILE"
