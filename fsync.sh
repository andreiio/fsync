#!/usr/bin/env sh

# Author: Andrei Ioniță
# Repository: https://github.com/andreiio/fsync
# Version: 0.1.0

LOCAL="$PWD"
LATENCY=3

if [ ! -x "$(command -v fswatch)" ]; then
	echo "ERROR: fswatch not found";
	echo "Get it from https://github.com/emcrisostomo/fswatch"
	exit 1
fi

if [ ! -f .env ]; then
	echo "ERROR: Missing .env file."
	exit 1
fi

source .env;

if [ -z $SYNC_HOST ]; then
	echo "ERROR: SYNC_HOST can't be empty."
	exit 1
fi

if [ -z $SYNC_PATH ]; then
	echo "ERROR: SYNC_PATH can't be empty."
	exit 1
fi

cmd="rsync -arvz --delete"

if [ -f .rsyncignore ]; then
	cmd+=" --exclude-from=.rsyncignore"
fi

case $1 in
	-i|--init)
		echo ""
		$cmd $LOCAL/ $SYNC_HOST:$SYNC_PATH
		;;

	-w|--watch)
		fswatch -r0l $LATENCY $LOCAL/ | while read -d "" changed; do
			TMPFILE=`mktemp -t fsync` || exit 1
			echo $changed > $TMPFILE
			echo $changed
			echo "[`date '+%F %H:%M:%S'`] $changed changed. Sync..."
			$cmd --include-from=$TMPFILE $LOCAL/ $SYNC_HOST:$SYNC_PATH
			rm $TMPFILE
		done
		;;

	*)
		echo "Usage:"
		echo "$0 [OPTION]"
		echo ""
		echo "Options:"
		echo "  -i, --init        Perform full sync"
		echo "  -w, --watch       Watch for file changes"
		echo ""
		exit 1
		;;
esac
