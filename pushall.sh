#!/bin/sh

_init () {

    CONF_SCRIPT_DIR=".pushall.sh";

    if [ ! "$XDG_CONFIG_HOME" ]; then
	XDG_CONFIG_HOME=~/.config;
    fi

    if [ ! "$XDG_DATA_HOME" ]; then
        XDG_DATA_HOME=~/.local/share;
    fi
    
    
    
    if [ $(command -v printf >/dev/null 2>&1 && echo "1") ]; then
	PRINT="printf %s\n";
	PRINT_E="printf %b\n";
	PRINT_N="printf %s";
	PRINT_EN="printf %b";
    elif [ $(command -v echo >/dev/null 2>&1 && echo "1") ]; then
	PRINT="echo";
	PRINT_E="echo -e";
	PRINT_N="echo -n";
	PRINT_EN="echo -en";
    else
	exit 1;
    fi
    
}

_print () {

	if [ ! "$PRINT" ] || [ ! "$PRINT_E" ] || [ ! "$PRINT_N" ] || [ ! "$PRINT_EN" ]; then
		exit 1;
	fi

	if [ ! "$2" ]; then
		PRINT_ARG=$1;
	else
		PRINT_MOD=$1;
		PRINT_ARG=$2;
	fi

	case $PRINT_MOD in
		-e)
			$PRINT_E "$PRINT_ARG"
		;;
		-n)
			$PRINT_N "$PRINT_ARG"
		;;
		-en|-ne)
			$PRINT_EN "$PRINT_ARG"
		;;
		*)
			$PRINT "$PRINT_ARG"
		;;
	esac

}

_usage () {

    _print "Usage: $0 [-h]"
    _print
    _print "API calls to pushall.ru"
    _print "v 0.0.1"
    _print
    _print "Options:"
    _print -e "\t-h\tThis usage help"
    _print

}

_parseOptions () {

    if [ "$1" = "" ]; then
	_usage
	exit 0;
    fi

    while getopts "h" opt
    do
	case $opt in
	    h)
		_usage
		exit 0;
		;;
	esac
    done
    
}

_init
_parseOptions "$@"
shift $((OPTIND-1));
