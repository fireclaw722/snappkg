#!/usr/bin/env bash

## Variables ##

# Set first first arg[] as <command>
comm=$1

# Set Version Number
version="v0.6"

## Functions ##

# Help Header
helphead(){
	echo $version
	echo "Usage: snapt <command>"
	echo ""
	echo "Snapt is a script designed to run snapper and aptitude in conjunction"
	echo "for installing/removing/updating packages using [snapper --command] to"
	echo "auto-create --pre and --post btrfs snapshots."
	echo ""
	echo "Available Commands:"
	echo " help"
	echo " version"
	echo " search"
	echo " snapshot"
	echo " install"
	echo " purge"
	echo " remove"
	echo " upgrade"
	echo " reinstall"
	echo ""
}

# Help Message fn()
helpmsg() {
	echo "Snapt Command info:"
	echo " help:"
	echo "  Shows this help message"
	echo ""
	echo " version:"
	echo "  Shows the version"
	echo ""
	echo " search:"
	echo "  Searches [aptitude search] through repos to find packages"
	echo ""
	echo " snapshot:"
	echo "  snapshot list"
	echo "   Lists [snapper list] snapshots by number"
	echo "  snapshot delete"
	echo "   Allows for deleting [snapper delete] snapshots"
	echo "  snapshot status"
	echo "   Shows changes between snapshots [snapper status]"
	echo ""
	echo " install:"
	echo "  Installs [aptitude install] new packages from repos"
	echo ""
	echo " purge:"
	echo "  Uninstalls [aptitude purge] new packages from repos"
	echo ""
	echo " remove:"
	echo "  Uninstalls [aptitude remove] new packages from repos"
	echo ""
	echo " upgrade:"
	echo "  Upgrade packages to their newest versions [aptitude safe-upgrade]"
	echo ""
	echo " reinstall:"
	echo "  Reinstalls packages [aptitude reinstall]"
	echo ""
}

## Script Start ##

# Force non-error fails to return as error
set -e

# Aptitude is required. If not installed, Abort
command -v aptitude >/dev/null 2>&1 || { echo >&2 "'aptitude' is required, please install it. Aborting."; exit 1; }
# Snapper is required. If not installed, Abort
command -v snapper >/dev/null 2>&1 || { echo >&2 "'snapper' is required, please install it. Aborting."; exit 1; }

# No Arguments
if [ "$#" -eq 0 ]; then
	echo "Error: Requires Arguments"
	echo ""
	helphead
	exit
fi

# Individual Commands
if [ $comm = "help" ]; then
	helphead
	helpmsg

	exit
elif [ $comm = "version" ]; then
	echo snapt $version

	exit
elif [ $comm = "snapshot" ]; then
	# Check for root privileges
	if [ "$EUID" -ne 0 ]; then
		echo "This command needs root privileges."
		echo "Please re-run using root privileges"

		exit 1
	fi

	shift

	if [ $1 = "list" ]; then
		shift
		snapper list $*
	elif [ $1 = "delete" ]; then
		shift
		snapper delete $*
	elif [ $1 = "status" ]; then
		shift
		snapper status $*
	else
		echo "Unsupported snapshot command"
	fi

	exit
elif [ $comm = "search" ]; then
	# Check for root
	if [ "$EUID" -ne 0 ]; then
		shift
		aptitude search $*

		exit
	else
		shift
		aptitude update 	# Run aptitude update if root
		aptitude search $*

		exit
	fi

	exit
elif [ $comm = "install" ]; then
	# Check for root privileges
	if [ "$EUID" -ne 0 ]; then
		echo "This command needs root privileges."
		echo "Please re-run using root privileges"

		exit 1
	fi

	shift

	aptcomm="aptitude install $*"
	aptitude update

	# Must have package names to install anything
	if [ "$#" -eq 0 ]; then
		echo "Requires package name to install"
		exit 1
	fi

	snapper -v create -d "snapt install" --command "$aptcomm"

	exit
elif [ $comm = "purge" ]; then
	# Check for root privileges
	if [ "$EUID" -ne 0 ]; then
		echo "This command needs root privileges."
		echo "Please re-run using root privileges"

		exit 1
	fi

	shift

	aptcomm="aptitude purge $*"
	aptitude update

	# Must have package names to remove anything
	if [ "$#" -eq 0 ]; then
		echo "Requires package name to purge"
		exit 1
	fi

	snapper -v create -d "snapt purge" --command "$aptcomm"

	exit
elif [ $comm = "remove" ]; then
	# Check for root privileges
	if [ "$EUID" -ne 0 ]; then
		echo "This command needs root privileges."
		echo "Please re-run using root privileges"

		exit 1
	fi

	shift

	aptcomm="aptitude remove $*"
	aptitude update

	# Must have package names to remove anything
	if [ "$#" -eq 0 ]; then
		echo "Requires package name to remove"
		exit 1
	fi

	snapper -v create -d "snapt remove" --command "$aptcomm"

	exit
elif [ $comm = "upgrade" ]; then
	# Check for root privileges
	if [ "$EUID" -ne 0 ]; then
		echo "This command needs root privileges."
		echo "Please re-run using root privileges"

		exit 1
	fi
	shift

	aptcomm="aptitude safe-upgrade $*"
	aptitude update

	snapper -v create -d "snapt upgrade" --command "$aptcomm"

	exit
elif [ $comm = "reinstall" ]; then
	# Check for root privileges
	if [ "$EUID" -ne 0 ]; then
		echo "This command needs root privileges."
		echo "Please re-run using root privileges"

		exit 1
	fi
	shift

	if [ "$#" -eq 0 ]; then
		echo "Requires package name to reinstall"
		exit 1
	fi

	aptcomm="aptitude reinstall $*"
	aptitude update

	snapper -v create -d "snapt reinstall" --command "$aptcomm"

	exit
else
	echo "Error: Command <$comm> is not a functional command."
	echo ""
	helphead

	exit 1
fi
