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

TOPX=10
FILE="/var/log/authlog"
FILE=${1:-${FILE}}
CAT="cat"
ZFILE=${FILE%%.gz}
if [ ${ZFILE} != ${FILE} ]; then
        CAT="zcat"
fi
# targeted accounts names
printf "\ntargeted user accounts top ${TOPX}\n"
printf "-----------------------------------\n"
${CAT} ${FILE} | grep Failed | grep -v invalid | cut -f2 -d"]" | cut -f5 -d" " | sort | uniq -c | sort -r | head -${TOPX}

# bad hosts
printf "\nfailed login attempts from top ${TOPX}\n"
printf "-----------------------------------\n"
${CAT} ${FILE} | grep Failed | grep -v invalid | cut -f2 -d"]" | cut -f7 -d" " | sort | uniq -c | sort -r | head -${TOPX}

# invalid account login attempts
printf "\ninvalid account login attempts ${TOPX}\n"
printf "-----------------------------------\n"
${CAT} ${FILE} | grep Failed | grep invalid | cut -f2 -d"]" | cut -f7 -d" " | sort | uniq -c | sort -r | head -${TOPX}

