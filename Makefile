VERSION := $(shell cat VERSION)
NAME := sysreport

run:
	bash scripts/sysreport.sh

version:
	@echo $(VERSION)

tag:
	git tag v$(VERSION)

push-tag:
	git push origin v$(VERSION)

release: tag push-tag

clean:
	rm -rf dist build release