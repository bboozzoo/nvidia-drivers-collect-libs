#!/bin/bash

set -e
set -x

release="$1"

cname="nvidiatest-$(echo $release | tr . -)"

if [ -e "$release-done" ]; then
    echo "---- skipping $release, already done"
    exit 0
fi

lxc launch "ubuntu:$release" "$cname" --ephemeral -c limits.cpu=8 -c limits.memory=8GiB ${EXTRA_LXC_ARGS}
driver_versions=$(lxc exec "$cname" -- sh -c "apt-cache search nvidia-driver | grep nvidia-driver | grep -v -i transition | cut -f1 -d' '")
lxc delete --force "$cname"

echo "-- release $release"
echo "-- driver versions:"
echo "$driver_versions" > "$release-drivers"
echo $driver_versions

for v in $driver_versions; do
    if [ -e "$release-$v-done" ]; then
        echo "--- skipping driver $v, already done"
        continue
    fi

    lxc launch "ubuntu:$release" "$cname" --ephemeral -c limits.cpu=8 -c limits.memory=8GiB ${EXTRA_LXC_ARGS}
    lxc exec "$cname" -- cloud-init status --wait
    echo "--- container ready"
    lxc file push collect-driver.sh "$cname"/root/collect-driver.sh
    lxc exec "$cname" -- /bin/sh -c "cd /root; ./collect-driver.sh $v" > "$release-$v.libs"
    lxc delete --force "$cname"
    test -s "$release-$v.libs"
    touch "$release-$v-done"
done

touch "$release-done"
