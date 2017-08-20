#!/bin/sh
set -x
dmd -m64 pepss.d
rm *.o
