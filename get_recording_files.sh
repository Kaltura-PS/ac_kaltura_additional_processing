#!/bin/bash
if [ $# -lt 1 ]; then
    echo "Usage $0 <recording ID>"
    exit 1
fi
ID="$1"
if [ -z "$OUTDIR" ]; then
    OUTDIR=/tmp/ac_output
fi
mkdir -p $OUTDIR
cd $OUTDIR
rm -rf $ID
mkdir -p $ID
COOKIE=`curl -I "$AC_ENDPOINT/api/xml?action=login&login=$AC_USERNAME&password=$AC_PASSWD" | grep "Set-Cookie:" | awk -F " " '{print $2}'`
if [ ! -r $ID.zip ]; then
        echo $ID
    curl -q -b "$COOKIE" "$AC_ENDPOINT/$ID/output/$ID.zip?download=zip" > $ID.zip
fi

unzip -o -d $ID $ID.zip
