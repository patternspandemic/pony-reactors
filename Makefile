build/reactors: build reactors/*.pony
	ponyc reactors -o build --debug

build:
	mkdir build

test: build/reactors
	build/reactors --only=$(ONLY) --exclude=$(EXCL)

clean:
	rm -rf build

.PHONY: clean test
