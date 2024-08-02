#!/bin/bash -x

set -e

if [ -e /etc/apt/sources.list.d/ubuntu.sources ]; then
    # new format fro 24.04+
    sed -i -e 's/Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources >&2
    grep 'deb-src' /etc/apt/sources.list.d/ubuntu.sources >&2
else
    sed -i -e 's/^# deb-src /deb-src /' /etc/apt/sources.list >&2
    grep 'deb-src' /etc/apt/sources.list >&2
fi

apt update >&2
DEBIAN_FRONTEND=noninteractive apt install dpkg-dev apt-file -y >&2
apt-file update >&2

driver=$1

apt source "$driver" >&2
driver_version=${DRIVER_VERSION-$(echo "$driver" | sed -e 's/-open//' -e 's/-server//' | rev | cut  -d- -f1 | rev)}
# shellcheck disable=SC2086
binpkglist=$(
    cat nvidia-graphics-drivers-${driver_version}*.dsc | \
        awk '/Package-List:/ { dump=1; next } /^[a-zA-Z].*:/ { if (dump==1) { dump=0; next} } // { if (dump==1) { print $1 } }' | \
        grep -v -- -open\
          )

echo "-- binary package list: $binpkglist" >&2

if [ "${USE_INSTALL}" = "y" ]; then
    DEBIAN_FRONTEND=noninteractive apt install $binpkglist -y >&2
    for p in $binpkglist; do
        dpkg -L "$p" |grep -E '\.so' | sort -u || true
    done
else
    for p in $binpkglist; do
        apt-file list "$p" |awk '/\.so/ { print $2 }' | sort -u || true
    done
fi
