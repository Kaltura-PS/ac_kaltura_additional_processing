#!/bin/bash
if [ $# -lt 1 ]; then
    echo "Usage $0 <recording ID>"
    exit 1
fi
TMP=$ID/tmp
if [ -z "$OUTDIR" ]; then
    OUTDIR=/tmp/ac_output
fi
mkdir -p $OUTDIR
cd $OUTDIR
rm -rf $ID
mkdir -p $TMP

COOKIE=`curl -I "$AC_ENDPOINT/api/xml?action=login&login=$AC_USERNAME&password=$AC_PASSWD" | grep "Set-Cookie:" | awk -F " " '{print $2}'`
if [ ! -r $ID.zip ]; then
    curl -q -b "$COOKIE" "$AC_ENDPOINT/$ID/output/$ID.zip?download=zip" > $ID.zip
fi

unzip -o -d $TMP $ID.zip