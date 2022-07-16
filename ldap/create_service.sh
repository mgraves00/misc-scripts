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

resp=""
out_file=""

cleanup() {
	[[ -f "$TEMP" ]] && rm -f $TEMP
}

ask() {
	local _q=$1 _d=$2
	echo -n "$_q [$_d]: "
	read resp
	resp=${resp:=$_d}
	return
}

ask_pass() {
	stty -echo
	IFS= read -r resp?'enter password (will not echo):'
	stty echo
	echo ""
}

salted_pass() {
	[[ -z "$1" ]] && return 1
	RND_SALT=`openssl rand -base64 6`
	PASS_HASH=`echo -n "$1$RND_SALT" | openssl dgst -sha1 -binary | openssl enc -base64 -A`
	LDAP_PASS_HASH=`(echo -n "$PASS_HASH" | openssl base64 -d -A; echo -n "$RND_SALT";) | openssl enc -base64 -A | awk '{print "{SSHA}"$0 }'`
	echo $LDAP_PASS_HASH
	return 0
}

usage() {
	echo "${0##*/} [-h] [-b base_dn] [-D admin_dn] [-H ldap_host] [-b base_dn] [-o out.ldif] <username> [pass]"
}
if [ -f "./ENV" ]; then
	. ./ENV
fi
args=`getopt b:D:H:ho: $*`
if [ $? -ne 0 ]; then
	echo "error with args"
	usage
	exit 2
fi
set -- $args
# search for -u first... save rest for later
while [ $# -ne 0 ]; do
	case "$1" in
	-b)
		BASE_DN=$2
		shift; shift;;
	-D)
		ADMIN_DN=$2
		shift; shift;;
	-h)
		usage
		exit 0;;
	-H)
		LDAP_HOST=$2
		shift; shift;;
	-o)
		out_file="$2"
		shift; shift;;
	--)
		shift; break;;
	esac
done
if [ -z ${LDAP_HOST} -o -z ${ADMIN_DN} -o -z ${BASE_DN} ]; then
	echo "error missing args"
	usage
	exit 2
fi

if [ -z "$1" ]; then
	echo "must specify a service name"
	exit 1
fi

trap cleanup EXIT
trap cleanup HUP
trap cleanup ALRM
TEMP=`mktemp`

if [ -z "$2" ]; then
	ask_pass
	pass=`salted_pass $resp`
else
	pass=`salted_pass $2`
fi

cat << EOF > $TEMP
#
# Create Service $1
#
dn: cn=$1,ou=service,$BASE_DN
objectclass: person
cn: $1
sn: $1
description: $1 service account
userPassword: $pass
EOF

if [ -z "$out_file" ]; then
	cat ${TEMP}
else
	mv -f ${TEMP} $out_file
fi
exit 0

