.PHONY: lzw_ada

all: lzw_ada

lzw_ada: lzw_ada.adb ./src/lzw.adb ./src/lzw.ads
	mkdir -p ./build
	gnatmake -f -I./src -D ./build lzw_ada.adb
