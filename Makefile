FILES=src/*
CLI_NAME=lorg

cli-debug: $(FILES)
	haxe --debug compile-cli.hxml
	cp -f build/Main-debug $(CLI_NAME)

cli-release: $(FILES)
	haxe --dce full compile-cli.hxml
	cp -f build/Main $(CLI_NAME)

web-debug: $(FILES)
	haxe --debug compile-web.hxml
	cp -f build/Main-debug $(CLI_NAME)

web-release: $(FILES)
	haxe --dce full compile-web.hxml
	cp -f build/Main $(CLI_NAME)

clean:
	rm -rf build
	rm -rf lorg

.PHONY: clean cli-release cli-debug web-release web-debug
