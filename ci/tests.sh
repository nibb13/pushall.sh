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

printf "%s\n" "Curl invocation, params: \$*" >&2
printf "%s\n" "\$*" >> curl.log
CURL_MOCK

chmod +x mockbin/curl

. ci/assert.sh

CONF_SCRIPT_DIR=".pushall.sh";
if [ ! "$XDG_CONFIG_HOME" ]; then
	XDG_CONFIG_HOME=~/.config;
fi

if [ ! "$XDG_DATA_HOME" ]; then
	XDG_DATA_HOME=~/.local/share;
fi

QUEUE_FILE=$XDG_DATA_HOME/$CONF_SCRIPT_DIR/queue.txt

# Usage test
assert "./pushall.sh" "$(cat usage.txt)"
assert "./pushall.sh -h" "$(cat usage.txt)"

assert_end "Usage test"

# self minimal call
assert "./pushall.sh -c self -t \"Title\" -T \"Text\" -I \"pushall_id\" -K \"pushall_key\" 2>&1" "6546002"
# self call with all usable params
assert "./pushall.sh -c self -t \"Title\" -T \"Text\" -i \"http://test.com/icon.png\" -I \"pushall_id\" -K \"pushall_key\" -u \"http://google.com\" -H 2 -e \"utf8\" -p 1 -l 300 2>&1" "6546003"

assert_end "Instant calls"

# Queue add
assert_raises "./pushall.sh -c self -t \"Title\" -T \"Text\" -I \"pushall_id\" -K \"pushall_key\" queue 2>&1" 0
assert_raises "[ -s $QUEUE_FILE ]" 0
echo "Queue file is at: $QUEUE_FILE"
QUEUE_ID=$(cat "$QUEUE_FILE" | awk -F '/::/' '{print $1;}')
assert_raises "[ \"$QUEUE_ID\" ]" 0

assert_end "Queue add"

# Queue delete
assert_raises "./pushall.sh delete \"$QUEUE_ID\" 2>&1" 0
assert_raises "[ -s $QUEUE_FILE ]" 1

assert_end "Queue delete"

# Queue clear
./pushall.sh -c self -t "Title" -T "Text" -I "pushall_id" -K "pushall_key" queue >/dev/null
./pushall.sh -c self -t "Title" -T "Text" -I "pushall_id" -K "pushall_key" queue >/dev/null
./pushall.sh -c self -t "Title" -T "Text" -I "pushall_id" -K "pushall_key" queue >/dev/null
assert_raises "[ -s $QUEUE_FILE ]" 0
assert_raises "./pushall.sh clear" 0
assert_raises "[ -s $QUEUE_FILE ]" 1

assert_end "Queue clear"

# Queue run
./pushall.sh -c self -t "Title" -T "Text" -I "pushall_id" -K "pushall_key" queue >/dev/null
./pushall.sh -c self -t "Title" -T "Text" -I "pushall_id" -K "pushall_key" queue >/dev/null
./pushall.sh -c self -t "Title" -T "Text" -I "pushall_id" -K "pushall_key" queue >/dev/null
assert_raises "[ -s $QUEUE_FILE ]" 0
assert_raises "./pushall.sh run" 0
assert_raises "[ -s $QUEUE_FILE ]" 1

assert_end "Queue run"

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
