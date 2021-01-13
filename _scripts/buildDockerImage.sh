#!/usr/bin/env bash

set -eu -o pipefail
shopt -s inherit_errexit

# buildDockerImage is a helper for the cueckoo/copybara Dockage image.
#
# Run with no args, the script first checks whether an image corresponding
# to the commit at which the copybara submodule is pinned exists locally.
# If not, it attempts to pull it from Docker hub. Failing that, the image
# is built.
#
# The -p flag attempts to push the local image to Docker hub.
#
# This script assumes the copybara submodule is initialised

push=""

while getopts 'p' opt; do
	case $opt in
		p) push=true ;;
		*) echo 'Error in command line parsing' >&2
			exit 1
	esac
done

# Change to the copybara directory
cd "$( command cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/../copybara"

if [ ! -f .git ]
then
	echo "could not find copybara .git directory - need to run 'git submodule update --init' perhaps?"
	exit 1
fi

target="cueckoo/copybara:$(git rev-parse HEAD)"

imageExists=""
if docker inspect $target > /dev/null 2>&1
then
	imageExists=true
fi

if ! [[ $imageExists ]]
then
	if docker pull $target > /dev/null 2>&1
	then
		echo "successfully pulled $target"
		# No need to push because we pulled
		exit 0
	fi
	docker build --rm -t $target .
fi

if [[ $push ]]
then
	docker push $target
fi
