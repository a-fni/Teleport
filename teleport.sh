#!/usr/bin/bash

# Fail whole script in case of errors
set -eou pipefail

# Reading configuration file
source teleporter.conf

# Check if local teleporter exists
if [[ ! -d "$LOCAL_TELEPORTER_PATH/teleporter" ]]; then
  echo "Local teleporter does not exist, nothing to teleport."
  echo "Creating an empty one for next teleportation"
  mkdir "$LOCAL_TELEPORTER_PATH/teleporter"
  exit 1
fi

# Usage string for documentation purtposes
USAGE="./teleport.sh away|here|copy|paste [clone]"

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
  scp -r "$LOCAL_TELEPORTER_PATH/teleporter"/* "$REMOTE_MACHINE:$REMOTE_TELEPORTER_PATH/.teleporter"
  if [[ "$#" == 1 ]]; then
    mkdir -p "$LOCAL_TELEPORTER_PATH/.teleported"
    rm -rf "$LOCAL_TELEPORTER_PATH/.teleported"/*
    mv "$LOCAL_TELEPORTER_PATH/teleporter"/* "$LOCAL_TELEPORTER_PATH/.teleported"/
    echo "Teleportation completed!"
  elif [[ "$2" == "clone" ]]; then
    echo "Clonation completed!"
  fi
elif [[ "$1" == "here" ]]; then
  scp -r "$REMOTE_MACHINE:$REMOTE_TELEPORTER_PATH/.teleporter"/* "$LOCAL_TELEPORTER_PATH/teleporter/"
  if [[ "$#" == 1 ]]; then
    ssh "$REMOTE_MACHINE" "rm -rf $REMOTE_TELEPORTER_PATH/.teleporter/*"
    echo "Teleportation completed!"
  elif [[ "$2" == "clone" ]]; then
    echo "Clonation completed!"
  fi
elif [[ "$1" == "copy" ]]; then
  echo "Copy"
elif [[ "$1" == "paste" ]]; then
  echo "paste"
else
  echo "Unknown argument $1 passed."
  echo "$USAGE"
fi

