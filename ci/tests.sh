#!/bin/sh

set -e

mkdir -p mockbin

export PATH="$PWD/mockbin:$PATH"

cat > mockbin/curl <<CURL_MOCK
#!/bin/sh
echo "Curl invocation, params: \$@" >&2;
CURL_MOCK

chmod +x mockbin/curl

. assert.sh

# Usage test
assert "./pushall.sh" "$(cat usage.txt)"

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
assert_end demo

rm -rf mockbin
