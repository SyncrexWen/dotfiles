#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Clean Command
# @raycast.mode silent
# @raycast.packageName Clipboard Tools

export LANG=en_US.UTF-8
pbpaste | sed -E '/^```/d; s/^[[:space:]]*\$[[:space:]]+//' | pbcopy
echo "Cleaned"
