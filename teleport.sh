# Fail whole script in case of errors
set -eou pipefail

# Reading configuration file
source teleporter.conf

# Check if local teleporter exists
if [[ ! -d "$TELEPORTER_LOCAL_PATH/$TELEPORTER_NAME" ]]; then
  echo "Local teleporter does not exist, nothing to teleport."
  echo "Creating an empty one for next teleportation"
  mkdir "$TELEPORTER_LOCAL_PATH/$TELEPORTER_NAME"
  exit 1
fi

# Usage string for documentation purtposes
PROLOGUE="== Teleport =="
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


# Teleporting operations
if [[ "$#" == 0 ]]; then
  echo ""
  echo "ERROR: no teleportation arguments supplied"
  echo ""
  echo "$USAGE"
  echo ""
elif [[ "$#" == 1 && "$1" == "help" ]]; then
  echo ""
  echo "$PROLOGUE"
  echo ""
  echo "$USAGE"
  echo ""
elif [[ "$#" == 2 && "$2" != "clone" ]]; then
  echo ""
  echo "ERROR: unknown teleportation argument \"$2\" supplied"
  echo ""
  echo "$USAGE"
  echo ""
elif [[ "$1" == "away" ]]; then
  echo ""
  echo "Operning connection to remote portal..."
  echo ""
  scp -r "$TELEPORTER_LOCAL_PATH/$TELEPORTER_NAME"/* "$REMOTE_MACHINE:$TELEPORTER_REMOTE_PATH/$TELEPORTER_NAME"/
  if [[ "$#" == 1 ]]; then
    rm -rf "$TELEPORTER_LOCAL_PATH/$TELEPORTER_NAME"/*
    #mkdir -p "$TELEPORTER_PATH/.teleported"
    #rm -rf "$TELEPORTER_PATH/.teleported"/*
    #mv "$TELEPORTER_PATH/$TELEPORTER_NAME"/* "$TELEPORTER_PATH/.teleported"/
    echo "Teleportation completed!"
  elif [[ "$2" == "clone" ]]; then
    echo "Clonation completed!"
  fi
  echo ""
  echo "Closing connectin with remote teleporter"
  echo ""
elif [[ "$1" == "here" ]]; then
  echo ""
  echo "Opening connection to remote portal..."
  echo ""
  scp -r "$REMOTE_MACHINE:$TELEPORTER_REMOTE_PATH/$TELEPORTER_NAME"/* "$TELEPORTER_LOCAL_PATH/$TELEPORTER_NAME"/
  if [[ "$#" == 1 ]]; then
    ssh "$REMOTE_MACHINE" "rm -rf $TELEPORTER_REMOTE_PATH/$TELEPORTER_NAME/*"
    echo "Teleportation completed!"
  elif [[ "$2" == "clone" ]]; then
    echo "Clonation completed!"
  fi
  echo ""
  echo "Closing connection with remote teleporter"
  echo ""
elif [[ "$1" == "copy" ]]; then
  scp "$REMOTE_MACHINE:$CLIPBOARD_REMOTE_PATH/$CLIPBOARD_NAME" "$CLIPBOARD_LOCAL_PATH/$CLIPBOARD_NAME"
  cat "$CLIPBOARD_LOCAL_PATH/$CLIPBOARD_NAME" | clipcopy
elif [[ "$1" == "paste" ]]; then
  clippaste > "$CLIPBOARD_LOCAL_PATH/$CLIPBOARD_NAME"
  scp "$CLIPBOARD_LOCAL_PATH/$CLIPBOARD_NAME" "$REMOTE_MACHINE:$CLIPBOARD_REMOTE_PATH/$CLIPBOARD_NAME"
else
  echo ""
  echo "ERROR: unknown teleportation argument \"$1\" supplied"
  echo ""
  echo "$USAGE"
  echo ""
fi

