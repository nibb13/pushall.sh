#!/bin/sh

_check_cmd () {

	command -v $1 >/dev/null 2>&1 && echo "1";
    
}

_init () {

	SCRIPT_VERSION="v 0.1.1-alpha"

	CONF_SCRIPT_DIR=".pushall.sh";
	SCRIPT_DIR=$(dirname "$0")
	SCRIPT_NAME=$(basename "$0")
	LOCKDIR="$LOCKDIR_PREFIX/var/lock/${SCRIPT_NAME}_${USER}"
	PIDFILE="${LOCKDIR}/pid"

	if [ ! "$XDG_CONFIG_HOME" ]; then
		XDG_CONFIG_HOME=~/.config;
	fi

	if [ ! "$XDG_DATA_HOME" ]; then
		XDG_DATA_HOME=~/.local/share;
	fi
	
	if [ ! -d "$XDG_DATA_HOME/$CONF_SCRIPT_DIR" ]; then
		mkdir -p "$XDG_DATA_HOME/$CONF_SCRIPT_DIR";
	fi
    
	if [ $(_check_cmd printf) ]; then
		PRINT="printf %s\n";
		PRINT_E="printf %b\n";
		PRINT_N="printf %s";
		PRINT_EN="printf %b";
	elif [ $(_check_cmd echo) ]; then
		PRINT="echo";
		PRINT_E="echo -e";
		PRINT_N="echo -n";
		PRINT_EN="echo -en";
	else
		exit 1;
	fi

	# TODO: Implement more robust checking for https/SSL in install
	if [ ! $(_check_cmd curl) ]; then
		_print_err "No curl is found!"
		exit 1;
	fi
    
}

_print () {

	if [ ! "$PRINT" ] || [ ! "$PRINT_E" ] || [ ! "$PRINT_N" ] || [ ! "$PRINT_EN" ]; then
		exit 1;
	fi

	if [ ! "$2" ]; then
		PRINT_ARG="$1";
	else
		PRINT_MOD="$1";
		PRINT_ARG="$2";
	fi

	case "$PRINT_MOD" in
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

_print_err () {
	_print "$@" >&2
}

_usage () {

	_print "Usage: $0 -cIKtT [-beHilpuh] [COMMAND]"
	_print
	_print "API calls to pushall.ru"
	_print "$SCRIPT_VERSION"
	_print
	_print "COMMAND can be:"
	_print
	_print -e "\t\tsend or empty - send specified API call"
	_print -e "\t\tqueue [top] - store specified API call in sending queue (optionally to the top)"
	_print -e "\t\trun - run sending queue respecting all timeouts"
	_print -e "\t\tdelete <ID> - delete single record from queue (ID returned by queue call)"
	_print -e "\t\tclear - clear current queue"
	_print
	_print "General options:"
	_print
	_print -e "\t-b\tCA bundle path for curl"
	_print -e "\t-c\tAPI call"
	_print -e "\t\t( Can be \"self\" or \"broadcast\" )"
	_print -e "\t-h\tThis usage help"
	_print
	_print "Options for self & broadcast API:"
	_print
	_print -e "\t-t\tPush message title (required)"
	_print -e "\t-T\tPush message text (required)"
	_print -e "\t-i\tPush message icon"
	_print -e "\t-I\tYour pushall account / channel ID (required)"
	_print -e "\t-K\tYour pushall account / channel key (required)"
	_print -e "\t-u\tPush message URL"
	_print -e "\t-H\tHide option for push message"
	_print -e "\t-e\tPush message encoding"
	_print -e "\t-p\tPush message priority"
	_print -e "\t-l\tPush message TTL"
	_print

}

_parse_options () {

	if [ "$1" = "" ]; then
		_usage
		exit 0;
	fi

	while getopts "hH:c:t:T:i:u:e:p:l:b:I:K:" opt
	do
		case "$opt" in
			h)
				_usage
				exit 0;
			;;
			c)
				PUSHALL_API=$OPTARG;
			;;
			t)
				TITLE="$OPTARG";
			;;
			T)
				TEXT="$OPTARG";
			;;
			i)
				ICON="$OPTARG";
			;;
			u)
				URL="$OPTARG";
			;;
			H)
				HIDDEN="$OPTARG";
			;;
			e)
				ENCODE="$OPTARG";
			;;
			p)
				PRIORITY="$OPTARG";
			;;
			l)
				TTL="$OPTARG";
			;;
			b)
				CA_BUNDLE="$OPTARG";
			;;
			I)
				PUSHALL_ID="$OPTARG";
			;;
			K)
				PUSHALL_KEY="$OPTARG";
			;;
		esac
	done
    
}

_self_api_call () {

	[ "$TITLE" ] && TITLE=$(_print -en "$TITLE")
	[ "$TEXT" ] && TEXT=$(_print -en "$TEXT")
	[ "$ICON" ] && ICON=$(_print -en "$ICON")
	[ "$URL" ] && URL=$(_print -en "$URL")
	[ "$ENCODE" ] && ENCODE=$(_print -en "$ENCODE")

	PARAMLINE="--data-urlencode \"id=$PUSHALL_ID\" --data-urlencode \"key=$PUSHALL_KEY\" --data-urlencode \"title=$TITLE\" --data-urlencode \"text=$TEXT\""
	
	if [ "$ICON" ]; then
		PARAMLINE="$PARAMLINE --data-urlencode \"icon=$ICON\""
	fi
	if [ "$URL" ]; then
		PARAMLINE="$PARAMLINE --data-urlencode \"url=$URL\""
	fi
	if [ "$HIDDEN" ]; then
		PARAMLINE="$PARAMLINE --data-urlencode \"hidden=$HIDDEN\""
	fi
	if [ "$ENCODE" ]; then
		PARAMLINE="$PARAMLINE --data-urlencode \"encode=$ENCODE\""
	fi
	if [ "$PRIORITY" ]; then
		PARAMLINE="$PARAMLINE --data-urlencode \"priority=$PRIORITY\""
	fi
	if [ "$TTL" ]; then
		PARAMLINE="$PARAMLINE --data-urlencode \"ttl=$TTL\""
	fi
	
	CURLARGS="-sS $PARAMLINE -X POST \"https://pushall.ru/api.php?type=self\""
	
	if [ "$CA_BUNDLE" ]; then
		CURLARGS="$CURLARGS --cacert \"$CA_BUNDLE\""
	fi
	
	# Calling curl & capturing stdout, stderr and exit code using
	# tagging approach by Warbo, ref: http://stackoverflow.com/a/37602314
	CURLOUT=$({ { eval "curl $CURLARGS"; _print -e "EXITSTATUS:$?" >&2; } | sed -e 's/^/STDOUT:/g'; } 2>&1)
	#_print "$CURLOUT"
	CURLEXITSTATUS=$(_print "$CURLOUT" | grep "^EXITSTATUS:" | sed -e 's/^EXITSTATUS://g')
#	CURLOUT="STDOUT:{\"success\":1,\"lid\":6546002}"
#	CURLEXITSTATUS=0
	CURLSTDOUT=$(_print "$CURLOUT" | grep "^STDOUT:" | grep -v "^EXITSTATUS:" | sed -e 's/^STDOUT://g')
	CURLSTDERR=$(_print "$CURLOUT" | grep -v "^STDOUT:\|^EXITSTATUS:")
	
	if [ $CURLEXITSTATUS -ne 0 ]; then
		_print_err -e "Error in curl: $CURLSTDERR"
		return 1;
	else
		CURLPARSED=$(_print "$CURLSTDOUT" | $SCRIPT_DIR/JSON.awk)
		PUSHALL_ERROR=$(_print "$CURLPARSED" | grep "\[\"error\"\]" | sed 's/.*\t\(.*\)/\1/')
		if [ "$PUSHALL_ERROR" ]; then
			_print_err "API returned error: $PUSHALL_ERROR"
			return 1;
		fi
		LID=$(_print "$CURLPARSED" | grep "\[\"lid\"\]" | sed 's/.*\t\(.*\)/\1/')
		_print "$LID"
		return 0;
	fi
	
}

_broadcast_api_call () {

	[ "$TITLE" ] && TITLE=$(_print -en "$TITLE")
	[ "$TEXT" ] && TEXT=$(_print -en "$TEXT")
	[ "$ICON" ] && ICON=$(_print -en "$ICON")
	[ "$URL" ] && URL=$(_print -en "$URL")
	[ "$ENCODE" ] && ENCODE=$(_print -en "$ENCODE")

	PARAMLINE="--data-urlencode \"id=$PUSHALL_ID\" --data-urlencode \"key=$PUSHALL_KEY\" --data-urlencode \"title=$TITLE\" --data-urlencode \"text=$TEXT\""
	
	if [ "$ICON" ]; then
		PARAMLINE="$PARAMLINE --data-urlencode \"icon=$ICON\""
	fi
	if [ "$URL" ]; then
		PARAMLINE="$PARAMLINE --data-urlencode \"url=$URL\""
	fi
	if [ "$HIDDEN" ]; then
		PARAMLINE="$PARAMLINE --data-urlencode \"hidden=$HIDDEN\""
	fi
	if [ "$ENCODE" ]; then
		PARAMLINE="$PARAMLINE --data-urlencode \"encode=$ENCODE\""
	fi
	if [ "$PRIORITY" ]; then
		PARAMLINE="$PARAMLINE --data-urlencode \"priority=$PRIORITY\""
	fi
	if [ "$TTL" ]; then
		PARAMLINE="$PARAMLINE --data-urlencode \"ttl=$TTL\""
	fi
	
	CURLARGS="-sS $PARAMLINE -X POST \"https://pushall.ru/api.php?type=broadcast\""
	
	if [ "$CA_BUNDLE" ]; then
		CURLARGS="$CURLARGS --cacert \"$CA_BUNDLE\""
	fi
	
	# Calling curl & capturing stdout, stderr and exit code using
	# tagging approach by Warbo, ref: http://stackoverflow.com/a/37602314
	CURLOUT=$({ { eval "curl $CURLARGS"; _print -e "EXITSTATUS:$?" >&2; } | sed -e 's/^/STDOUT:/g'; } 2>&1)
	#_print "$CURLOUT"
	CURLEXITSTATUS=$(_print "$CURLOUT" | grep "^EXITSTATUS:" | sed -e 's/^EXITSTATUS://g')
	CURLSTDOUT=$(_print "$CURLOUT" | grep "^STDOUT:" | grep -v "^EXITSTATUS:" | sed -e 's/^STDOUT://g')
	CURLSTDERR=$(_print "$CURLOUT" | grep -v "^STDOUT:\|^EXITSTATUS:")
	
	if [ $CURLEXITSTATUS -ne 0 ]; then
		_print_err -e "Error in curl: $CURLSTDERR"
		return 1;
	else
		CURLPARSED=$(_print "$CURLSTDOUT" | $SCRIPT_DIR/JSON.awk)
		PUSHALL_ERROR=$(_print "$CURLPARSED" | grep "\[\"error\"\]" | sed 's/.*\t\(.*\)/\1/')
		if [ "$PUSHALL_ERROR" ]; then
			_print_err "API returned error: $PUSHALL_ERROR"
			return 1;
		fi
		LID=$(_print "$CURLPARSED" | grep "\[\"lid\"\]" | sed 's/.*\t\(.*\)/\1/')
		_print "$LID"
		return 0;
	fi
	
}

_self_api_queue () {

	case "$EXTRA" in

		[Tt][Oo][Pp])
			EXTRA="top"
		;;

	esac

	_lock_set "queue"

	UUID=$(cat /proc/sys/kernel/random/uuid)

	if [ "$EXTRA" = "top" ]; then
		# TODO: Make checks against running out of space
		mv $XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt $XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.old
		_print "$UUID/::/self/::/$PUSHALL_ID/::/$PUSHALL_KEY/::/$TITLE/::/$TEXT/::/$ICON/::/$URL/::/$HIDDEN/::/$ENCODE/::/$PRIORITY/::/$TTL/::/$CA_BUNDLE" > "$XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt"
		cat $XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.old >> $XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt
		rm $XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.old
	else
		_print "$UUID/::/self/::/$PUSHALL_ID/::/$PUSHALL_KEY/::/$TITLE/::/$TEXT/::/$ICON/::/$URL/::/$HIDDEN/::/$ENCODE/::/$PRIORITY/::/$TTL/::/$CA_BUNDLE" >> "$XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt"
	fi

	_lock_remove "queue"

	_print "$UUID"

	return 0;
	
}

_broadcast_api_queue () {

	case "$EXTRA" in

		[Tt][Oo][Pp])
			EXTRA="top"
		;;

	esac

	_lock_set "queue"

	UUID=$(cat /proc/sys/kernel/random/uuid)

	if [ "$EXTRA" = "top" ]; then
		# TODO: Make checks against running out of space
		mv $XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt $XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.old
		_print "$UUID/::/broadcast/::/$PUSHALL_ID/::/$PUSHALL_KEY/::/$TITLE/::/$TEXT/::/$ICON/::/$URL/::/$HIDDEN/::/$ENCODE/::/$PRIORITY/::/$TTL/::/$CA_BUNDLE" > "$XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt"
		cat $XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.old >> $XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt
		rm $XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.old
	else
		_print "$UUID/::/broadcast/::/$PUSHALL_ID/::/$PUSHALL_KEY/::/$TITLE/::/$TEXT/::/$ICON/::/$URL/::/$HIDDEN/::/$ENCODE/::/$PRIORITY/::/$TTL/::/$CA_BUNDLE" >> "$XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt"
	fi

	_lock_remove "queue"

	_print "$UUID"

	return 0;
	
}

_queue_run() {

	[ ! -f "$XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt" ] && return 0;

	# run once approach by bk138, ref: http://stackoverflow.com/a/25243837
	if ! mkdir $LOCKDIR 2>/dev/null
	then
	# lock failed, but check for stale one by checking if the PID is really existing
		PID=$(cat $PIDFILE)
		if kill -0 $PID 2>/dev/null
		then
			_print_err "Queue is already running. Exiting."
			exit 1
		fi
	fi

	# lock successfully acquired, save PID
	echo $$ > $PIDFILE

	trap "rm -rf ${LOCKDIR}" QUIT INT TERM EXIT

	while read -r _line
	do

		if [ ! "$READING_LINE"]; then

			_lock_set "queue"

		fi

		[ "$FULL_LINE" ] && FULL_LINE="$FULL_LINE\n"
		FULL_LINE="$FULL_LINE$_line"

		if [ $(echo "$FULL_LINE" | awk -F"/::/" '{print NF; exit}') -lt 13 ]; then
			sed -i 1d "$XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt"
			READING_LINE=1
			continue
		fi

		READING_LINE=
		
		# TODO: Find a better way for this:
		_api=$(echo "$FULL_LINE" | awk -F"/::/" '{print $2}')
		PUSHALL_ID=$(echo "$FULL_LINE" | awk -F"/::/" '{print $3}')
		PUSHALL_KEY=$(echo "$FULL_LINE" | awk -F"/::/" '{print $4}')
		TITLE=$(echo "$FULL_LINE" | awk -F"/::/" '{print $5}')
		TEXT=$(echo "$FULL_LINE" | awk -F"/::/" '{print $6}')
		ICON=$(echo "$FULL_LINE" | awk -F"/::/" '{print $7}')
		URL=$(echo "$FULL_LINE" | awk -F"/::/" '{print $8}')
		HIDDEN=$(echo "$FULL_LINE" | awk -F"/::/" '{print $9}')
		ENCODE=$(echo "$FULL_LINE" | awk -F"/::/" '{print $10}')
		PRIORITY=$(echo "$FULL_LINE" | awk -F"/::/" '{print $11}')
		TTL=$(echo "$FULL_LINE" | awk -F"/::/" '{print $12}')
		CA_BUNDLE=$(echo "$FULL_LINE" | awk -F"/::/" '{print $13}')
		case "$_api" in
			[Ss][Ee][Ll][Ff])
				while true; do
					if [ ! "$SELF_LAST" ] || [ $(($(date +%s) - $SELF_LAST)) -gt 3 ]; then
						break
					fi
					sleep 1;
				done
				_self_api_check && _self_api_call && SELF_LAST=$(date +%s)
			;;
			[Bb][Rr][Oo][Aa][Dd][Cc][Aa][Ss][Tt])
				while true; do
					if [ ! "$BROADCAST_LAST" ] || [ $(($(date +%s) - $BROADCAST_LAST)) -gt 30 ]; then
						break
					fi
					sleep 1;
				done
				_broadcast_api_check && _broadcast_api_call && BROADCAST_LAST=$(date +%s)
			;;
			*)
				_print_err "Unknown API: \"$PUSHALL_API\""
			;;
		esac
		sed -i 1d "$XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt"

		_lock_remove "queue"

		FULL_LINE=""

	done < "$XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt"

	_lock_remove "queue" # In case of faulty data in queue

	return 0;

}

_queue_delete_check() {

	if [ ! "$EXTRA" ]; then
		_print_err "ID is required to delete single record from queue"
		return 1;
	fi
	
	return 0;
	
}

_queue_delete() {

	[ ! -f "$XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt" ] && return 0;

	_lock_set "queue"

	while read -r _line
	do

		[ "$FULL_LINE" ] && FULL_LINE="$FULL_LINE\n"
		FULL_LINE="$FULL_LINE$_line"

		if [ $(echo "$FULL_LINE" | awk -F"/::/" '{print NF; exit}') -lt 13 ]; then
			sed -i 1d "$XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt"
			_lock_remove "queue"
			continue
		fi

		sed -i 1d "$XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt"

		echo "$FULL_LINE" | grep "^$EXTRA/::/" >/dev/null || NEW_QUEUE="$NEW_QUEUE$FULL_LINE\n"

		FULL_LINE=""

	done < "$XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt"

	[ "$NEW_QUEUE" ] && _print -en "$NEW_QUEUE" > "$XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt"

	_lock_remove "queue"

	return 0;

}

_queue_clear() {

	[ ! -f "$XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt" ] && return 0;

	_lock_set "queue"

	rm "$XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt"

	_lock_remove "queue"

}

_self_api_check() {

	if [ ! "$TITLE" ]; then
		_print_err "Title (-t) is required for self API call"
		return 1;
	fi
	
	if [ ! "$TEXT" ]; then
		_print_err "Text (-T) is required for self API call"
		return 1;
	fi
	
	if [ ! "$PUSHALL_ID" ]; then
		_print_err "Pushall ID (-I) is required for self API call"
		return 1;
	fi
	
	if [ ! "$PUSHALL_KEY" ]; then
		_print_err "Pushall key (-K) is required for self API call"
		return 1;
	fi
	
	return 0;
	
}

_broadcast_api_check() {

	if [ ! "$TITLE" ]; then
		_print_err "Title (-t) is required for broadcast API call"
		return 1;
	fi
	
	if [ ! "$TEXT" ]; then
		_print_err "Text (-T) is required for broadcast API call"
		return 1;
	fi
	
	if [ ! "$PUSHALL_ID" ]; then
		_print_err "Pushall ID (-I) is required for broadcast API call"
		return 1;
	fi
	
	if [ ! "$PUSHALL_KEY" ]; then
		_print_err "Pushall key (-K) is required for broadcast API call"
		return 1;
	fi
	
	return 0;
	
}

_lock_set () {

	LOCK_NAME="$1";

	while ! mkdir -p $LOCKDIR_$LOCK_NAME 2>/dev/null; do
		LOCK_PID=$(cat $LOCKDIR_$LOCK_NAME/pid)
		[ -f $LOCKDIR_$LOCK_NAME/pid ] && ! kill -0 $LOCK_PID 2>/dev/null && rm -rf "$LOCKDIR_$LOCK_NAME"
	done

	echo $$ > $LOCKDIR_$LOCK_NAME/pid
	
	trap "rm -rf $LOCKDIR_$LOCK_NAME" QUIT INT TERM EXIT

}

_lock_remove () {

	LOCK_NAME="$1";

	rm -rf $LOCKDIR_$LOCK_NAME;

}

_init
_parse_options "$@"
shift $((OPTIND-1));
COMMAND=$1;
EXTRA=$2;

case "$COMMAND" in

	[Ss][Ee][Nn][Dd]|"")
		case "$PUSHALL_API" in
			[Ss][Ee][Ll][Ff])
				_self_api_check && _self_api_call
			;;
			[Bb][Rr][Oo][Aa][Dd][Cc][Aa][Ss][Tt])
				_broadcast_api_check && _broadcast_api_call
			;;
			*)
				_print_err "Unknown API: \"$PUSHALL_API\""
				exit 1;
			;;
		esac
	;;
	[Qq][Uu][Ee][Uu][Ee])
		case "$PUSHALL_API" in
			[Ss][Ee][Ll][Ff])
				_self_api_check && _self_api_queue
			;;
				[Bb][Rr][Oo][Aa][Dd][Cc][Aa][Ss][Tt])
				_broadcast_api_check && _broadcast_api_queue
			;;
			*)
				_print_err "Unknown API: \"$PUSHALL_API\""
				exit 1;
			;;
		esac
	;;
	[Rr][Uu][Nn])
		_queue_run
	;;
	[Dd][Ee][Ll][Ee][Tt][Ee])
		_queue_delete_check && _queue_delete
	;;
	[Cc][Ll][Ee][Aa][Rr])
		_queue_clear
	;;
	*)
		_print_err "Unknown command: \"$COMMAND\""
		exit 1;
	;;

esac
