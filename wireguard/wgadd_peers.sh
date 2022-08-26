#!/bin/sh
#
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

WGPEERFILE="/etc/wireguard/peers"

# to be called by /etc/netstart
if [ -z "$1" ]; then
  # no interface name specified
  exit 1
fi
if [ ! -f $WGPEERFILE ]; then
  # if not peer file just exit nicely... no error
  exit 0
fi

# routing handled by ifstated

# loop thru peers file and construct ifconfig command
egrep -v "^#" $WGPEERFILE | while read intf name pub psk port addrs; do
  _cmd=""
  [[ "$intf" != "$1" ]] && continue
  if [ ! -z "$pub" -a ! -z "$psk" ]; then
    _cmd="$_cmd wgpeer $pub wgpsk $psk"
  fi
  if [ ! -z "$addrs" ]; then
    for addr in $addrs; do
      _cmd="$_cmd wgaip $addr"
    done
  fi
  if [ ! -z "$name" -a ! -z "$port" ]; then
    # if name == network then the port has alerady been set ... so skip
    if [ "$name" != "network" ]; then
      # get the IPv4 Address
      haddr=`host -tA $name | awk '{ print $4 }'`
      if [ $? -eq 1 ]; then
        echo "failed to find address for $name. Aborting"
        exit 1
      fi
      _cmd="$_cmd wgendpoint $haddr $port"
    fi
  fi
  ifconfig $1 $_cmd
done

exit 0
