#!/bin/sh

set -e

mkdir -p mockbin

export PATH="$PWD/mockbin:$PATH"

cat > mockbin/curl <<CURL_MOCK
#!/bin/sh
if [ "\$*" = "-sS --data-urlencode id=pushall_id --data-urlencode key=pushall_key --data-urlencode title=Title --data-urlencode text=Text -X POST https://pushall.ru/api.php?type=self" ]; then
	printf "%b\n" "{\\"success\\":1,\\"lid\\":6546002}"
	exit 0
fi

if [ "\$*" = "-sS --data-urlencode id=pushall_id --data-urlencode key=pushall_key --data-urlencode title=Title --data-urlencode text=Text --data-urlencode icon=http://test.com/icon.png --data-urlencode url=http://google.com --data-urlencode hidden=2 --data-urlencode encode=utf8 --data-urlencode priority=1 --data-urlencode ttl=300 -X POST https://pushall.ru/api.php?type=self" ]; then
	printf "%b\n" "{\\"success\\":1,\\"lid\\":6546003}"
	exit 0
fi

if [ "\$*" = "-sS --data-urlencode id=pushall_id --data-urlencode key=pushall_key --data-urlencode title=Title --data-urlencode text=Unreachable test -X POST https://pushall.ru/api.php?type=self" ]; then
	printf "%s\n" "curl: (6) Couldn't resolve host 'pushall.ru'"
	exit 6
fi

if [ "\$*" = "-sS --data-urlencode id=pushall_id --data-urlencode key=pushall_key --data-urlencode title=Title --data-urlencode text=API error test -X POST https://pushall.ru/api.php?type=self" ]; then
	printf "%b\n" "{\\"error\\":\\"wrong key\\"}"
	exit 0
fi

printf "%s\n" "Curl invocation, params: \$*" >&2
printf "%s\n" "\$*" >> curl.log
exit 1
CURL_MOCK

chmod +x mockbin/curl

. ci/assert.sh

CONF_SCRIPT_DIR=".pushall.sh";
if [ ! "$XDG_CONFIG_HOME" ]; then
	export XDG_CONFIG_HOME=./ci/.config;
fi

if [ ! "$XDG_DATA_HOME" ]; then
	export XDG_DATA_HOME=./ci/.local/share;
fi

QUEUE_FILE=$XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt

# Usage test
assert "./pushall.sh" "$(cat usage.txt)"
assert "./pushall.sh -h" "$(cat usage.txt)"

assert_end "USAGE MESSAGE"

# self minimal call
assert "./pushall.sh -c self -t \"Title\" -T \"Text\" -I \"pushall_id\" -K \"pushall_key\" 2>&1" "6546002"
# self call with all usable params
assert "./pushall.sh -c self -t \"Title\" -T \"Text\" -i \"http://test.com/icon.png\" -I \"pushall_id\" -K \"pushall_key\" -u \"http://google.com\" -H 2 -e \"utf8\" -p 1 -l 300 2>&1" "6546003"

assert_end "INSTANT CALLS"

# Travis CI issue: https://github.com/travis-ci/travis-cookbooks/issues/876

mkdir -p ./ci/var/lock/
export LOCKDIR_PREFIX="./ci"

# Queue add
assert_raises "./pushall.sh -c self -t \"Title\" -T \"Text\" -I \"pushall_id\" -K \"pushall_key\" queue 2>&1" 0
assert_raises "[ -s $QUEUE_FILE ]" 0
QUEUE_ID=$(cat "$QUEUE_FILE" | awk -F '/::/' '{print $1;}')
assert_raises "[ \"$QUEUE_ID\" ]" 0

assert_end "QUEUE ADD"

# Queue delete
assert_raises "./pushall.sh delete \"$QUEUE_ID\" 2>&1" 0
assert_raises "[ -s $QUEUE_FILE ]" 1

assert_end "QUEUE DELETE"

# Queue add to the top
./pushall.sh -c self -t "Title" -T "Text" -I "pushall_id" -K "pushall_key" queue >/dev/null
assert_raises "./pushall.sh -c self -t \"Title\" -T \"Text\" -I \"pushall_id\" -K \"pushall_key\" queue top 2>&1" 0
NEW_ID=$(./pushall.sh -c self -t "Title" -T "Text" -I "pushall_id" -K "pushall_key" queue top)
assert_raises "[ -s $QUEUE_FILE ]" 0
QUEUE_ID=$(cat "$QUEUE_FILE" | awk -F '/::/' '{print $1;exit 0;}')
assert_raises "[ \"$QUEUE_ID\" = \"$NEW_ID\" ]" 0

assert_end "QUEUE ADD TO THE TOP"

# Queue clear
./pushall.sh -c self -t "Title" -T "Text" -I "pushall_id" -K "pushall_key" queue >/dev/null
./pushall.sh -c self -t "Title" -T "Text" -I "pushall_id" -K "pushall_key" queue >/dev/null
./pushall.sh -c self -t "Title" -T "Text" -I "pushall_id" -K "pushall_key" queue >/dev/null
assert_raises "[ -s $QUEUE_FILE ]" 0
assert_raises "./pushall.sh clear" 0
assert_raises "[ -s $QUEUE_FILE ]" 1

assert_end "QUEUE CLEAR"

# Queue run
./pushall.sh -c self -t "Title" -T "Text" -I "pushall_id" -K "pushall_key" queue >/dev/null
./pushall.sh -c self -t "Title" -T "Text" -I "pushall_id" -K "pushall_key" queue >/dev/null
./pushall.sh -c self -t "Title" -T "Text" -I "pushall_id" -K "pushall_key" queue >/dev/null
assert_raises "[ -s $QUEUE_FILE ]" 0
assert_raises "./pushall.sh run" 0
assert_raises "[ -s $QUEUE_FILE ]" 1

assert_end "QUEUE RUN"

# No api call (-c) set
assert_raises "./pushall.sh -t \"Title\" -T \"Text\" -I \"pushall_id\" -K \"pushall_key\" 2>&1" 1
# No account ID set (-I)
assert_raises "./pushall.sh -c self -t \"Title\" -T \"Text\" -K \"pushall_key\" 2>&1" 1
# No account key set (-K)
assert_raises "./pushall.sh -c self -t \"Title\" -T \"Text\" -I \"pushall_id\" 2>&1" 1
# No message title set (-t)
assert_raises "./pushall.sh -c self -T \"Text\" -I \"pushall_id\" -K \"pushall_key\" 2>&1" 1
# No message body set (-T)
assert_raises "./pushall.sh -c self -t \"Title\" -I \"pushall_id\" -K \"pushall_key\" 2>&1" 1
# Wrong API call set (-c wrongapicall)
assert_raises "./pushall.sh -c wrongapicall -t \"Title\" -T \"Text\" -I \"pushall_id\" -K \"pushall_key\" 2>&1" 1
# Wrong command supplied
assert_raises "./pushall.sh -c self -t \"Title\" -T \"Text\" -I \"pushall_id\" -K \"pushall_key\" wrongcmd 2>&1" 1
# Curl error (server is unreachable)
assert_raises "./pushall.sh -c self -t \"Title\" -T \"Unreachable test\" -I \"pushall_id\" -K \"pushall_key\" 2>&1" 1
# API error (malformed data etc.)
assert_raises "./pushall.sh -c self -t \"Title\" -T \"API error test\" -I \"pushall_id\" -K \"pushall_key\" 2>&1" 1
assert "./pushall.sh -c self -t \"Title\" -T \"API error test\" -I \"pushall_id\" -K \"pushall_key\" 2>&1" "API returned error: \"wrong key\""
# Multiple instance queue run
./pushall.sh -c self -t "Title" -T "Text" -I "pushall_id" -K "pushall_key" queue >/dev/null
./pushall.sh -c self -t "Title" -T "Text" -I "pushall_id" -K "pushall_key" queue >/dev/null
./pushall.sh -c self -t "Title" -T "Text" -I "pushall_id" -K "pushall_key" queue >/dev/null
./pushall.sh run 2>&1 &
BG_PUSHALL_PID=$!
echo "bg job pid: $!"
#assert_raises "./pushall.sh run 2>&1" 1
#assert "./pushall.sh run 2>&1" "Queue is already running. Exiting."
while kill -0 $BG_PUSHALL_PID >/dev/null 2>&1; do
	true
done

assert_end "ERROR HANDLING"

#assert "./curlget.sh 2>&1" "Curl invocation, params: -h"
#assert "echo"                           # no output expected
#assert "echo foo" "foo"                 # output expected
#assert "cat" "bar" "bar"                # output expected if input's given
#assert_raises "true" 0 ""               # status code expected
#assert_raises "exit 127" 127 ""         # status code expected
#assert "head -1 < $0" "#!/bin/sh"     # redirections
#assert "seq 2" "1\n2"                   # multi-line output expected
#assert_raises 'read a; exit $a' 42 "42" # variables still work
#assert "echo 1;
#echo 2      # ^" "1\n2"                 # semicolon required!

rm -rf mockbin
rm -rf ci/.local
rm -rf ci/var
