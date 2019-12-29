SHELL:=/bin/bash
DIR := ${CURDIR}
output ?= 'build/'

test: test-circuits test-py934 test-contracts

# -------------------- Dev Containers -------------------- #
container-python:
	$(info Make: build container for py934)
	@docker build -f containers/py934.dockerfile ./ -t ethereum-mw-zokrates-python

container-circuit:
	$(info Make: build container and compile circuits)
	@docker build -f containers/zokrates.dockerfile ./ -t ethereum-mw-zokrates

container-zokrates-pycrypto: # Used for utils/create_challenge_circuit.py
	$(info Make: build zokrates pycrypto container for py934)
	@docker build -f containers/zokrates_pycrypto.dockerfile ./ -t ethereum-mw-zokrates-pycrypto

# -------------------- ZK Containers -------------------- #
container-zk-deposit:
	@docker build -f containers/zkDeposit.dockerfile ./ -t ethereum934/zk-deposit

container-zk-range-proof:
	@docker build -f containers/zkRangeProof.dockerfile ./ -t ethereum934/zk-range-proof

container-zk-mimblewimble:
	@docker build -f containers/zkMimblewimble.dockerfile ./ -t ethereum934/zk-mimblewimble

container-zk-withdraw:
	@docker build -f containers/zkWithdraw.dockerfile ./ -t ethereum934/zk-withdraw

container-zk-mmr-inclusion:
	@docker build -f containers/zkMMRInclusion.dockerfile ./ -t ethereum934/zk-mmr-inclusion

container-zk-roll-up:
	@docker build -f containers/zkRollUp.dockerfile ./ -t ethereum934/zk-roll-up

container-zk-roll-up-1:
	@docker build -f containers/zkRollUp1.dockerfile ./ -t ethereum934/zk-roll-up-1

container-zk-roll-up-2:
	@docker build -f containers/zkRollUp2.dockerfile ./ -t ethereum934/zk-roll-up-2

container-zk-roll-up-4:
	@docker build -f containers/zkRollUp4.dockerfile ./ -t ethereum934/zk-roll-up-4

container-zk-roll-up-8:
	@docker build -f containers/zkRollUp8.dockerfile ./ -t ethereum934/zk-roll-up-8

container-zk-roll-up-16:
	@docker build -f containers/zkRollUp16.dockerfile ./ -t ethereum934/zk-roll-up-16

container-zk-roll-up-32:
	@docker build -f containers/zkRollUp32.dockerfile ./ -t ethereum934/zk-roll-up-32

container-zk-roll-up-64:
	@docker build -f containers/zkRollUp64.dockerfile ./ -t ethereum934/zk-roll-up-64

container-zk-roll-up-128:
	@docker build -f containers/zkRollUp128.dockerfile ./ -t ethereum934/zk-roll-up-128

# -------------------- Commands for circuit -------------------- #
test-circuits: container-circuit clear-container
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
	@docker cp zokrates-tmp:/pycrypto/challengeHasher.zok $(output)
	@docker rm zokrates-tmp

clear-container:
	@(docker rm zokrates-tmp || true) 2> /dev/null

# -------------------- Commands for py934 library -------------------- #

install-python:
	@pip3 install -q virtualenv
	@[[ -d .venv ]] || virtualenv .venv -p python3
	@source .venv/bin/activate; pip3 install -q -r requirements.txt

test-py934: install-python
	@source .venv/bin/activate; python -m unittest tests/test*.py

sample_data: install-python
	@source .venv/bin/activate; python sample.py

# -------------------- Commands for contracts -------------------- #

install-node:
	@npm install

test-contracts:
	@npm run test;

# -------------------- Commands for CI/CI -------------------- #
# TODO
travis: compile
	$(info Make: Running Travis CI Locally)
