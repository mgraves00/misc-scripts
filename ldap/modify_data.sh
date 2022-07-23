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

out_file=""
TEMP=`mktemp`

cleanup() {
	if [ -f "$TEMP" ]; then
		rm -f $TEMP
	fi
}

usage() {
	echo "${0##*/} -r record_dn [-o output.ldif] [[-m key=val] [-d key] [-a key=val]...]"
}

trap cleanup EXIT
trap cleanup HUP
trap cleanup ALRM

if [ -f "./ENV" ]; then
	. ./ENV
fi

# getopt doesn't handle args with spaces.  too many shell interpertations
# so just run thru the args and save the ones that don't match anything
args=""
RDN=0
# now go thru the args again to add the add/modify/delete commands
#set -- $args
while [ $# -ne 0 ]; do
	case "$1" in
	-a)
		if [ ${RDN} -eq 0 ]; then
			echo "must specify -r first"
			usage
			exit 1
		fi
		kv=$2
		key=`echo $kv | cut -f1 -d=`
		val=`echo $kv | cut -f2- -d=`
		echo "add: ${key}" >>${TEMP}
		echo "${key}: ${val}" >>${TEMP}
		echo "-" >>${TEMP}
		shift; shift;;
	-d)
		if [ ${RDN} -eq 0 ]; then
			echo "must specify -r first"
			usage
			exit 1
		fi
		kv=$2
		key=`echo $kv | cut -f1 -d=`
		val=`echo $kv | cut -f2- -s -d=`
		echo "delete: ${key}" >>${TEMP}
		if [ ! -z "${val}" ]; then
			echo "${key}: ${val}" >>${TEMP}
		fi
		echo "-" >>${TEMP}
		shift; shift;;
	-m)
		if [ ${RDN} -eq 0 ]; then
			echo "must specify -r first"
			usage
			exit 1
		fi
		kv=$2
		key=`echo $kv | cut -f1 -d=`
		val=`echo $kv | cut -f2- -d=`
		echo "replace: ${key}" >>${TEMP}
		echo "${key}: ${val}" >>${TEMP}
		echo "-" >>${TEMP}
		shift; shift;;
	-o)
		out_file=$2
		shift; shift;;
	-r)
		if [ ${RDN} -eq 0 ]; then
			RDN=1
			echo "dn: $2" >>${TEMP}
			echo "changetype: modify" >>${TEMP}
		else
			echo "record DN already specified"
			usage
			exit 1
		fi
		shift; shift;;
	--)
		shift; break;;
	*)
		# noting matched... save for later
		args="${args} $1"
		shift;;
	esac
done
set -- $args

if [ -z "$out_file" ];then
	cat ${TEMP}
else
	mv -f ${TEMP} ${out_file}
fi

exit 0
