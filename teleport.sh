##
## Teleport - main logic script (basically an SCP wrapper with custom behaviour)
##
## v1.0: basic teleportation and clipboard operations implemented and working
##
## Author: @afni / Andrea Ferrarini (https://github.com/a-fni)
##

# Fail whole script in case of errors
set -eou pipefail


# Reading prologue and usage strings for documentation purtposes
PROLOGUE=$(cat ./prologue.txt)
USAGE=$(cat ./usage.txt)

# Basic command line input sanity check
if [[ "$#" == 0 ]]; then
  echo "$PROLOGUE"
  echo ""
  echo "  >>> No teleportation arguments supplied"
  echo ""
  echo "$USAGE"
  echo ""
  exit 0
elif [[ "$#" == 1 && "$1" == "help" ]]; then
  echo "$PROLOGUE"
  echo ""
  echo "$USAGE"
  echo ""
  exit 0
elif [[ "$#" == 1 && \
  ("$1" != "away" && "$1" != "here" && "$1" != "copy" && "$1" != "paste") ]]; then
  echo ""
  echo "ERROR: unknown teleportation argument \"$1\" supplied"
  echo ""
  echo "$USAGE"
  echo ""
  exit 1
elif [[ "$#" == 2 && "$2" != "clone" ]]; then
  echo ""
  echo "ERROR: unknown teleportation argument \"$2\" supplied"
  echo ""
  echo "$USAGE"
  echo ""
  exit 1
elif [[ "$#" > 2 ]]; then
  echo ""
  echo "ERROR: too many arguments have been supplied"
  echo ""
  echo "$USAGE"
  echo ""
  exit 1
fi


# Configuration file: reading from ~/.config/teleporter.conf if present
if [[ -f "$HOME/.config/teleporter.conf" ]]; then
  source $HOME/.config/teleporter.conf
else
  # If not found, advicing the user and quitting
  echo "WARNING: no configuration file found under \$HOME/.config/teleporter.conf. Using the default configuration file is not suggested."
  echo ""
  echo "A copy of the default configuration file has been created under \$HOME/.config/teleporter.conf, but requires manual editing before usage."
  echo "Aborting teleportation operations. Please manually inspect teleporter configuration prior to next run."
  cp ./teleporter.default.conf $HOME/.config/teleporter.conf
  exit 1
fi


# Check for illegal argument + configuration combinations
if [[ "$#" == 2 && ("$1" == "away" || "$1" == "here") && \
  ("$USE_ENCRYPTION" == true || "$USE_COMPRESSION" == true) ]]; then
  echo ""
  echo "ERROR: not allowed to clone while also using either encryption or compression"
  echo ""
  exit 1
fi


# If teleporting, handle local / remote teleporter locations
if [[ "$1" == "away" || "$1" == "here" ]]; then
  # Handle local teleporter location
  if [[ "$ALWAYS_REQUEST_LOCAL_TELEPORTER_PATH" == true ]]; then
    echo "  >>> Insert local teleporter path:"
    read TELEPORTER_LOCAL_PATH
  fi
  
  # Handle remote teleporter location
  if [[ "$ALWAYS_REQUEST_REMOTE_TELEPORTER_PATH" == true ]]; then
    echo "  >>> Insert remote teleporter path:"
    read TELEPORTER_REMOTE_PATH
  fi
fi

# Check if REMOTE_MACHINE variable has been set
if [[ -z "$REMOTE_MACHINE" && "$ALWAYS_REQUEST_REMOTE_MACHINE" == false ]]; then
  echo "WARNING: REMOTE_MACHINE variable has not been set in \$HOME/.config/teleporter.conf, unable to teleport data."
  echo "Update the configuration file to contain teleportation destination."
  exit 1
elif [[ "$ALWAYS_REQUEST_REMOTE_MACHINE" == true ]]; then
  echo "  >>> Insert remote destination ssh connection string:"
  read REMOTE_MACHINE
fi


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


# Not implemented warning messages
if [[ "$USE_ENCRYPTION" == true || "$USE_COMPRESSION" == true ]]; then
  echo "WARNING: compression and encryption are currently not implemented yet..."
fi


# Teleporting operations
if [[ "$1" == "away" ]]; then
  echo ""
  echo "Operning connection to remote portal..."
  echo ""
  scp -r "$TELEPORTER_LOCAL_PATH/$TELEPORTER_NAME"/* "$REMOTE_MACHINE:$TELEPORTER_REMOTE_PATH/$TELEPORTER_NAME"/
  echo ""
  if [[ "$#" == 1 ]]; then
    rm -rf "$TELEPORTER_LOCAL_PATH/$TELEPORTER_NAME"/*
    echo "Teleportation completed!"
  elif [[ "$2" == "clone" ]]; then
    echo "Clonation completed!"
  fi
  echo "Closing connection with remote teleporter"
  echo ""
elif [[ "$1" == "here" ]]; then
  echo ""
  echo "Opening connection to remote portal..."
  echo ""
  scp -r "$REMOTE_MACHINE:$TELEPORTER_REMOTE_PATH/$TELEPORTER_NAME"/* "$TELEPORTER_LOCAL_PATH/$TELEPORTER_NAME"/
  echo ""
  if [[ "$#" == 1 ]]; then
    ssh "$REMOTE_MACHINE" "rm -rf $TELEPORTER_REMOTE_PATH/$TELEPORTER_NAME/*"
    echo "Teleportation completed!"
  elif [[ "$2" == "clone" ]]; then
    echo "Clonation completed!"
  fi
  echo "Closing connection with remote teleporter"
  echo ""
elif [[ "$1" == "copy" ]]; then
  scp "$REMOTE_MACHINE:$CLIPBOARD_REMOTE_PATH/$CLIPBOARD_NAME" "$CLIPBOARD_LOCAL_PATH/$CLIPBOARD_NAME"
  cat "$CLIPBOARD_LOCAL_PATH/$CLIPBOARD_NAME" | clipcopy
elif [[ "$1" == "paste" ]]; then
  clippaste > "$CLIPBOARD_LOCAL_PATH/$CLIPBOARD_NAME"
  scp "$CLIPBOARD_LOCAL_PATH/$CLIPBOARD_NAME" "$REMOTE_MACHINE:$CLIPBOARD_REMOTE_PATH/$CLIPBOARD_NAME"
fi

