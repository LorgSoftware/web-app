lorg: src/*
	haxe compile.hxml
	cp -f build/Main-debug ./lorg

clean:
	rm -rf build

.PHONY: clean
