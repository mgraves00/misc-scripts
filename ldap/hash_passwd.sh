#!/bin/sh

# MIT License
# 
# Copyright (c) 2022 mgraves00
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

ask_pass() {
	stty -echo
	IFS= read -r pass?'enter password (will not echo):'
	stty echo
	echo $pass
}

#### not safe from 'ps'
salted_pass() {
	[[ -z "$1" ]] && return 1
	RND_SALT=`openssl rand -base64 6`
	PASS_HASH=`echo -n "$1$RND_SALT" | openssl dgst -sha1 -binary | openssl enc -base64 -A`
	LDAP_PASS_HASH=`(echo -n "$PASS_HASH" | openssl base64 -d -A; echo -n "$RND_SALT";) | openssl enc -base64 -A | awk '{print "{SSHA}"$0 }'`
	echo $LDAP_PASS_HASH
	return 0
}

usage() {
	echo "${0##*/} [-h] [-t [CRYPT]|SSHA] [pass]"
}

## main
args=`getopt ht: $*`
if [ $? -ne 0 ]; then
	echo "error with args"
	usage
	exit 2
fi
ptype=CRYPT
set -- $args
while [ $# -ne 0 ]; do
	case "$1" in
	-h)
		usage
		exit 0;;
	-t)
		t=`echo $2 | tr [a-z] [A-Z]`
		case $t in
			CRYPT)
				ptype=CRYPT;;
			SSHA)
				ptype=SSHA;;
			*)
				echo "unknown type $2"
				usage
				exit 1
				;;
		esac
		shift; shift;;
	--)
		shift; break;;
	esac
done

if [ -z "$1" ]; then
	p=`ask_pass`
	echo ""
else
	p=$1
fi

case $ptype in
	CRYPT)
		LPH=`encrypt $p`
		echo "{CRYPT}$LPH"
		;;
	SSHA)
		LPH=`salted_pass $p`
		echo "$LPH"
		;;
esac

