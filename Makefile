build/reactors: build reactors/*.pony
	ponyc reactors -o build --debug

build:
	mkdir build

test: build/reactors
	build/reactors

clean:
	rm -rf build

.PHONY: clean test
