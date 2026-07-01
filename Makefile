VERSION := $(shell cat VERSION)
NAME := sysreport

run:
	bash bin/sysreport

help:
	bash bin/sysreport --help

sections:
	bash bin/sysreport --list-sections

check:
	bash -n bin/sysreport scripts/sysreport.sh src/sysreport/core.sh src/sysreport/modules/*.sh

version:
	@echo $(VERSION)

tag:
	git tag v$(VERSION)

push-tag:
	git push origin v$(VERSION)

release: tag push-tag

clean:
	rm -rf dist build release
