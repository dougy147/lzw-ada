#!/usr/bin/env bash

usage() {
    echo "$0 <dir>"
    exit $1
}

[[ -d $1 || -f $1 ]] || usage 1

get_size() {
    du -b $1 | awk '{print $1}'
}

bench() {
    local file=$1
    original_size=$(get_size $file)
    echo -ne "$file\t$original_size"
    tmp=$(mktemp) 
    $PROG_NAME c "$file" -o $tmp
    compressed_size=$(get_size $tmp)
    echo -e "\t$compressed_size\t($(( (compressed_size * 100 / original_size) ))%)"
}

PROG_NAME=./lzw_ada

if [[ -d $1 ]]; then
    echo "File" "Original-Size" "Compressed-Size"
    for file in $1/*; do
        [[ -f $file ]] || continue
        bench $file
    done
elif [[ -f $1 ]]; then
    bench $1
fi
