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

egrep -v "^#" $WGPEERFILE | while read name pub psk addr port rest; do
  _cmd=""
  if [ ! -z "$pub" -a ! -z "$psk" -a ! -z "$addr" ]; then
    _cmd="$_cmd wgpeer $pub wgpsk $psk wgaip $addr"
  fi
  if [ ! -z "$name" -a ! -z "$port" ]; then
    _cmd="$_cmd wgendpoint $name $port"
  fi
  ifconfig $1 $_cmd
done
exit 0
