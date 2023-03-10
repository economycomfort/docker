#!/usr/bin/env bash
#
set -e

source .env
ln -sf $APPDATA appdata
echo "Symlink to ${APPDATA} created."

