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
	echo "${0##*/} [-o output.ldif] -r record_dn [[-m key=val] [-d key] [-a key=val]...]"
}

trap cleanup EXIT
trap cleanup HUP
trap cleanup ALRM

if [ -f "./ENV" ]; then
	. ./ENV
fi

RDN=""

args=`getopt a:d:hm:o:r: $*`
if [ $? -ne 0 ]; then
	echo "error with args"
	echo usage
	exit 2
fi
set -- $args
CNT=0
# search for -u first... save rest for later
while [ $# -ne 0 ]; do
	case "$1" in
	-a|-d|-m)
		CNT=$((CNT+1))
		shift; shift;;
	-h)
		usage
		exit 0;;
	-o)
		out_file="$2"
		shift; shift;;
	-r)
		RDN=$2
		shift; shift;;
	--)
		shift; break;;
	esac
done
if [ -z "$RDN" ]; then
	echo "Must Specify a record DN to work on"
	usage
	exit 1
fi
if [ $CNT -le 0 ]; then
	echo "Nothing to do"
	usage
	exit 1
fi

# INIT the TEMP FILE
echo "dn: ${RDN}" >>${TEMP}
echo "changetype: modify" >>${TEMP}

# now go thru the args again to add the add/modify/delete commands
set -- $args
while [ $# -ne 0 ]; do
	case "$1" in
	-a)
		kv=$2
		key=`echo $kv | cut -f1 -d=`
		val=`echo $kv | cut -f2 -d=`
		echo "add: ${key}" >>${TEMP}
		echo "${key}: ${val}" >>${TEMP}
		echo "-" >>${TEMP}
		shift; shift;;
	-d)
		kv=$2
		key=`echo $kv | cut -f1 -d=`
		val=`echo $kv | cut -f2 -s -d=`
		echo "delete: ${key}" >>${TEMP}
		if [ ! -z "${val}" ]; then
			echo "${key}: ${val}" >>${TEMP}
		fi
		echo "-" >>${TEMP}
		shift; shift;;
	-m)
		kv=$2
		key=`echo $kv | cut -f1 -d=`
		val=`echo $kv | cut -f2 -d=`
		echo "replace: ${key}" >>${TEMP}
		echo "${key}: ${val}" >>${TEMP}
		echo "-" >>${TEMP}
		shift; shift;;
	-o)
		shift; shift;;
	-r)
		shift; shift;;
	--)
		shift; break;;
	esac
done

if [ -z "$out_file" ];then
	cat ${TEMP}
else
	mv -f ${TEMP} ${out_file}
fi

exit 0
