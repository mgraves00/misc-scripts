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

## main

p=`ask_pass`
echo ""
if [ -z "$p" ]; then
	echo "no password"
	exit 1
fi


LPH=`salted_pass $p`
echo $LPH
