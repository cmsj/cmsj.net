#!/bin/bash

set -eu

echo "Copying files to gnubert..."
rsync -qrx --stats output/ gnubert.local:/srv/tank/docker/ipfs/staging/cmsj.net

echo "Publishing files to IPFS..."
HASH=$(ssh gnubert.local docker exec ipfs ipfs add -Q -r /export/cmsj.net | tr -d '\r')

echo "Linking files to cmsj.net..."
ssh gnubert.local docker exec ipfs ipfs name publish --key=cmsj.net "${HASH}"
