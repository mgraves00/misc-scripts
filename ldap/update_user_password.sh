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

usage() {
	echo "${0##*/} [-h] [-o out.ldif] [-t [CRYPT]|SSHA] <user_dn> [pass]"
}
if [ -f "./ENV" ]; then
	. ./ENV
fi
args=`getopt ho:t: $*`
if [ $? -ne 0 ]; then
	echo "error with args"
	usage
	exit 2
fi
ptype=CRYPT
set -- $args
# search for -u first... save rest for later
while [ $# -ne 0 ]; do
	case "$1" in
	-h)
		usage
		exit 0;;
	-o)
		out_file="$2"
		shift; shift;;
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
	echo "must specify a username"
	exit 1
fi
if [ -z "$2" ]; then
	ask_pass
	newpass=$resp
	echo ""
else
	newpass=$2
fi
newpass=`./hash_passwd.sh -t $ptype $newpass`

trap cleanup EXIT
trap cleanup HUP
trap cleanup ALRM
TEMP=`mktemp`

./modify_data.sh -r $1 -o $TEMP -m userPassword=$newpass

if [ -z "$out_file" ]; then
	cat ${TEMP}
else
	mv -f ${TEMP} $out_file
fi
exit 0

