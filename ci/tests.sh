#!/bin/sh

set -e

mkdir -p mockbin

export PATH="$PWD/mockbin:$PATH"

cat > mockbin/curl <<CURL_MOCK
#!/bin/sh
if [ "\$*" = "-sS --data-urlencode id=pushall_id --data-urlencode key=pushall_key --data-urlencode title=Title --data-urlencode text=Text -X POST https://pushall.ru/api.php?type=self" ]; then
	printf "%b\n" "{\\"success\\":1,\\"lid\\":6546002}"
else
	printf "%s\n" "Curl invocation, params: \$*" >&2
	printf "%s\n" "\$*" >> curl.log
fi
CURL_MOCK

chmod +x mockbin/curl

. ./assert.sh

# Usage test
assert "./pushall.sh" "$(cat usage.txt)"
assert "./pushall.sh -h" "$(cat usage.txt)"

assert_end "Usage test"

# self minimal call
assert "./pushall.sh -c self -t \"Title\" -T \"Text\" -I \"pushall_id\" -K \"pushall_key\" 2>&1" "6546002"

assert_end "Calls"

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
