#!/bin/ksh

. ./ipaddress.lib.sh

function run_test {
	local _cmd=$1
	local _exp=$2
	local _test, _rc, _o

	echo -n "checking '${_cmd}' ? '${_exp}' => "
	_rc=0
	_test=$(eval "$_cmd")
	_rc=$?
	if [ "$_exp" == "$_test" ]; then
		echo "ok($_rc)"
	else
		echo "failed($_rc) '${_test}'"
	fi
}

run_test "echo '192.168.1.1/32' | v4network" "192.168.1.1"
run_test "echo '192.168.1.1/24' | v4network" "192.168.1.0"
run_test "echo '192.168.1.1/16' | v4network" "192.168.0.0"
run_test "echo '192.168.1.1/16' | v4broadcast" "192.168.255.255"
run_test "echo '0' | v4bit2mask" "0.0.0.0"
run_test "echo '16' | v4bit2mask" "255.255.0.0"
run_test "echo '17' | v4bit2mask" "255.255.128.0"
run_test "echo '255.255.255.0' | v4mask2bit" "24"

run_test "echo '255.255.255.0' | v4mask2bit | v4bit2wild" "0.0.0.255"
run_test "echo '255.255.254.0' | v4mask2bit | v4bit2wild" "0.0.1.255"

run_test "echo '192.168.1.1/24' | v4network | v4reverse" "0.1.168.192"
run_test "echo '192.168.1.1/24' | v4network | v4octs "3" | v4reverse" "1.168.192"

run_test "echo '1.2.3.4' | isv4" ""
run_test "echo '1.2.3.256' | isv4" ""

run_test "echo '2001:db8::1' | isv6" ""
run_test "echo '2001:db8::q' | isv6" ""
run_test "echo '128' | v6bit2mask" "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff"
run_test "echo '127' | v6bit2mask" "ffff:ffff:ffff:ffff:ffff:ffff:ffff:fffe"
run_test "echo '126' | v6bit2mask" "ffff:ffff:ffff:ffff:ffff:ffff:ffff:fffc"
run_test "echo '125' | v6bit2mask" "ffff:ffff:ffff:ffff:ffff:ffff:ffff:fff8"
run_test "echo '124' | v6bit2mask" "ffff:ffff:ffff:ffff:ffff:ffff:ffff:fff0"
run_test "echo '120' | v6bit2mask" "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ff00"
run_test "echo  '64' | v6bit2mask" "ffff:ffff:ffff:ffff:0000:0000:0000:0000"
run_test "echo  '64' | v6bit2wild" "0000:0000:0000:0000:ffff:ffff:ffff:ffff"
run_test "echo '128' | v6bit2wild" "0000:0000:0000:0000:0000:0000:0000:0000"
run_test "echo '127' | v6bit2wild" "0000:0000:0000:0000:0000:0000:0000:0001"
run_test "echo '2001:db8::1/128' | v6network" "2001:0db8:0000:0000:0000:0000:0000:0001"
run_test "echo '2001:db8:40::1/64' | v6network" "2001:0db8:0040:0000:0000:0000:0000:0000"
run_test "echo '2001:db8:40::1/127' | v6network" "2001:0db8:0040:0000:0000:0000:0000:0000"
run_test "echo '2001:db8:40::3/127' | v6network" "2001:0db8:0040:0000:0000:0000:0000:0002"
run_test "echo '2001:db8:40::d/125' | v6network" "2001:0db8:0040:0000:0000:0000:0000:0008"

run_test "echo '2001:db8::1/128' | v6broadcast" "2001:0db8:0000:0000:0000:0000:0000:0001"
run_test "echo '2001:db8::1/64' | v6broadcast" "2001:0db8:0000:0000:ffff:ffff:ffff:ffff"
run_test "echo '2001:db8::0/127' | v6broadcast" "2001:0db8:0000:0000:0000:0000:0000:0001"

run_test "echo '2001:db8:40::/64' | v6reverse" "0.0.0.0.0.4.0.0.8.b.d.0.1.0.0.2"
