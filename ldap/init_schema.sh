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
domain_name=""
BASE_DN=""
out_file=""

dom_part() {
	local _p=$1 _dn=$2
	res=`echo $_dn | cut -f$_p -d'.'`
	echo $res
}
cleanup() {
	[[ -f "$TEMP" ]] && rm -f $TEMP
}

usage() {
	echo "${0##*/} [-h] [-b base_dn] [-D admin_dn] [-H ldap_host] [-o out.ldif] <domain.name>"
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
if [ -z "${LDAP_HOST}" -o -z "${ADMIN_DN}" -o -z "${BASE_DN}" ]; then
	echo "error missing args"
	usage
	exit 2
fi

if [ -z "$1" ]; then
	echo "no DOMAIN NAME specified"
	exit 1
else
	domain_name=$1
fi

if [ -z "$BASE_DN" ]; then
	for p in `echo $domain_name | tr '.' ' '`; do
		BASE_DN="$base_dn dc=$p"
	done
	BASE_DN=`echo $base_dn | tr ' ' ','`
fi

trap cleanup EXIT
trap cleanup HUP
trap cleanup ALRM

TEMP=`mktemp`

# base schema
cat << EOF > $TEMP
#
# Simple LDAP Schema
#
dn: $BASE_DN
objectclass: dcObject
objectclass: organization
dc: `dom_part 1 $domain_name`
o: $domain_name LDAP Server
description: Root entry for $domain_name

# First level
dn: ou=people,$BASE_DN
objectclass: organizationalUnit
ou: people
description: All people in organization

dn: ou=groups,$BASE_DN
objectclass: organizationalUnit
ou: groups
description: All groups in organization

dn: ou=domains,$BASE_DN
objectclass: organizationalUnit
ou: domains
description: All domains in organization

dn: ou=services,$BASE_DN
objectclass: organizationalUnit
ou: services
description: All sevices in organization

# Second level
dn: dc=$domain_name,ou=domains,$BASE_DN
objectclass: domain
dc: $domain_name
description: Main domain

dn: cn=everybody,ou=groups,$BASE_DN
objectclass: groupOfNames
cn: everybody
description: All Users

dn: cn=ldap_admins,ou=groups,$BASE_DN
objectclass: groupOfNames
cn: ldap_admins
description: LDAP Admins

EOF

if [ -z "$out_file" ]; then
	cat $TEMP
else
	mv -f $TEMP $out_file
fi

exit 0
