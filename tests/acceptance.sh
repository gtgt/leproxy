#!/bin/bash

# test against first argument or search first file matching "leproxy*.php"
bin=${1:-$(ls -b leproxy*.php | head -n1 || echo leproxy.php)}
echo "Testing $bin"

# test command line arguments
out=$(php $bin --version) && echo -n "OK (" && echo -n $out && echo ")" || (echo "FAIL: $out" && exit 1) || exit 1
out=$(php $bin --help) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(php $bin -h) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(php $bin --unknown 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
out=$(php $bin --unknown 2>&1 || true) && echo "$out" | grep -q "see --help" && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(php $bin invalid 2>&1 || true) && echo "$out" | grep -q "see --help" && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(php $bin 8080 2>&1 || true) && echo "$out" | grep -q "see --help" && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(php $bin user:pass@[::] --allow-unprotected 2>&1 || true) && echo "$out" | grep -q "see --help" && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(php $bin --block=http:// 2>&1 || true) && echo "$out" | grep -q "see --help" && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(php $bin --proxy= 2>&1 || true) && echo "$out" | grep -q "see --help" && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(php $bin --proxy=tcp://host/ 2>&1 || true) && echo "$out" | grep -q "see --help" && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

killall php 2>&- 1>&- || true
php $bin 127.0.0.1:8180 --no-log &
sleep 2

out=$(curl -v --head --silent --fail http://localhost:8180/pac 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 http://127.0.0.1:8180/pac 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy http://localhost:8180 http://localhost:8180/pac 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 --location http://github.com 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy socks5h://127.0.0.1:8180 http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy socks4a://127.0.0.1:8180 --location http://github.com  2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

# ensure we can receive multiple "Set-Cookie" headers
out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 "http://httpbin.org/cookies/set?k2=v2&k1=v1" 2>&1) && (echo "$out" | grep -q "Set-Cookie: k2=v2;" && echo OK) || (echo "FAIL: $out" && exit 1) || exit 1

# unneeded authentication should work
out=$(curl -v --head --silent --fail --proxy http://user:pass@127.0.0.1:8180 http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy socks5h://user:pass@127.0.0.1:8180 http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

# invalid URIs should return error
out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 http://test.invalid/test 2>&1) && echo "FAIL: $out" && exit 1 || (echo "$out" | grep -q "502 Bad Gateway" && echo OK) || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 https://test.invalid/test 2>&1) && echo "FAIL: $out" && exit 1 || (echo "$out" | grep -q "502 Bad Gateway" && echo OK) || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy socks://127.0.0.1:8180 http://test.invalid/test 2>&1) && echo "FAIL: $out" && exit 1 || echo OK

# restart LeProxy with really short timeout to ensure timeout error
killall php 2>&- 1>&- || true
php -d default_socket_timeout=0.001 $bin 127.0.0.1:8180 --no-log &
sleep 2

out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 https://www.youtube.com 2>&1) && echo "FAIL: $out" && exit 1 || (echo "$out" | grep -q "504 Gateway Time-out" && echo OK) || (echo "FAIL: $out" && exit 1) || exit 1

# restart LeProxy on IPv6 address
killall php 2>&- 1>&- || true
php $bin [::]:8180 --no-log &
sleep 2

out=$(curl -v --head --silent --fail --proxy http://[::1]:8180 http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy http://[::1]:8180 http://[::1]:8180/pac 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy socks://[::1]:8180 -4 http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy socks://127.0.0.1:8180 -4 http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy socks5://[::1]:8180 http://[::1]:8180/pac 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

# restart LeProxy with hosts and plain HTTP port blocked
killall php 2>&- 1>&- || true
php $bin 127.0.0.1:8180 --block=youtube.com --block=*.google.com --block=*:80 --no-log &
sleep 2

out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 https://youtube.com 2>&1) && echo "FAIL: $out" && exit 1 || (echo "$out" | grep -q "403 Forbidden" && echo OK) || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy socks5h://127.0.0.1:8180 https://youtube.com 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 https://www.google.com 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
out=$(curl -v --head --silent --fail --proxy socks5h://127.0.0.1:8180 https://www.google.com 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 http://youtube.com 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
out=$(curl -v --head --silent --fail --proxy socks5h://127.0.0.1:8180 http://www.google.com 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 http://google.de 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
out=$(curl -v --head --silent --fail --proxy socks5h://127.0.0.1:8180 http://www.google.de 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 https://www.youtube.com 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
out=$(curl -v --head --silent --fail --proxy socks5h://127.0.0.1:8180 https://www.youtube.com 2>&1) && echo "FAIL: $out" && exit 1 || echo OK

out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 https://google.de 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy socks5h://127.0.0.1:8180 https://google.de 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

# restart LeProxy with hosts file and plain HTTP port blocked
killall php 2>&- 1>&- || true
php $bin 127.0.0.1:8180 --block-hosts=tests/hosts-google --no-log &
sleep 2

out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 https://google.com 2>&1) && echo "FAIL: $out" && exit 1 || (echo "$out" | grep -q "403 Forbidden" && echo OK) || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 https://maps.google.com 2>&1) && echo "FAIL: $out" && exit 1 || (echo "$out" | grep -q "403 Forbidden" && echo OK) || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 https://google.de 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

# restart LeProxy on Unix domain socket path and another LeProxy instance for chaining
killall php 2>&- 1>&- || true
php $bin ./leproxy.tmp.socket --no-log &
pid=$!
php $bin :8180 --proxy ./leproxy.tmp.socket --no-log &
sleep 2

out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
kill $pid && rm leproxy.tmp.socket && echo . || (echo "FAIL" && exit 1) || exit 1

# restart LeProxy with authentication required
killall php 2>&- 1>&- || true
php $bin user:pass@127.0.0.1:8180 --no-log &
sleep 2

# authentication should work
out=$(curl -v --head --silent --fail --proxy http://user:pass@127.0.0.1:8180 http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy socks5h://user:pass@127.0.0.1:8180 http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

# invalid authentication should return error
out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8180 http://reactphp.org 2>&1) && echo "FAIL: $out" && exit 1 || echo OK
out=$(curl -v --head --silent --fail --proxy socks5h://127.0.0.1:8180 http://reactphp.org 2>&1) && echo "FAIL: $out" && exit 1 || echo OK

# start another LeProxy instance for HTTP proxy chaining / nesting
php $bin 127.0.0.1:8181 --proxy=http://user:pass@127.0.0.1:8180 --no-log &
sleep 2

# client does not need authentication because first chain passes to next via HTTP
out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8181 http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy socks5h://127.0.0.1:8181 http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

# start another LeProxy instance for SOCKS proxy chaining / nesting
php $bin 127.0.0.1:8182 --proxy=socks://user:pass@127.0.0.1:8180 --no-log &
sleep 2

# client does not need authentication because first chain passes to next via SOCKS
out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8182 http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1
out=$(curl -v --head --silent --fail --proxy socks5h://127.0.0.1:8182 http://reactphp.org 2>&1) && echo OK || (echo "FAIL: $out" && exit 1) || exit 1

# start another LeProxy instance for invalid HTTP proxy chaining / nesting
php $bin 127.0.0.1:8183 --proxy=http://user:invalid@127.0.0.1:8180 --no-log &
sleep 2

# client does not need authentication because first chain passes to next via HTTP
out=$(curl -v --head --silent --fail --proxy http://127.0.0.1:8183 https://youtube.com 2>&1) && echo "FAIL: $out" && exit 1 || (echo "$out" | grep -q "502 Bad Gateway" && echo OK) || (echo "FAIL: $out" && exit 1) || exit 1

killall php 2>&- 1>&- || true
echo DONE
