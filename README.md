# Teleport

Personal teleportation tool for files and clipboard content across personal devices.

## Overview

Teleport is a project developed to handle file and clipboard sharing across multiple
devices leveraging a remote machine used as temporary storage.

A local directory (by default `$HOME/teleporter/`) will act as a teleportation device:
any file placed inside this directory will be teleported to a remote machine
(by default under `$HOME/teleporter/`) for future retrieval. Other devices can the
teleport the files locally from the remote machine with a simple command.

The same synchronisation operations can be performed also for clipboard content:
copied data can be shared easily across devices thanks to teleportation/.

Some of the intended uses of Teleport are:

- File synchronisation across devices / file hand-off
- File sharing, while retaining full control and privacy
- Clipboard synchronisation for data sharing (password, api-keys, urls, ...)

## Requirements

Teleport is fully written in shell hence is fully compatible out of the box with
Unix/Linux operating systems. The compatibility can be extended on Windows using
WSL.

There are two possible ways to use Teleport:

- **VPS:** this is the preferred use but requires access to a remote server. PORT
22 for ssh/scp operations must be open and it is suggested to handle connections
only via ssh key pairs.
- **LAN:** Teleport may also be used between machines inside the same local area
network, provided the destination machine is hosting an ssh server with port 22
open. Note that in this case usage will be limited only to the local network and
will not be ubiquitous.

## Installation

To install Teleport simply clone this repository on your local machine.

**Optional but suggested:** in order to be able to also teleport clipboard content
ensure one among the following utilities is available locally: `xclip`, `wl-paste`,
`pbpaste`.

Finally, it is highly recommended to add an alias to the local profile:

`alias tp=PATH_TO_LOCAL_REPOSITORY/teleport.sh`

## Configuration

Prior to usage Teleport should be configured. In order to do so either copy the
default configuration template `teleporter.default.conf` under `$HOME/.config/teleporter.conf`
or run `./teleporter.sh` to automatically generate the configuration file template
under `$HOME/.config/teleporter.conf`. In both cases it is necessary to manually
edit the value of the `REMOTE_MACHINE` variable prior to usage.

## Usage

Teleport can be used to sync local and remote data by simply running:

- `./teleport.sh away` to teleport data from the local teleporter to the remote
teleporter.
- `./teleport.sh here` to teleport data from the remote teleporter to the local
teleporter.
- `./teleport.sh paste` to upload clipboard content online.
- `./teleport.sh copy` to retrieve clipboard content.

For more information on usage run: `./teleport.sh help`.

## Teleportation Rules

Teleportation by default will delete content from the origin teleporter after it
has been moved to the destination teleporter. In order to avoid this behaviour
and keep a copy of the data in the origin teleporter use `./teleport.sh away clone`
and `./teleport.sh here clone` instead.

`./teleport.sh away` operations can be performed in sequence in order to upload
multiple files to the remote teleporter.
