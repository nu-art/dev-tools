#!/bin/bash

before() {
  echo "[before] initializing test suite"
}

after() {
  echo "[after] cleaning up  test suite"
}

before_each() {
  echo "[before_each] starting test"
}

after_each() {
  echo "[after_each] finished test"
}

test_dummy_test1() {
  echo "NOTHING TO TEST HERE1"
}

test_dummy_test2() {
  echo "NOTHING TO TEST HERE2"
}

