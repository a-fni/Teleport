#!/usr/bin/bash

# Fail whole script in case of errors
set -eou pipefail

# Reading configuration file
source teleporter.conf

# Check if local teleporter exists
if [[ ! -d "$TELEPORTER_PATH/$TELEPORTER_NAME" ]]; then
  echo "Local teleporter does not exist, nothing to teleport."
  echo "Creating an empty one for next teleportation"
  mkdir "$TELEPORTER_PATH/$TELEPORTER_NAME"
  exit 1
fi

# Usage string for documentation purtposes
USAGE="./teleport.sh away|here|copy|paste [clone]"


# Define generic clipboard operation to ensure multiplaform
clipcopy() {
  if command -v wl-copy &>/dev/null; then
    wl-copy "$@"
  elif command -v xclip &>/dev/null; then
    xclip -selection clipboard "$@"
  elif command -v pbcopy &>/dev/null; then  # macOS
    pbcopy "$@"
  else
    echo "No clipboard tool found" >&2
  fi
}

clippaste() {
  if command -v wl-paste &>/dev/null; then
    wl-paste --no-newline "$@"
  elif command -v xclip &>/dev/null; then
    xclip -selection clipboard -o "$@"
  elif command -v pbpaste &>/dev/null; then  # macOS
    pbpaste "$@"
  else
    echo "No clipboard tool found" >&2
  fi
}


echo "Connecting to remote portal..."

# Teleporting operations
if [[ "$#" == 0 ]]; then
  echo "No arguments supplied"
  echo "$USAGE"
elif [[ "$#" == 1 && "$1" == "help" ]]; then
  echo "$USAGE"
elif [[ "$#" == 2 && "$2" != "clone" ]]; then
  echo "Unknown argument $2 passed."
  echo "$USAGE"
elif [[ "$1" == "away" ]]; then
  scp -r "$TELEPORTER_PATH/$TELEPORTER_NAME"/* "$REMOTE_MACHINE:$TELEPORTER_PATH/$TELEPORTER_NAME"/
  if [[ "$#" == 1 ]]; then
    rm -rf "$TELEPORTER_PATH/$TELEPORTER_NAME"/*
    #mkdir -p "$TELEPORTER_PATH/.teleported"
    #rm -rf "$TELEPORTER_PATH/.teleported"/*
    #mv "$TELEPORTER_PATH/$TELEPORTER_NAME"/* "$TELEPORTER_PATH/.teleported"/
    echo "Teleportation completed!"
  elif [[ "$2" == "clone" ]]; then
    echo "Clonation completed!"
  fi
elif [[ "$1" == "here" ]]; then
  scp -r "$REMOTE_MACHINE:$TELEPORTER_PATH/$TELEPORTER_NAME"/* "$TELEPORTER_PATH/$TELEPORTER_NAME"/
  if [[ "$#" == 1 ]]; then
    ssh "$REMOTE_MACHINE" "rm -rf $TELEPORTER_PATH/$TELEPORTER_NAME/*"
    echo "Teleportation completed!"
  elif [[ "$2" == "clone" ]]; then
    echo "Clonation completed!"
  fi
elif [[ "$1" == "copy" ]]; then
  scp "$REMOTE_MACHINE:$CLIPBOARD_PATH/$CLIPBOARD_NAME" "$CLIPBOARD_PATH/$CLIPBOARD_NAME"
  cat "$CLIPBOARD_PATH/$CLIPBOARD_NAME" | clipcopy
elif [[ "$1" == "paste" ]]; then
  clippaste > "$CLIPBOARD_PATH/$CLIPBOARD_NAME"
  scp "$CLIPBOARD_PATH/$CLIPBOARD_NAME" "$REMOTE_MACHINE:$CLIPBOARD_PATH/$CLIPBOARD_NAME"
else
  echo "Unknown argument $1 passed."
  echo "$USAGE"
fi

