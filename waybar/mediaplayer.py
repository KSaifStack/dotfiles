#!/usr/bin/env python3
import subprocess

try:
    status = subprocess.check_output(["playerctl", "status"]).decode().strip()
    if status == "Playing":
        title = subprocess.check_output(["playerctl", "metadata", "--format", "{{artist}} - {{title}}"]).decode().strip()
        print(title, flush=True)
    else:
        print("", flush=True)
except:
    print("", flush=True)
