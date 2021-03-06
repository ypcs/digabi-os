#!/bin/sh

set -e

PROVISION_CHECKSUM="$(md5sum $0 |awk '{print $1}')"
PROVISION_STATEFILE="/root/.vagrant_provision_id"

if [ -f "${PROVISION_STATEFILE}" ]
then
    OLD_STATE="$(cat ${PROVISION_STATEFILE})"
    if [ "${OLD_STATE}" = "${PROVISION_CHECKSUM}" ]
    then
        echo "I: Already provisioned w/ ${PROVISION_CHECKSUM}, skipping..."
        exit 0
    fi
fi

contains() {
    string="$1"
    substring="$2"
    if test "${string#*$substring}" != "$string"
    then
        return 0
    else
        return 1
    fi
}

#
# Initialiaze new Vagrant (Debian wheezy/jessie)
#
REPOSITORY_INSTALLER="/vagrant/custom-packages/digabi-repository/install-repository.sh"

#
# Prefer IPv4 over IPv6
#
echo "I: Prefer IPv4 over IPv6..."
sed -i -e 's/#\(precedence ::ffff:.*100\)/\1/' /etc/gai.conf
sysctl -w net.ipv6.conf.all.disable_ipv6=1

if [ -f "/etc/apt/sources.list.d/digabi.list" ]
then
    echo "I: Digabi repository already configured, skipping configuration..."
else
    echo "I: Add Digabi repository..."
    if [ -e "${REPOSITORY_INSTALLER}" ]
    then
        echo "D: Install using repository installer..."
        sh ${REPOSITORY_INSTALLER}
        sed -i "s,-stable,-${DIGABI_SUITE:-stable},g" /etc/apt/sources.list.d/digabi.list
        sed -i "s,http://dev.digabi.fi/debian,${DIGABI_MIRROR:-http://dev.digabi.fi/debian},g" /etc/apt/sources.list.d/digabi.list
    else
        echo "D: Install using http..."
        wget -qO /etc/apt/sources.list.d/digabi.list ${DIGABI_MIRROR}/digabi.list
        wget -qO- ${DIGABI_MIRROR}/digabi.asc | apt-key add -
    fi
fi

if [ -n "${DEBIAN_MIRROR}" ]
then
    echo "I: Configuring custom Debian mirror: ${DEBIAN_MIRROR}..."
    if [ -z "${DEBIAN_SUITE}" ]
    then
        DEBIAN_SUITE="jessie"
    fi
    echo "deb ${DEBIAN_MIRROR} ${DEBIAN_SUITE} main contrib non-free" >/etc/apt/sources.list
    echo "deb-src ${DEBIAN_MIRROR} ${DEBIAN_SUITE} main contrib non-free" >>/etc/apt/sources.list
    echo "deb http://security.debian.org/ ${DEBIAN_SUITE}/updates main contrib non-free" >>/etc/apt/sources.list
    echo "deb-src http://security.debian.org/ ${DEBIAN_SUITE}/updates main contrib non-free" >>/etc/apt/sources.list
else
    echo "I: Using pre-configured Debian mirror."
fi

echo "I: Configure APT: do not install recommends..."
cat << EOF >/etc/apt/apt.conf.d/99-no-recommends
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF

echo "I: Update package lists..."
apt-get -qy update

echo "I: Upgrade build system..."
DEBIAN_FRONTEND=noninteractive apt-get -qy upgrade

echo "I: Install digabi-dev, rsync..."
DEBIAN_FRONTEND=noninteractive apt-get -o "Acquire::http::Pipeline-Depth=10" -qy install digabi-dev rsync git aptitude digabi-archive-keyring

echo "I: Saving provisioning state..."
echo "${PROVISION_CHECKSUM}" >${PROVISION_STATEFILE}
