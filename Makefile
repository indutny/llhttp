CLANG ?= clang
CFLAGS ?=

CFLAGS += -Os -g3 -Wall -Wextra -Wno-unused-parameter
INCLUDES += -Ibuild/

all: build/libllhttp.a

clean:
	rm -rf release/
	rm -rf build/

llx: build/llx

test-fast: build/compat
	rm -f _out
	./build/compat >>_out 2>>_out

test: build/compat
	./build/compat

test-g: build/compat-g
	lldb -o run -o bt -o exit ./build/compat-g

build/compat: test/compat/compat.c test/compat/http_parser.h
	$(CLANG) $(CFLAGS) $(INCLUDES) -o $@  -Wfatal-errors -Werror $< build/libllhttp.a

build/compat-g: test/compat/compat.c test/compat/http_parser.h
	$(CLANG) -g $(INCLUDES) -o $@ -Wfatal-errors -Werror $< build/libllhttp.a


build/libllhttp.a: build/c/llhttp.o build/native/api.o \
		build/native/http.o
	$(AR) rcs $@ build/c/llhttp.o build/native/api.o build/native/http.o

build/bitcode/llhttp.o: build/bitcode/llhttp.bc
	$(CLANG) $(CFLAGS) -c $< -o $@

build/c/llhttp.o: build/c/llhttp.c
	$(CLANG) $(CFLAGS) $(INCLUDES) -c $< -o $@

build/native/%.o: src/native/%.c build/llhttp.h src/native/api.h \
		build/native
	$(CLANG) $(CFLAGS) $(INCLUDES) -c $< -o $@

build/llx: test/llx/llx.c
	$(CLANG) $(CFLAGS) $(INCLUDES) -o $@  -Wfatal-errors -Werror $< build/libllhttp.a

build/llhttp.h: generate
build/bitcode/llhttp.bc: generate
build/c/llhttp.c: generate

build/native:
	mkdir -p build/native

release: generate
	mkdir -p release/src
	mkdir -p release/include
	cp -rf build/llhttp.h release/include/
	cp -rf build/c/llhttp.c release/src/
	cp -rf src/native/*.c release/src/
	cp -rf src/llhttp.gyp release/
	cp -rf src/common.gypi release/
	cp -rf README.md release/
	cp -rf LICENSE-MIT release/

postversion: release
	git push
	git checkout release
	cp -rf release/* ./
	rm -rf release
	git add include src *.gyp *.gypi README.md LICENSE-MIT
	git commit -a -m "release: $(TAG)"
	git tag "release/v$(TAG)"
	git push && git push --tags
	git checkout master

generate:
	./bin/generate.ts

.PHONY: all generate clean release
