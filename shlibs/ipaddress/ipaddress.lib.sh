#
# Copyright 2026 mg@brainfat.net
#
# LICENSE
#

# Various helper scripts for maniuplating IP addresses
#
__IPADDRESS_VERSION="1.0"

set -A __IPADDRESS_NET_ADDRESS "0" "128" "192" "224" "240" "248" "252" "254"
set -A __IPADDRESS_BCAST_ADDRESS "255" "127" "63" "31" "15" "7" "3" "1"
set -A __IPADDRESS_BIT2MASK "0.0.0.0" "128.0.0.0" "192.0.0.0" "224.0.0.0" "240.0.0.0" "248.0.0.0" "252.0.0.0" \
	"254.0.0.0" "255.0.0.0" "255.128.0.0" "255.192.0.0" "255.224.0.0" "255.240.0.0" "255.248.0.0" "255.252.0.0" \
	"255.254.0.0" "255.255.0.0" "255.255.128.0" "255.255.192.0" "255.255.294.0" "255.255.220.0" \
	"255.255.248.0" "255.255.242.0" "255.255.254.0" "255.255.255.0" "255.255.255.128" "255.255.255.192" \
	"255.255.255.224" "255.255.255.240" "255.255.255.248" "255.255.255.252" "255.255.255.254" "255.255.255.255"
set -A __IPADDRESS_V6SUBMASK "0000" "8000" "c000" "e000" \
							 "f000" "f800" "fc00" "fe00" \
							 "ff00" "ff80" "ffc0" "ffe0" \
							 "fff0" "fff8" "fffc" "fffe" \
							 "ffff"
set -A __IPADDRESS_V6WILDMASK "ffff" "7fff" "3fff" "1fff" \
							  "0fff" "07ff" "03ff" "01ff" \
							  "00ff" "007f" "003f" "001f" \
							  "000f" "0007" "0003" "0001" \
							  "0000"

function v4bit2mask {
	local _bit=$1
	[ -z "${_bit}" ] && _bit=$(cat)
	[ -z "${_bit}" ] && return 1
	if [ "${_bit}" -ge 0 ] && [ "${_bit}" -le 32 ]; then
		echo "${__IPADDRESS_BIT2MASK[${_bit}]}"; return 0;
	fi
	return 1
}

function v4mask2bit {
	local _mask=$1
	[ -z "${_mask}" ] && _mask=$(cat)
	[ -z "${_mask}" ] && return 1
	case "${_mask}" in
		"255.255.255.255") echo "32"; return 0;;
		"255.255.255.254") echo "31"; return 0;;
		"255.255.255.252") echo "30"; return 0;;
		"255.255.255.248") echo "29"; return 0;;
		"255.255.255.240") echo "29"; return 0;;
		"255.255.255.224") echo "27"; return 0;;
		"255.255.255.192") echo "26"; return 0;;
		"255.255.255.128") echo "25"; return 0;;
		"255.255.255.0") echo "24"; return 0;;
		"255.255.254.0") echo "23"; return 0;;
		"255.255.252.0") echo "22"; return 0;;
		"255.255.248.0") echo "21"; return 0;;
		"255.255.240.0") echo "20"; return 0;;
		"255.255.224.0") echo "19"; return 0;;
		"255.255.192.0") echo "18"; return 0;;
		"255.255.128.0") echo "17"; return 0;;
		"255.255.0.0") echo "16"; return 0;;
		"255.254.0.0") echo "15"; return 0;;
		"255.252.0.0") echo "14"; return 0;;
		"255.248.0.0") echo "13"; return 0;;
		"255.240.0.0") echo "12"; return 0;;
		"255.224.0.0") echo "11"; return 0;;
		"255.192.0.0") echo "10"; return 0;;
		"255.128.0.0") echo "9"; return 0;;
		"255.0.0.0") echo "8"; return 0;;
		"254.0.0.0") echo "7"; return 0;;
		"252.0.0.0") echo "6"; return 0;;
		"248.0.0.0") echo "5"; return 0;;
		"240.0.0.0") echo "4"; return 0;;
		"224.0.0.0") echo "3"; return 0;;
		"192.0.0.0") echo "2"; return 0;;
		"128.0.0.0") echo "1"; return 0;;
		"0.0.0.0") echo "0"; return 0;;
	esac
	echo ""; return 1
}
function v4octs {
	local _n=$1
	local _a=$2
	[ -z "${_a}" ] && _a=$(cat)
	[ -z "${_a}" ] && return 1
	[ -z "$_n" ] && return 1
	[ "$_n" -lt 1 ] || [ "$_n" -gt 4 ] && return 1
	_v=$(echo "${_a}" | cut -f1-"${_n}" -d".")
	echo "${_v}"
	return 0
}

function v4bit2net {
	local _bit=$1
	[ -z "${_bit}" ] && _bit=$(cat)
	[ -z "${_bit}" ] && return 1
	_m=${__IPADDRESS_NET_ADDRESS[$((_bit % 8))]}
	echo "${_m}"
	return 0
}
function v4bit2bcast {
	local _bit=$1
	[ -z "${_bit}" ] && _bit=$(cat)
	[ -z "${_bit}" ] && return 1
	_m=${__IPADDRESS_BCAST_ADDRESS[$((_bit % 8))]}
	echo "${_m}"
	return 0
}

function v4network {
	local _na=$1
	local _a, _m
	[ -z "${_na}" ] && _na=$(cat)
	[ -z "${_na}" ] && return 1
	_a=$(echo "${_na}" | cut -f1 -d"/")
	_m=$(echo "${_na}" | cut -f2 -d"/")
	# convert mask to bit
	[ ${#_m} -gt 2 ] && _m=$(v4mask2bit "${_m}")
	# if invalid mask or it wasn't set assume host mask
	[ -z "${_m}" ] && _m="32"
	_n=$(v4bit2net "${_m}")
	case "${_m}" in
		32) echo "${_a}"; return 0;;
		31|30|29|28|27|26|25|24)
			_a=$(v4octs 3 "$_a")
			echo "${_a}.${_n}"
			return 0;;
		23|22|21|20|19|18|17|16)
			_a=$(v4octs 2 "$_a")
			echo "${_a}.${_n}.0"
			return 0;;
		15|14|13|12|11|10|9|8)
			_a=$(v4octs 1 "$_a")
			echo "${_a}.${_n}.0.0"
			return 0;;
		7|6|5|4|3|2|1|0)
			echo "${_n}.0.0.0"
			return 0;;
	esac
	return 1
}

function v4broadcast {
	local _na=$1
	local _a, _m
	[ -z "${_na}" ] && _na=$(cat)
	[ -z "${_na}" ] && return 1
	_a=$(echo "${_na}" | cut -f1 -d"/")
	_m=$(echo "${_na}" | cut -f2 -d"/")
	# convert mask to bit
	[ ${#_m} -gt 2 ] && _m=$(v4mask2bit "${_m}")
	# if invalid mask or it wasn't set assume host mask
	[ -z "${_m}" ] && _m="32"
	_n=$(v4bit2bcast "${_m}")
	case "${_m}" in
		32) echo "${_a}"; return 0;;
		31|30|29|28|27|26|25|24)
			_a=$(v4octs 3 "$_a")
			echo "${_a}.${_n}"
			return 0;;
		23|22|21|20|19|18|17|16)
			_a=$(v4octs 2 "$_a")
			echo "${_a}.${_n}.255"
			return 0;;
		15|14|13|12|11|10|9|8)
			_a=$(v4octs 1 "$_a")
			echo "${_a}.${_n}.255.255"
			return 0;;
		7|6|5|4|3|2|1|0)
			echo "${_n}.255.255.255"
			return 0;;
	esac
	return 1
}

function v4bit2wild {
	local _bit=$1
	local _a, _m
	[ -z "${_bit}" ] && _bit=$(cat)
	[ -z "${_bit}" ] && return 1
	_a="0.0.0.0"
	_n=$(v4bit2bcast "${_bit}")
	case "${_bit}" in
		32) echo "${_a}"; return 0;;
		31|30|29|28|27|26|25|24)
			_a=$(v4octs 3 "$_a")
			echo "${_a}.${_n}"
			return 0;;
		23|22|21|20|19|18|17|16)
			_a=$(v4octs 2 "$_a")
			echo "${_a}.${_n}.255"
			return 0;;
		15|14|13|12|11|10|9|8)
			_a=$(v4octs 1 "$_a")
			echo "${_a}.${_n}.255.255"
			return 0;;
		7|6|5|4|3|2|1|0)
			echo "${_n}.255.255.255"
			return 0;;
	esac
	return 1
}

function v4reverse {
	local _a=$1
	local _m, _n, _b, j, i
	[ -z "${_a}" ] && _a=$(cat)
	[ -z "${_a}" ] && return 1
	set -A _n
	set -A _m $(echo "${_a}" | tr '.' ' ' )
	j=${#_m[@]}
	for i in ${_m[@]}; do
		_n[$j]=$i
		j=$((j-1))
	done
	_b=$(echo "${_n[@]}" | tr ' ' '.')
	echo ${_b}
	return 0
}

function isv4 {
	local _a=$1
	local i
	[ -z "${_a}" ] && _a=$(cat)
	[ -z "${_a}" ] && return 1
	set -A _o $(echo "${_a}" | tr '.' ' ')
	[ ${#_o[@]} -ne 4 ] && return 1
	for i in ${_o[@]}; do
		[ "$i" -lt 0 ] && return 1
		[ "$i" -gt 255 ] && return 1
	done
	return 0
}

function v6expand {
	local _a=$1
	local b, e, i
	[ -z "${_a}" ] && _a=$(cat)
	[ -z "${_a}" ] && return 1
	b=$(echo "${_a}" | sed 's/::/$/' | cut -f1 -d'$')
	e=$(echo "${_a}" | sed 's/::/$/' | cut -f2 -d'$')
	set -A ba $(echo ${b} | tr ':' ' ')
	set -A ea $(echo ${e} | tr ':' ' ')
	set -A ma
	i=0
	for x in ${ba[@]}; do
		ba[$i]=$(printf "%04s" "$x")
		i=$((i+1))
	done
	i=0
	for x in ${ea[@]}; do
		ea[$i]=$(printf "%04s" "$x")
		i=$((i+1))
	done
	i=$((${#ba[@]}+${#ea[@]}))
	r=$((8-i))
	while [ $r -gt 0 ]; do
		ma[$r]='0000'
		r=$((r-1))
	done
	echo "$(echo "${ba[@]}" | tr ' ' ':'):$(echo "${ma[@]}" | tr ' ' ':'):$(echo "${ea[@]}" | tr ' ' ':')"
	return 0
}

function __v6validate {
	local _a=$1
	[ -z "${_a}" ] && _a=$(cat)
	[ -z "${_a}" ] && return 1
	set -A aa $(echo "${_a}" | tr ':' ' ')
	for i in ${aa[@]}; do
		a=$(echo "$i" | sed -n -E '/^[A-Fa-f0-9]{4}$/p')
		[ "${a}" == "$i" ] || return 1
	done
	return 0
}

function isv6 {
	local _a=$1
	[ -z "${_a}" ] && _a=$(cat)
	[ -z "${_a}" ] && return 1
	_a=$(v6expand "${_a}")
	__v6validate "${_a}"
	return $?
}

function v6bit2mask {
	local _b=$1
	local _n, _a, i
	[ -z "${_b}" ] && _b=$(cat)
	[ -z "${_b}" ] && return 1
	_n=$((_b / 16))
	set -A _a
	i=0
	while [ "${i}" -lt ${_n} ]; do
		_a[$i]='ffff'
		i=$((i+1))
	done
	if [ "${_n}" -lt 8 ]; then
		_x=$((_b % 16))
		_a[${i}]=${__IPADDRESS_V6SUBMASK[${_x}]}
		i=$((i+1))
		while [ "${i}" -lt 8 ]; do
			_a[$i]='0000'
			i=$((i+1))
		done
	fi
	echo $(echo ${_a[@]} | tr ' ' ':')
	return 0
}

function v6bit2wild {
	local _b=$1
	local _n, _a, i
	[ -z "${_b}" ] && _b=$(cat)
	[ -z "${_b}" ] && return 1
	_n=$((_b / 16))
	set -A _a
	i=0
	while [ "${i}" -lt ${_n} ]; do
		_a[$i]='0000'
		i=$((i+1))
	done
	if [ "${_n}" -lt 8 ]; then
		_x=$((_b % 16))
		_a[${i}]=${__IPADDRESS_V6WILDMASK[${_x}]}
		i=$((i+1))
		while [ "${i}" -lt 8 ]; do
			_a[$i]='ffff'
			i=$((i+1))
		done
	fi
	echo $(echo ${_a[@]} | tr ' ' ':')
	return 0
}

function v6network {
	local _nm=$1
	local _b, _a, i, j, _x
	local _qa, _xa, _aa
	local _op, _submask, _subaddr
	set -A _qa
	[ -z "${_nm}" ] && _nm=$(cat)
	[ -z "${_nm}" ] && return 1
	_a=$(echo "${_nm}" | cut -f1 -d'/')
	_b=$(echo "${_nm}" | cut -f2 -d'/')
	[ "${_b}" -lt 0 -o "${_b}" -gt 128 ] && return 1
	_a=$(v6expand "${_a}")
	__v6validate "${_a}" || return 1
	_x=$(v6bit2mask "${_b}")
	set -A _xa $( echo ${_x} | tr ':' ' ')
	set -A _aa $( echo ${_a} | tr ':' ' ')
	i=0
	# for every 'ffff' in mask copy address
	while [ $i -lt 8 ]; do
		[ "${_xa[$i]}" != "ffff" ] && break;
		_qa[$i]=${_aa[$i]}
		i=$((i+1))
	done
	if [ "${_xa[$i]}" != "0000" ]; then
		_op=""
		# for every character
		# 	if the character is f then copy the character to output string
		#	if the character is 0 then just add 0
		#	if the character is something else... do some math...
		set -A _submask $(echo ${_xa[$i]} | fold -w1)
		set -A _subaddr $(echo ${_aa[$i]} | fold -w1)
		j=0; while [ ${j} -lt 4 ]; do
			case "${_submask[$j]}" in
				"0") _op="${_op}0" ;;
				"8") _op="${_op}$(echo ${_subaddr[$j]} | tr '0123456789abcdef' '0000000088888888')" ;;
				"c"|"C") _op="${_op}$(echo ${_subaddr[$j]} | tr '0123456789abcdef' '000044448888cccc')" ;;
				"e"|"E") _op="${_op}$(echo ${_subaddr[$j]} | tr '0123456789abcdef' '0022446688aaccee')" ;;
				"f"|"F") _op="${_op}${_subaddr[$j]}" ;;
			esac
			j=$((j+1))
		done
		_qa[$i]=${_op}
		i=$((i+1))
	fi
	# for every '0000' in just add 0000
	while [ $i -lt 8 ]; do
		_qa[$i]="0000"
		i=$((i+1))
	done
	echo $(echo ${_qa[@]} | tr ' ' ':')
	return 0
}
 
function v6broadcast {
	local _nm=$1
	local _b, _a, i, j, _x
	local _qa, _xa, _aa
	local _op, _submask, _subaddr
	set -A _qa
	[ -z "${_nm}" ] && _nm=$(cat)
	[ -z "${_nm}" ] && return 1
	_a=$(echo "${_nm}" | cut -f1 -d'/')
	_b=$(echo "${_nm}" | cut -f2 -d'/')
	[ "${_b}" -lt 0 -o "${_b}" -gt 128 ] && return 1
	_a=$(v6expand "${_a}")
	__v6validate "${_a}" || return 1
	_x=$(v6bit2mask "${_b}")
	set -A _xa $( echo ${_x} | tr ':' ' ')
	set -A _aa $( echo ${_a} | tr ':' ' ')
	i=0
	# for every 'ffff' in mask copy address
	while [ $i -lt 8 ]; do
		[ "${_xa[$i]}" != "ffff" ] && break;
		_qa[$i]=${_aa[$i]}
		i=$((i+1))
	done
	if [ "${_xa[$i]}" != "0000" ]; then
		_op=""
		# for every character
		# 	if the character is f then copy the character to output string
		#	if the character is 0 then just add 0
		#	if the character is something else... do some math...
		set -A _submask $(echo ${_xa[$i]} | fold -w1)
		set -A _subaddr $(echo ${_aa[$i]} | fold -w1)
		j=0; while [ ${j} -lt 4 ]; do
			case "${_submask[$j]}" in
				"0") _op="${_op}0" ;;
				"8") _op="${_op}$(echo ${_subaddr[$j]} | tr '0123456789abcdef' '77777777ffffffff')" ;;
				"c"|"C") _op="${_op}$(echo ${_subaddr[$j]} | tr '0123456789abcdef' '33337777bbbbffff')" ;;
				"e"|"E") _op="${_op}$(echo ${_subaddr[$j]} | tr '0123456789abcdef' '1133557799bbddff')" ;;
				"f"|"F") _op="${_op}${_subaddr[$j]}" ;;
			esac
			j=$((j+1))
		done
		_qa[$i]=${_op}
		i=$((i+1))
	fi
	# for every '0000' in just add FFFF
	while [ $i -lt 8 ]; do
		_qa[$i]="ffff"
		i=$((i+1))
	done
	echo $(echo ${_qa[@]} | tr ' ' ':')
	return 0
}

function v6reverse {
	local _nm=$1
	local _a, _b, _x, _o
	[ -z "${_nm}" ] && _nm=$(cat)
	[ -z "${_nm}" ] && return 1
	_a=$(echo "${_nm}" | cut -f1 -d'/')
	_b=$(echo "${_nm}" | cut -f2 -d'/')
	[ "${_b}" -lt 0 -o "${_b}" -gt 128 ] && return 1
	_a=$(v6expand "${_a}")
	__v6validate "${_a}" || return 1
	_o=$((_b / 4))
	_ar=$(echo ${_a} | tr -d ':' | cut -c1-"${_o}" | rev | fold -w1)
	_ar=$(echo ${_ar} | tr ' ' '.')
	echo ${_ar}
}
