.PHONY: build test

build:
	protostar build --cairo-path lib/cairo_contracts/src

test:
	protostar test contracts/ --cairo-path lib/cairo_contracts/src $(args)

date:
	date
	
cli: date
	sh ./cli/menu.sh