SHELL:=/bin/bash
DIR := ${CURDIR}
output ?= 'build/'

# -------------------- Containers -------------------- #
container-python:
	$(info Make: build container for py934)
	@docker build -f containers/py934.dockerfile ./ -t ethereum-mw-zokrates-python

container-circuit:
	$(info Make: build container and compile circuits)
	@docker build -f containers/zokrates.dockerfile ./ -t ethereum-mw-zokrates

container-zokrates-pycrypto: # Used for utils/create_challenge_circuit.py
	$(info Make: build zokrates pycrypto container for py934)
	@docker build -f containers/zokrates_pycrypto.dockerfile ./ -t ethereum-mw-zokrates-pycrypto


# -------------------- Commands for circuit -------------------- #
test: container-circuit clear-container
	$(info Make: Run unit test for circuits)
	@docker run\
		--name zokrates-tmp \
		ethereum-mw-zokrates \
		/bin/bash -c "\
		./zokrates compile -i tests/circuits/unitTest.code;\
		./zokrates setup;\
		./zokrates compute-witness;\
		./zokrates generate-proof;\
		"
	@docker rm zokrates-tmp

verifier: container-circuit clear-container
	$(info Make: compile circuits)
	@docker run \
		--name zokrates-tmp \
		ethereum-mw-zokrates \
		/bin/bash -c "\
	./zokrates compile -i $(circuit);\
	./zokrates setup;\
	./zokrates export-verifier" \
	@mkdir -p build
	@docker cp zokrates-tmp:/home/zokrates/verifier.sol $(output)
	@docker rm zokrates-tmp
	@echo Successfully generated verifier. 
	@echo ---------------- result -------------------
	@echo Circuit: $(circuit)
	@echo Output: $(output)

proof: container-circuit clear-container
	$(info Make: Generate zkSNARKs proof)
	@docker run \
		--name zokrates-tmp \
		ethereum-mw-zokrates \
		/bin/bash -c "\
		./zokrates compile -i $(circuit);\
		./zokrates setup;\
		./zokrates compute-witness $(if $(args), -a $(args)) ;\
		./zokrates generate-proof;\
		"
	@mkdir -p build
	@docker cp zokrates-tmp:/home/zokrates/proof.json $(output)
	@docker rm zokrates-tmp
	@echo ---------------- result -------------------
	@echo Circuit: $(circuit)
	@echo Args: $(args)
	@echo Output: $(output)

shell: container-circuit clear-container
	$(info Make: Generate zkSNARKs proof)
	@docker run \
		-it \
		--rm
		--name zokrates-tmp \
		ethereum-mw-zokrates \

hash-circuit: container-zokrates-pycrypto clear-container
	$(info Make: get hasher circuit for tx challenge)
	@docker run \
		-it \
		--name zokrates-tmp \
		ethereum-mw-zokrates-pycrypto \
		create_challenge_circuit.py
	@docker cp zokrates-tmp:/pycrypto/challengeHasher.code $(output)
	@docker rm zokrates-tmp

clear-container:
	@(docker rm zokrates-tmp || true) 2> /dev/null

# -------------------- Commands for py934 library -------------------- #

pyenv:
	@pip3 install -q virtualenv
	@[[ -d .venv ]] || virtualenv .venv -p python3
	@source .venv/bin/activate; pip3 install -q -r requirements.txt

pytest: pyenv
	@source .venv/bin/activate; python -m unittest tests/test*.py

sample_tx: pyenv
	@source .venv/bin/activate; python utils/sample_tx.py


# -------------------- Commands for CI/CI -------------------- #
# TODO
travis: compile
	$(info Make: Running Travis CI Locally)

