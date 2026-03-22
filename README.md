# Teleport

Teleport is a personal and fully customisable cloud storage manager. Share files
and clipboard content across devices seamlessly not compromising privacy, confidentiality
and control over all shared data.

## Overview

Teleport is a project developed to handle file and clipboard sharing across multiple
devices leveraging a remote machine used as storage. The concept is identical to
that of a cloud provider, however by self-hosting your remote storage and using
Teleport full control over all stored files is retained, which increases privacy,
confidentiality and customisation of the service. In particular, one is able to
chose the provider of their liking, the amount of storage they require, generally
speaking at a lower per GiB price and with potentially also other features included
(a personal VPS doesn't provide only storage).

A local `~/teleporter` directory will be used to store synchronised data (both downstream
and upstream). As the name suggests, the directory will act as a teleport device,
namely local [...].

Some of the intended uses of Teleport are:

- File synchronisation across devices / file hand-off
- File sharing
- Clipboard synchronisation for data sharing
- Remote backup of File

## Requirements

Teleport is fully written in Python and Bash hence is fully compatible out of the
box with Unix/Linux operating systems. The compatibility can be extended on Windows
using WSL.

There are two possible ways to use Teleport:

- **VPS:** this is the preferred use but requires access to a remote server. PORT
22 for ssh/scp opreations must be
open and it is suggested to handle connections only via ssh key pairs.
- **LAN:** Teleport may also be used on any local machine with a port 22 open for
ssh/scp operations within a local area network, however usage will be restricted
and not ubiquitous.

## Installation

To install Teleport simply clone this repository on your local machine and install
`xclip` if you also want clipboard synchronisation.

## Configuration

Prior to usage Teleport should be configured. A [...].

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
has been moved to the destination teleporter. In order to keep avoid this behaviour
and keep a copy of the data in the origin teleporter use `./teleport.sh away --clone`
and `./teleport.sh here --clone` instead.

`./teleport.py away` operations can be performed in sequence in order to upload
multiple files to the remote teleporter.
