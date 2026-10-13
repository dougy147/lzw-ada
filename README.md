Experimenting with [LZW](https://en.wikipedia.org/wiki/Lempel%E2%80%93Ziv%E2%80%93Welch) algorithm and Ada.

```console
$ gnatmake -I./src lzw_ada.adb
```

# Overview

```console
$ ./lzw_ada -h
USAGE: ./lzw_ada <FLAGS> <INPUT_FILE> [OPTS]
FLAGS:
    c|compress
    d|decompress
OPTS:
    -o|--output <FILE>  : default=INPUT_FILE.lzw
    -b|--max-bits <INT> : limit for bits-packing size
```

# Benchmarking

```bash
for max_bits in 12 16 24 32; do 
    { time ./benchmark/benchmark.sh ./benchmark/ $max_bits | column -t; } 2>&1 | tee -a summary.txt;
done
```

# RESOURCES

- https://en.wikipedia.org/wiki/Lempel%E2%80%93Ziv%E2%80%93Welch
- https://vapier.github.io/ncompress/
- https://web.archive.org/web/20190217073454/https://marknelson.us/posts/2011/11/08/lzw-revisited.html
- Salomon, David. Data Compression: The Complete Reference - p. 199
- https://www.data-compression.info/Corpora/CanterburyCorpus/
- https://corpus.canterbury.ac.nz/
