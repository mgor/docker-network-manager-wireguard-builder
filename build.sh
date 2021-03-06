#!/bin/bash
PACKAGE="network-manager-wireguard"
DEBEMAIL="github@mgor.se"
DEBFULLNAME="docker-ubuntu-${PACKAGE}-builder"
DEBCOPYRIGHT="debian/copyright"
USER=builder
URL="https://github.com/max-moser/network-manager-wireguard"
DISTRO="$(lsb_release -sc)"

export DISTRO URL USER DEBCOPYRIGHT DEBFULLNAME DEBEMAIL PACKAGE

run() {
    sudo -Eu "${USER}" -H "${@}"
}

groupadd --gid "${GROUP_ID}" "${USER}" && \
useradd -M -N -u "${USER_ID}" -g "${GROUP_ID}" "${USER}" && \
chown "${USER}" . && \
run git clone "${URL}.git" "${PACKAGE}" && \
cd "${PACKAGE}" || exit

run ./autogen.sh --without-libnm-glib
#run ./configure --without-libnm-glib --prefix=/usr --sysconfdir=/etc --libdir=/usr/lib/x86_64-linux-gnu --libexecdir=/usr/lib/NetworkManager --localstatedir=/var
#
#run make

VERSION="0mg-master+$(git rev-parse --short HEAD)"
export VERSION

run dh_make -p "${PACKAGE}_${VERSION}" -s -y --createorig

# Create overrides for lintian
sudo -Eu "${USER}" -H tee "debian/${PACKAGE}.lintian-overrides" >/dev/null <<EOF
${PACKAGE} binary: binary-without-manpage *
${PACKAGE} binary: icon-size-and-directory-name-mismatch *
EOF

sudo -Eu "${USER}" -H tee -a "debian/rules" > /dev/null <<EOF
override_dh_auto_configure:
	dh_auto_configure -- \
	    --without-libnm-glib
EOF

# Fix debian/copyright
COPYRIGHT_YEAR="$(awk '/^Copyright/ {gsub(/-.+/, "", $3); print $3; exit}' COPYING)"
COPYRIGHT_OWNER="$(awk '/^Copyright/ {print $(NF-2)" "$(NF-1)" "$NF; exit}' COPYING)"
export COPYRIGHT_YEAR COPYRIGHT_OWNER

{ echo ""; awk '/Files: debian/,/^$/' "${DEBCOPYRIGHT}"; } | sudo -Eu "${USER}" -H tee "${DEBCOPYRIGHT}.template" >/dev/null
sudo -Eu "${USER}" -H tee "${DEBCOPYRIGHT}" >/dev/null <<EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: ${PACKAGE}
Source: $(git config remote.origin.url)

Files: *
Copyright: ${COPYRIGHT_YEAR} ${COPYRIGHT_OWNER}
License: GPL-2 or GPL-3
EOF

#shellcheck disable=SC2002
cat "${DEBCOPYRIGHT}.template" | sudo -Eu "${USER}" -H tee -a "${DEBCOPYRIGHT}" >/dev/null && rm -rf "${DEBCOPYRIGHT}.template"

# Fix debian/changelog
run rm -rf debian/changelog
run dch -D "${DISTRO}" --create --package "${PACKAGE}" --newversion "${VERSION}" "Automagically built in docker"

# Fix debian/control
DESCRIPTION=" This project is a VPN Plugin for NetworkManager that handles client-side WireGuard Connections"
SHORT_DESCRIPTION="NetworkManager Wireguard"
export DESCRIPTION SHORT_DESCRIPTION

run sed -i '/^#/d' debian/control
run sed -r -i "s|^(Section:).*|\1 x11|" debian/control
run sed -r -i "s|^(Homepage:).*|\1 ${URL}|" debian/control
run sed -r -i "s|^(Architecture:).*|\1 $(dpkg --print-architecture)|" debian/control
run sed -r -i "s|^(Description:).*|\1 ${SHORT_DESCRIPTION}|" debian/control
run sed -r -i "s|^(Depends: .*)|\1, resolvconf|" debian/control
run sed -i '$ d' debian/control
echo "${DESCRIPTION}" | sudo -u "${USER}" tee -a debian/control >/dev/null
run rm -rf debian/README.Debian
run cp README.md debian/README.source

if run debuild -i -us -uc -b
then
    cd ../ && rm -rf "${PACKAGE}"
    exit 0
else
    echo "Build failed!"
    exit 1
fi

