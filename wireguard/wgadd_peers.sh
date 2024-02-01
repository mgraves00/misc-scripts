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

WGPEERFILE="/etc/wireguard/peers"

# to be called by /etc/netstart
if [ -z "$1" ]; then
  # no interface name specified
  exit 1
fi
if [ ! -z "$2" ]; then
  FILTER=$2
fi
if [ ! -f $WGPEERFILE ]; then
  # if not peer file just exit nicely... no error
  exit 0
fi

# loop thru peers file and construct ifconfig command
egrep -v "^#" $WGPEERFILE | while read name descr pub psk port addrs; do
  if [ ! -z "$FILTER" ]; then
    if [ "$FILTER" != "$descr" ]; then
      continue
    fi
  fi
  _cmd=""
  if [ ! -z "$pub" ]; then
    _cmd="$_cmd wgpeer $pub"
  fi
  if [ ! -z "$psk" -a "$psk" != "\"\"" ]; then
    _cmd="$_cmd wgpsk $psk"
  fi
  if [ ! -z "$descr" -a "$descr" != "\"\"" ]; then
    _cmd="$_cmd wgdescr $descr"
  fi
  if [ ! -z "$addrs" ]; then
    for addr in $addrs; do
      _cmd="$_cmd wgaip $addr"
    done
  fi
  if [ ! -z "$name" -a ! -z "$port" ]; then
    # if name == network then the port has alerady been set ... so skip
    case "$name" in 
      network)	;;	# skip
      remote)	;;	# skip
      *)
        # get the IPv4 Address
        haddr=`host -tA $name | awk '{ print $4 }'`
	[[ $? -eq 1 ]] && continue
	[[ "$haddr" == "found:" ]] && (echo "failed to find address for $name. Skipping"; continue)
	[[ "$haddr" == "pointer" ]] && haddr=$name # IP was specified
        _cmd="$_cmd wgendpoint $haddr $port"
        ;;
    esac
  fi
  ifconfig $1 $_cmd
done

exit 0
