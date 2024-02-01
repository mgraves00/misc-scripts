#!/bin/sh
#
# MIT License
#
# Copyright (c) 2024 Michael Graves
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

if [ -f ~/.wgconf ]; then
	. ~/.wgconf
fi

usage() {
	echo "Usage: ${0##*/} [-k client_key ] [-s server_addr] [-p server_port] client_address"
}

CPRIV=""
args=`getopt d:hk:p:s: $*`
if [ $? -ne 0 ]; then
	usage
	exit 2
fi
# MIT License
#
# Copyright (c) 2021 Michael Graves
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

set -- $args
while [ $# -ne 0 ]; do
	case "$1" in
		-d)
			CLIENT_DNS=$2
			shift; shift;;
		-h)
			usage
			exit 0
			shift;;
		-k)
			CPRIV=$2
			shift; shift;;
		-p)
			SERVER_PORT=$2
			shift; shift;;
		-s)
			SERVER=$2
			shift; shift;;
		--)
			shift; break;;
	esac
done

CLIENT=$1
if [ -z "$CLIENT" ]; then
	echo "client address not specified"
	usage
	exit 1
fi
if [ -z "$SERVER" ]; then
	echo "no server specified"
	usage
	exit 1
fi
if [ -z "$SERVER_PORT" ]; then
	echo "no server port specified"
	usage
	exit 1
fi
if [ -z "$SERVER_PUBKEY" ]; then
	echo "no server pubkey specified"
	usage
	exit 1
fi

if [ -z "$CPRIV" ]; then
	CPRIV=`openssl rand -base64 32`
fi

cat <<EOF
[Interface]
PrivateKey = ${CPRIV}
DNS = ${CLIENT_DNS}
Address = ${CLIENT}

[Peer]
PublicKey = ${SERVER_PUBKEY}
AllowedIPs = ${SERVER_ALLOWED_IPS}
Endpoint = ${SERVER}:${SERVER_PORT}
EOF

