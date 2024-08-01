#!/bin/bash

set -e

#RELEASES="18.04 20.04 22.04 24.04"
RELEASES="18.04"

for release in $RELEASES; do
    ./collect-release "$release"
done
