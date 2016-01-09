SHELL := /bin/bash

types = shaded boot
apps = freemarker
combined = $(foreach type,$(types),$(foreach app,$(apps),build/$(type)/$(app).jar))

all: $(combined) run

run:
	mkdir -p build
	rm -f build/result.txt
	echo id    app        type limit status errors > build/result.txt
	cat input.txt | xargs -L 1 ./push.sh

shaded: */pom.xml build/shaded/%.jar

build/shaded/%.jar: | %
	cd $(*) && mvn clean package -P shaded,!boot
	mkdir -p build/shaded
	cp $(*)/target/spring*.jar $@

boot: */pom.xml build/boot/%.jar

build/boot/%.jar: | %
	cd $(*) && mvn clean package -P !shaded,boot
	mkdir -p build/boot
	cp $(*)/target/spring*.jar $@

.PHONY: all run $(apps)
