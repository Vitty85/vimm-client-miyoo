#!/bin/sh

export mydir=$(pwd)
export sysdir=/mnt/SDCARD/.tmp_update
export miyoodir=/mnt/SDCARD/miyoo
export LD_LIBRARY_PATH="$mydir/../lib:/lib:/config/lib:$miyoodir/lib:$sysdir/lib:$sysdir/lib/parasyte"
export PATH="$sysdir/bin:$PATH"
cd $mydir
HOME=$mydir st -q -e $mydir/launchenv.sh 
