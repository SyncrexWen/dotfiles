#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.title Split Flags
# @raycast.mode silent
# @raycast.packageName Clipboard Tools

export LANG=en_US.UTF-8
pbpaste | perl -0pe 's/(?<=\S)[ \t]+(--?[A-Za-z])/ \\\n  $1/g' | pbcopy
echo "Split"
