#!/bin/bash

set -eu

echo "Copying files to gnubert..."
rsync -qrx --stats output/ gnubert.local:/srv/tank/docker/ipfs/staging/cmsj.net

echo "Publishing files to IPFS..."
HASH=$(ssh gnubert.local docker exec ipfs ipfs add -Q -r /export/cmsj.net | tr -d '\r')

echo "Pushing new hash to Route53..."
HOSTEDZONE=ZLC6XW8O2UH0
NAME=ipfs.cmsj.net
REQUEST='{"HostedZoneId":"'$HOSTEDZONE'","ChangeBatch":{"Comment":"Updating '$NAME' to '$HASH'","Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"_dnslink.'$NAME'","Type":"TXT","TTL":30,"ResourceRecords":[{"Value":"\"dnslink=/ipfs/'$HASH'\""}]}}]}}'

source ../_cmsj.net-r53_env.txt
aws route53 change-resource-record-sets --cli-input-json "${REQUEST}"

#echo "Linking files to cmsj.net..."
#ssh gnubert.local docker exec ipfs ipfs name publish --key=cmsj.net "${HASH}"
