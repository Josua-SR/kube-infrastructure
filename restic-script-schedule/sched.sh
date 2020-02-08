#!/bin/sh -e

interval=$1; shift
run=true

on_signal() {
	run=false
}
trap on_signal 1 2 3 9 15

while $run; do
	echo Sleeping for $interval
	sleep $interval

	echo Running restic $*
	$SHELL /entry.sh $*
done

exit 0
