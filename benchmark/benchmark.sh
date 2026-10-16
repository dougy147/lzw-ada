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
    local file="$1"
    local max_bits=${2:-24}
    original_size=$(get_size $file)
    echo -ne "$file\t$original_size"
    tmp=$(mktemp) 
    $PROG_NAME c "$file" -b $max_bits -o $tmp
    compressed_size=$(get_size $tmp)
    echo -ne "\t$compressed_size"
    ratio=$(( (compressed_size * 100 / original_size) ))
    #echo -ne "\t$ratio%" # ratio
    echo -ne "\t-$((100 - ratio))%" # ratio
    ratios=$((ratios + ratio))
    $PROG_NAME d "$tmp" -b $max_bits -o "$tmp.decoded"
    cmp "$tmp.decoded" "$file"
    echo ""
    rm "$tmp" "$tmp.decoded"
}

PROG_NAME=./lzw_ada

if [[ -d "$1" ]]; then
    ratios=0 files_count=0
    echo "File__(${2:-24}-max-bits)" "Original_Size" "Compressed_Size" "Rate"
    echo "-------------------------" "-------------" "---------------" "-----"
    for file in $1/*; do                                                              
        [[ -f "$file" ]] || continue                                                  
        bench "$file" $2                                                              
        ((files_count++))                                                             
    done                                                                              
    echo "-------------------------" "-------------" "---------------" "-----"
    echo "x" "x" "x" "-$((100 - ratios / files_count))%"
elif [[ -f "$1" ]]; then
    bench "$1" $2
fi
