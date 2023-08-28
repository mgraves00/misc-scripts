#!/bin/sh

# MIT License
# 
# Copyright (c) 2023 Michael Graves
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

TABLE="banned"
STDIN=0
WHITELIST="/var/db/pf.whitelist"

block_addr() {
  local _table=$1
  local _address=$2

  [[ -z "$_table" ]] && return 1
  [[ -z "$_address" ]] && return 1

  grep -q $_address $WHITELIST >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    return 1
  fi

  echo "Blocking $_address"
  pfctl -t $_table -T add $_address >/dev/null 2>&1
  pfctl -k $_address >/dev/null 2>&1
  return 0
}

if [ $# -lt 1 ]; then
  STDIN=1
fi

if [ STDIN -eq 1 ]; then
  addresses=`cat`
else
  addresses=$*
fi

for a in $addresses; do
  block_addr $TABLE $a
done
