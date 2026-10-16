An experiment with [LZW](https://en.wikipedia.org/wiki/Lempel%E2%80%93Ziv%E2%80%93Welch) lossless compression algorithm.

```console
$ gnatmake -O3 -I./src lzw_ada.adb
$ ./lzw_ada -h
Usage: ./lzw_ada <MODE> <INPUT_FILE> [OPTS]
MODE:
    c|compress
    d|decompress
OPTS:
    -o|--output <FILE>  : default=INPUT_FILE.lzw
    -b|--max-bits <INT> : limit for bits-packing size
```

# BENCHMARK

Comparing to `[ncompress](https://vapier.github.io/ncompress/)` on [Canterbury corpus](https://corpus.canterbury.ac.nz/) and more:

```console
$ ./benchmark/comp-benchmark.sh ./benchmark/ 24 | column -t
File_(max-bits=24)              Original-Size  `./lzw_ada`     `ncompress`
------------------------        -------------  --------------  ------------
./benchmark//alice29.txt        152089         62245           62247
./benchmark//asyoulik.txt       125179         54987           54990
./benchmark//benchmark.sh       1526           744             746
./benchmark//bible.txt          4047392        1241875         1377093
./benchmark//comp-benchmark.sh  1065           659             661
./benchmark//cp.html            24603          11314           11317
./benchmark//E.coli             4638690        1230082         1218349
./benchmark//fields.c           11150          4962            4964
./benchmark//grammar.lsp        3721           1810            1813
./benchmark//k7.asm             1325042        105439          105441
./benchmark//kennedy.xls        1029744        320787          310451
./benchmark//lcet10.txt         426754         163170          163147
./benchmark//plrabn12.txt       481861         198464          196963
./benchmark//ptt5               513216         62213           62215
./benchmark//sum                38240          20099           20102
./benchmark//world192.txt       2473400        795209          920163
./benchmark//xargs.1            4227           2337            2339
```

# RESOURCES

- https://en.wikipedia.org/wiki/Lempel%E2%80%93Ziv%E2%80%93Welch
- https://vapier.github.io/ncompress/
- https://web.archive.org/web/20190217073454/https://marknelson.us/posts/2011/11/08/lzw-revisited.html
- Salomon, David. Data Compression: The Complete Reference - p. 199
- https://www.data-compression.info/Corpora/CanterburyCorpus/
- https://corpus.canterbury.ac.nz/
