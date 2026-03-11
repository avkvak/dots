#!/bin/bash
cliphist list | fuzzel -d -p "  " --width 40 | cliphist decode | wl-copy