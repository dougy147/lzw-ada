#!/usr/bin/env bash

# Compare our prog to `compress` and `marknelson`

usage() {
    echo "$0 <dir>"
    exit $1
}

[[ -d $1 || -f $1 ]] || usage 1

get_size() {
    du -b $1 | awk '{print $1}'
}

bench() {
    local file="$1"
    local max_bits=${2:-24}
    original_size=$(get_size "$file")
    echo -ne "$file\t$original_size"
    tmp=$(mktemp) 
    $PROG_NAME c "$file" -b $max_bits -o $tmp
    our_compressed_size=$(get_size $tmp)
    #echo -ne "\t$our_compressed_size\t($(( (our_compressed_size * 100 / original_size) ))%)"
    echo -ne "\t$our_compressed_size"
    compress -b $max_bits -k "$file"
    their_compressed_size=$(get_size "$file.Z")
    echo -e "\t$their_compressed_size"
    rm "$tmp"
    rm "$file.Z"
}

PROG_NAME=./lzw_ada

if [[ -d $1 ]]; then
    echo "File_(max-bits=${2:-24})" "Original-Size" "\`$PROG_NAME\`" "\`ncompress\`"
    echo "------------------------" "-------------" "--------------" "-------------"
    for file in $1/*; do
        [[ -f "$file" ]] || continue
        bench "$file" $2
    done
elif [[ -f "$1" ]]; then
    bench "$1" $2
fi
