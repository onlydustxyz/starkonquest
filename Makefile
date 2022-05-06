.PHONY: build test

build:
	protostar build --cairo-path lib/cairo_contracts/src

test:
	protostar test contracts/ --cairo-path lib/cairo_contracts/src -m '.*$(match).*'

date:
	date
	
cli: date
	sh ./cli/menu.sh
