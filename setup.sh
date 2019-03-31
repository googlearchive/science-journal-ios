#!/bin/bash

bundle install
bundle exec pod install
brew install protobuf@3.1
brew link protobuf@3.1 -f
cd Protos
echo "Generating Science Journal protos"
./generate.sh
