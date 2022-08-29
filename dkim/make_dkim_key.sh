#!/bin/sh

# MIT License
#
# Copyright (c) 2022 Michael Graves
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

# must keep at 1024 for now because dns doesn't like DNS lines over 255 characters
KEYLEN=1024

if [ $# -lt 1 ]; then
        echo "specifiy domain"
        exit
fi
if [ -f $1.key ]; then
        echo "$1.key already exists. remove first"
        exit
fi

(umask 337; openssl genrsa -out $1.key $KEYLEN)
openssl rsa -in $1.key -pubout -out $1.pub
group info _dkimsign >/dev/null && chgrp _dkimsign $1.key
echo "add the $1.dns to the zone file"
echo "selector1._domainkey.$1. 3600 IN TXT \"v=DKIM1; k=rsa; p=$(sed -e '1d' -e '$d' $1.pub | tr -d '\n')\"" >$1.dns

