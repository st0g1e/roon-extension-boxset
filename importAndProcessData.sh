#!/bin/sh

node importRoonDB.js
./processRoonAPIs.pl
./convertRoonDB.pl
