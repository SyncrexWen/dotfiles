#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Join Command
# @raycast.mode silent
# @raycast.packageName Clipboard Tools

export LANG=en_US.UTF-8
pbpaste | perl -0pe 's/\s*\\\n\s*/ /g; s/^\s+|\s+$//g' | pbcopy
echo "Joined"
