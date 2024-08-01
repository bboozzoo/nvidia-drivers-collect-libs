#!/bin/bash

set -e

#RELEASES="18.04 20.04 22.04 24.04"
RELEASES="18.04"

for release in $RELEASES; do
    if [ -e "$release-done" ]; then
        echo "---- skipping $release, already done"
        continue
    fi
    lxc launch "ubuntu:$release" nvidiatest --ephemeral -c limits.cpu=8 -c limits.memory=8GiB
    driver_versions=$(lxc exec nvidiatest -- sh -c "apt-cache search nvidia-driver | grep nvidia-driver | grep -v -- -open | grep -v -- -server | grep -v -i transition | cut -f1 -d' '")
    lxc delete --force nvidiatest

    echo "-- release $release"
    echo "-- driver versions:"
    echo $driver_versions

    for v in $driver_versions; do
        if [ -e "$release-$v-done" ]; then
           echo "--- skipping driver $v, already done"
           continue
        fi

        lxc launch "ubuntu:$release" nvidiatest --ephemeral -c limits.cpu=8 -c limits.memory=8GiB
        lxc exec nvidiatest -- cloud-init status --wait
        echo "--- container ready"
        lxc file push collect-driver.sh nvidiatest/root/collect-driver.sh
        lxc exec nvidiatest -- /bin/sh -c "cd /root; ./collect-driver.sh $v" > "$release-$v.libs"
        lxc delete --force nvidiatest
        test -s "$release-$v.libs"
        touch "$release-$v-done"
    done

    touch "$release-done"
done
