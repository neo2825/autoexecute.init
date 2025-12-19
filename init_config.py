#!/usr/bin/env python3
# init_inite_config.py
# Usage:
#   python3 init_inite_config.py               # try to auto-detect removable drive
#   python3 init_inite_config.py --mount /media/usb
#   python3 init_inite_config.py --force

import argparse
import sys
import os
import uuid
from datetime import datetime
import platform

def detect_removable():
    system = platform.system()
    if system == "Windows":
        try:
            import ctypes
            drives = []
            bitmask = ctypes.windll.kernel32.GetLogicalDrives()
            for i in range(26):
                if bitmask & (1 << i):
                    drive = f"{chr(65+i)}:\\"
                    dtype = ctypes.windll.kernel32.GetDriveTypeW(drive)
                    # DRIVE_REMOVABLE = 2
                    if dtype == 2:
                        drives.append(drive)
            return drives[0] if drives else None
        except Exception:
            return None
    else:
        # common mount points on linux/mac
        user = os.getenv("USER") or os.getenv("LOGNAME")
        candidates = []
        if user:
            candidates += [f"/run/media/{user}", f"/media/{user}"]
        candidates += ["/media", "/Volumes"]
        for base in candidates:
            if os.path.isdir(base):
                for entry in os.listdir(base):
                    path = os.path.join(base, entry)
                    if os.path.ismount(path):
                        return path
        return None

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--mount", "-m", help="explicit mount path or drive (e.g. /media/usb or E:\\)")
    p.add_argument("--force", "-f", action="store_true", help="overwrite without prompt")
    args = p.parse_args()

    mount = args.mount
    if not mount:
        mount = detect_removable()

    if not mount:
        print("Could not auto-detect removable drive. Provide --mount /path or E:\\")
        sys.exit(2)

    if not os.path.isdir(mount):
        print(f"Mount path '{mount}' does not exist or is not a directory.")
        sys.exit(3)

    target = os.path.join(mount, "inite.config")
    if os.path.exists(target) and not args.force:
        ans = input(f"File {target} exists. Overwrite? (y/N) ")
        if ans.lower() not in ("y","yes"):
            print("Aborted.")
            sys.exit(0)

    content = (
        "[init]\n"
        f"created_by = {os.getenv('USER') or os.getenv('USERNAME') or 'unknown'}\n"
        f"created_at = {datetime.utcnow().isoformat()}Z\n"
        f"id = {uuid.uuid4()}\n"
        "note = This is an automatically created inite.config\n"
    )

    with open(target, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"Created {target}")

if __name__ == "__main__":
    main()
