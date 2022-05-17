.PHONY: build test

build:
	protostar build

test:
	protostar test contracts/ -m '.*$(match).*'

date:
	date
