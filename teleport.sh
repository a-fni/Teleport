##
## Teleport - main logic script (basically an SCP wrapper with custom behaviour)
##
## v1.0: basic teleportation and clipboard operations implemented and working
##
## Author: @afni / Andrea Ferrarini (https://github.com/a-fni)
##

# Fail whole script in case of errors
set -eou pipefail


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
  ("$1" != "away" && "$1" != "here" && "$1" != "copy" && \
  "$1" != "paste" && "$1" != "limbo" && "$1" != "void") ]]; then
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


# Check for illegal configuration paramenters
if [[ "$USE_ENCRYPTION" == true && "$USE_COMPRESSION" != true ]]; then
  echo "WARNING: can't use encryption without compression ==> update your configuration file."
  echo ""
  echo "Either set USE_COMPRESSION=true or set USE_ENCRYPTION=false."
  echo "Aborting teleportation operations due to illegal parameter combination."
  exit 1
fi


# Preparing clipboard file if pasting
if [[ "$1" == "paste" ]]; then
  clippaste > "$CLIPBOARD_LOCAL_PATH/$CLIPBOARD_NAME"
fi


# If teleporting, handle local / remote teleporter locations
if [[ "$1" == "away" || "$1" == "here" || "$1" == "limbo" || "$1" == "void" ]]; then
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


# Constructing paths in variables
tp_local="$TELEPORTER_LOCAL_PATH/$TELEPORTER_NAME"
tp_remote="$TELEPORTER_REMOTE_PATH/$TELEPORTER_NAME"
clip_local="$CLIPBOARD_LOCAL_PATH/$CLIPBOARD_NAME"
clip_remote="$CLIPBOARD_REMOTE_PATH/$CLIPBOARD_NAME"


# Perform compression if requested
if [[ $USE_COMPRESSION == true ]]; then
  # Check whether pasting clipboard or teleporting files
  if [[ "$1" == "away" ]]; then
    echo ""
    echo "Compressing data..."
    echo ""
    tar -czvf "$tp_local.tar.gz" -C "$tp_local" .
    tp_local="$tp_local.tar.gz"
    echo ""
    echo "Compression completed!"
    echo ""
  elif [[ "$1" == "paste" ]]; then
    echo ""
    echo "Compressing clipboard..."
    echo ""
    tar -czvf "$clip_local.tar.gz" "$clip_local"
    clip_local="$clip_local.tar.gz"
    echo ""
    echo "Compression completed!"
    echo ""
  elif [[ "$1" == "copy" ]]; then
    clip_local="$clip_local.tar.gz"
  fi
elif [[ "$1" == "away" ]]; then
  # If not compressing, the local path should be slightly updated
  tp_local="$tp_local/*"
fi

# Perform encryption if requested
if [[ "$USE_ENCRYPTION" == true ]]; then
  if [[ "$1" == "away" ]]; then 
    echo ""
    echo "Encrypting data..."
    echo ""
    gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 -o "$tp_local.gpg" "$tp_local" <<< "$ENCRYPTION_KEY"
    tp_local="$tp_local.gpg"
    echo ""
    echo "Data encrypted!"
    echo ""
  elif [[ "$1" == "paste" ]]; then
    echo ""
    echo "Encrypting clipboard..."
    echo ""
    gpg --batch --yes --passphrase-fd 0 --symmetric --cipher-algo AES256 -o "$clip_local.gpg" "$clip_local" <<< "$ENCRYPTION_KEY"
    clip_local="$clip_local.gpg"
    echo ""
    echo "Clipboard encrypted!"
    echo ""
  elif [[ "$1" == "copy" ]]; then
    clip_local="$clip_local.gpg"
  fi
fi

# If teleporting here, we need to slightly update our path
if [[ "$1" == "here" ]]; then
  tp_local="$tp_local/"
fi


# Teleporting operations
if [[ "$1" == "limbo" ]]; then
  echo ""
  echo "Opening connection to remote teleporter..."
  echo ""
  ssh "$REMOTE_MACHINE" \
    "echo '  >> Files in remote teleporter:' &&
    ls -1A $tp_remote &&
    echo -e '\n  >> Remote clipboard content:' &&
    cat $clip_remote
    echo ''"
  echo ""
  echo "Closing connection with remote teleporter"
  echo ""
elif [[ "$1" == "void" ]]; then
  echo ""
  echo "Opening connection to remote teleporter..."
  echo ""
  ssh "$REMOTE_MACHINE" \
    "rm -rf $tp_remote/* &&
    echo '' > $clip_remote"
  echo "All remote data voided irreversively"
  echo "Closing connection with remote teleporter"
  echo ""
elif [[ "$1" == "away" ]]; then
  echo ""
  echo "Operning connection to remote teleporter..."
  echo ""
  scp -r $tp_local "$REMOTE_MACHINE:$tp_remote"/
  echo ""
  if [[ "$#" == 1 ]]; then
    # Using full path manually in case compression and/or encryption are used
    rm -rf "$TELEPORTER_LOCAL_PATH/$TELEPORTER_NAME"/*
    echo "Teleportation completed!"
  elif [[ "$2" == "clone" ]]; then
    echo "Clonation completed!"
  fi
  echo "Closing connection with remote teleporter"
  echo ""
elif [[ "$1" == "here" ]]; then
  echo ""
  echo "Opening connection to remote teleporter..."
  echo ""
  scp -r "$REMOTE_MACHINE:$tp_remote"/* $tp_local
  echo ""
  if [[ "$#" == 1 ]]; then
    ssh "$REMOTE_MACHINE" "rm -rf $tp_remote/*"
    echo "Teleportation completed!"
  elif [[ "$2" == "clone" ]]; then
    echo "Clonation completed!"
  fi
  echo "Closing connection with remote teleporter"
  echo ""
elif [[ "$1" == "copy" ]]; then
  scp "$REMOTE_MACHINE:$clip_remote" "$clip_local"
elif [[ "$1" == "paste" ]]; then
  scp "$clip_local" "$REMOTE_MACHINE:$clip_remote"
fi


# If encryption requested decrypting
if [[ "$USE_ENCRYPTION" == true && "$1" == "here" ]]; then
  echo ""
  echo "Beginning decryption of retrieved data..."
  echo ""
  gpg --batch --yer --passhprase-fd 0 -o "$tp_local/$TELEPORTER_NAME.tar.gz" "$tp_local/$TELEPORTER_NAME.tar.gz.gpg" <<< "$ENCRYPTION_KEY"
  rm -rf "$tp_local/$TELEPORTER_NAME.tar.gz.gpg"
  echo ""
  echo "Decryption completed!"
  echo ""
fi

if [[ "$USE_ENCRYPTION" == true && "$1" == "copy" ]]; then
  echo ""
  echo "Beginning decryption of retrieved clipboard..."
  echo ""
  gpg --batch --yer --passhprase-fd 0 -o "$CLIPBOARD_LOCAL_PATH/$CLIPBOARD_NAME.tar.gz" "$CLIPBOARD_LOCAL_PATH/$CLIPBOARD_NAME.tar.gz.gpg" <<< "$ENCRYPTION_KEY"
  rm -rf "$CLIPBOARD_LOCAL_PATH/$CLIPBOARD_NAME.tar.gz.gpg"
  echo ""
  echo "Decryption completed!"
  echo ""
fi

# If compression requested decompressing
if [[ "$USE_COMPRESSION" == true && "$1" == "here" ]]; then
  echo ""
  echo "Beginning decompression of retrieved data..."
  echo ""
  tar -xzvf "$tp_local/$TELEPORTER_NAME.tar.gz" -C "$tp_local"
  rm -rf "$tp_local/$TELEPORTER_NAME.tar.gz"
  echo ""
  echo "Decompression completed!"
  echo ""
fi

if [[ "$USE_COMPRESSION" == true && "$1" == "copy" ]]; then
  echo ""
  echo "Beginning decompression of retrieved clipboard..."
  echo ""
  tar -xzvf "$CLIPBOARD_LOCAL_PATH/$CLIPBOARD_NAME.tar.gz" #-C "$CLIPBOARD_LOCAL_PATH" "$CLIPBOARD_NAME"
  rm -rf "$CLIPBOARD_LOCAL_PATH/$CLIPBOARD_NAME.tar.gz"
  echo ""
  echo "Decompression completed!"
  echo ""
fi


# Cleaning up for compression
if [[ "$USE_COMPRESSION" == true && "$1" == "away" ]]; then
  echo ""
  echo "Cleaning up after compression..."
  rm -rf "$TELEPORTER_LOCAL_PATH/$TELEPORTER_NAME.tar.gz"
  echo "Compression clean up completed!"
  echo ""
fi

if [[ "$USE_COMPRESSION" == true && "$1" == "paste" ]]; then
  echo ""
  echo "Cleaning up after compression..."
  rm -rf "$CLIPBOARD_LOCAL_PATH/$CLIPBOARD_NAME.tar.gz"
  echo "Compression clean up completed!"
  echo ""
fi


# Cleaning up for encryption
if [[ "$USE_ENCRYPTION" == true && "$1" == "away" ]]; then
  echo ""
  echo "Cleaning up after encryption..."
  rm -rf "$TELEPORTER_LOCAL_PATH/$TELEPORTER_NAME.tar.gz.gpg"
  echo "Encryption clean up completed!"
  echo ""
fi

if [[ "$USE_ENCRYPTION" == true && "$1" == "paste" ]]; then
  echo ""
  echo "Cleaning up after encryption..."
  rm -rf "$CLIPBOARD_LOCAL_PATH/$CLIPBOARD_NAME.tar.gz.gpg"
  echo "Encryption clean up completed!"
  echo ""
fi


# Retrieving clipboard content at end of pipeline
if [[ "$1" == "copy" ]]; then
  cat "$clip_local" | clipcopy
fi

