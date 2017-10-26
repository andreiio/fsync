#!/usr/bin/env sh

# Author: Andrei Ioniță
# Repository: https://github.com/andreiio/fsync
# Version: 0.2.0

BUFFER=`mktemp -t fsync` || exit 1
LOCAL="$PWD"
DATE_FORMAT="%F %H:%M:%S"

function finish() {
	echo "\nPerforming cleanup..."
	rm -f $BUFFER
}

trap finish EXIT

colors=$(tput colors)
if [ $colors -gt "8" ]; then
	inf='\033[0;32m'
	clr='\033[00m'
else
	inf=
	clr=
fi

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

if [ -z $SYNC_POLL ]; then
	SYNC_POLL=3
fi

cmd="rsync --delete -ha"

if [ -f .rsyncignore ]; then
	cmd+=" --exclude-from=.rsyncignore"
fi

echo "${inf}[`date +\"${DATE_FORMAT}\"`] Performing initial sync... ${clr}"
$cmd $LOCAL/ $SYNC_HOST:$SYNC_PATH
echo "Watching $PWD for changes every $SYNC_POLL seconds..."

fswatch -r $LOCAL/ > $BUFFER &

while true; do
	count=$(cat $BUFFER | wc -l)

	if [ $count -gt 0 ]; then
		subj="file"

		if [ $count -gt 1 ]; then
			subj="${subj}s"
		fi

		echo "${inf}[`date +\"${DATE_FORMAT}\"`] $count $subj changed... ${clr}"
		$cmd -v --include-from=$BUFFER $LOCAL/ $SYNC_HOST:$SYNC_PATH
		>$BUFFER
	fi
	sleep $SYNC_POLL
done;
