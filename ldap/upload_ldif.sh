#!/bin/sh

# MIT License
# 
# Copyright (c) 2025 mgraves00
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

ADMIN_DN=""
BASE_DN=""
LDAP_HOST=""

find_env() {
	LIST="/etc/ldap.env \
		/etc/openldap/ldap.env \
		/usr/local/etc/ldap.env \
		$HOME/.ldap.env"
	for f in ${LIST} ; do
		if [ -f "$f" ]; then
			echo $f
			return
		fi
	done
	echo ""
	return
}

cleanup() {
}

usage() {
	echo "${0##*/} [-h] [-b base_dn] [-D admin_dn] [-H ldap_host] [-b base_dn] <file.ldif>"
}
ENV=$(find_env)
if [ ! -z "${ENV}" -a -f "${ENV}" ]; then
		. ${ENV}
fi
args=`getopt b:D:H:hw: $*`
if [ $? -ne 0 ]; then
	echo "error with args"
	usage
	exit 2
fi
pass="-W"
set -- $args
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

if [ -z "$1" ]; then
	echo "No LDIF file specified"
	exit 1
fi
if [ ! -f "$1" ]; then
	echo "LDIF file $1 not found"
	exit 1
fi
LDIF_FILE=$1

trap cleanup EXIT
trap cleanup HUP
trap cleanup ALRM

grep -q "changetype" $LDIF_FILE
if [ $? -eq 0 ]; then
	ldapmodify -vv ${pass} -H ${LDAP_HOST} -D "${ADMIN_DN}" -f "${LDIF_FILE}"
else
	ldapadd -vv ${pass} -H ${LDAP_HOST} -D "${ADMIN_DN}" -f "${LDIF_FILE}"
fi

exit $?

