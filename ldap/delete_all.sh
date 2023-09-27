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

usage() {
	echo "${0##*/} [-h] [-b base_dn] [-D admin_dn] [-H ldap_host]"
}
if [ -f "./ENV" ]; then
	. ./ENV
fi
pass="-W"
args=`getopt b:D:H:hw: $*`
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
	-w)
		pass="-w $2"
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


ldapdelete -rv ${pass} -H ${LDAP_HOST} -D "${ADMIN_DN}" "${BASE_DN}"

