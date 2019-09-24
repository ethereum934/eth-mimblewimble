#!/bin/bash

# Test script should be run in the base directory
check_truffle_project() {
  cd `dirname "$0"` && cd ../
  if [ -f "truffle-config.js" ]
  then
    echo "Start testing"
  else
    echo "You should run this script in the base directory of this project"
    exit 1
  fi
}

# Terminate running ganaches for testing
kill_ganache() {
  echo "Terminate ganache"
  if !([ -z ${pid+x} ]);then
    kill $pid > /dev/null 2>&1
  fi
}

# Compile contracts
compile() {
  ./node_modules/.bin/truffle compile --all
  [ $? -ne 0 ] && exit 1
}

# Run private block-chain for test cases
run_ganache() {
  ./node_modules/.bin/ganache-cli -s ethereum934 -l 8100000 -p $1 > /dev/null & pid=$!
  if ps -p $pid > /dev/null
  then
    echo "Running ganache..."
  else
    echo "Failed to run a chain"
    exit 1
  fi
}

# Run test cases with truffle
test_contracts() {
  #./node_modules/.bin/truffle test tests/*.sol --network test
  ./node_modules/.bin/truffle test tests/*.js --network test
  [ $? -ne 0 ] && exit 1
}

# Check test coverage
run_coverage() {
    ./node_modules/.bin/solidity-coverage
}
