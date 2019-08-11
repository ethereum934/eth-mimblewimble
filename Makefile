SHELL:=/bin/bash
DIR := ${CURDIR}
output ?= 'build/'

build-image:
	$(info Make: build container and compile circuits)
	@docker build -f containers/zokrates.dockerfile ./ -t ethereum-mw-zokrates

test: build-image
	$(info Make: Run unit test for circuits)
	@trap "docker rm zokrates-container" SIGINT SIGTERM ERR EXIT
	@docker run\
		--name zokrates-container \
		ethereum-mw-zokrates \
		/bin/bash -c "\
		./zokrates compile -i tests/unitTest.code;\
		./zokrates setup;\
		./zokrates compute-witness;\
		./zokrates generate-proof;\
		"

verifier: build-image
	$(info Make: compile circuits)
	@trap "docker rm zokrates-container" SIGINT SIGTERM ERR EXIT
	@docker run \
		--name zokrates-container \
		ethereum-mw-zokrates \
		/bin/bash -c "\
	./zokrates compile -i $(circuit);\
	./zokrates setup;\
	./zokrates export-verifier" \
	@mkdir -p build
	@docker cp zokrates-container:/home/zokrates/verifier.sol $(output)
	@echo Successfully generated verifier. 
	@echo ---------------- result -------------------
	@echo Circuit: $(circuit)
	@echo Output: $(output)

proof: build-image
	$(info Make: Generate zkSNARKs proof)
	@trap "docker rm zokrates-container" SIGINT SIGTERM ERR EXIT
	@docker run \
		--name zokrates-container \
		ethereum-mw-zokrates \
		/bin/bash -c "\
		./zokrates compile -i $(circuit);\
		./zokrates setup;\
		./zokrates compute-witness $(if $(args), -a $(args)) ;\
		./zokrates generate-proof;\
		"
	@mkdir -p build
	@docker cp zokrates-container:/home/zokrates/proof.json $(output)
	@echo ---------------- result -------------------
	@echo Circuit: $(circuit)
	@echo Args: $(args)
	@echo Output: $(output)

shell: build-image
	$(info Make: Generate zkSNARKs proof)
	@trap "docker rm zokrates-container" SIGINT SIGTERM ERR EXIT
	@docker run \
		-it \
		--name zokrates-container \
		ethereum-mw-zokrates \


# TODO
travis: compile
	$(info Make: Running Travis CI Locally)

