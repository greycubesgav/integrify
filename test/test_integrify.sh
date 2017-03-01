#!/usr/bin/env bash

# Check file has no integrify data
output=$(../integrify ./test_01.dat)
result='./test_01.dat : <none>'
if [ "$output" == "$result" ]; then
  echo "No Data - Pass"
else
  echo "No Data - Fail: [${output}] expected [${result}]"
fi

# Check we can write to the file
output=$(../integrify -a ./test_01.dat)
result='./test_01.dat : added'
if [ "$output" == "$result" ]; then
  echo "Checksum Added - Pass"
else
  echo "Checksum Added - Fail: [${output}] expected [${result}]"
fi

# Check the checksum was right
output=$(../integrify -c ./test_01.dat)
result='./test_01.dat : passed'
if [ "$output" == "$result" ]; then
  echo "Checksum Validated - Pass"
else
  echo "Checksum Validated - Fail: [${output}] expected [${result}]"
fi

# Check the checksum was removed
output=$(../integrify -d ./test_01.dat)
result='./test_01.dat : <removed>'
if [ "$output" == "$result" ]; then
  echo "Checksum Validated - Pass"
else
  echo "Checksum Validated - Fail: [${output}] expected [${result}]"
fi




