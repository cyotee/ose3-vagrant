# OpenShift Enterprise 3 Vagrant Setup

This project contains a Vagrant file creating multiple VMs for running and demoing OpenShift Enterprise v3.
The demo environment consists of one VM running dnsmasq as the DNS server, one OpenShift master, and two OpenShift
nodes.

## Preparation

In order to use this you need to get a base VM setup. In order to do this, first create a Red Hat Enterprise Linux v7.1
VM. After it has been installed and registered, you will need to perform some basic set up tasks.

You can refer to the directions below or follow the instructions in the
[documentation](https://access.redhat.com/beta/documentation/en/openshift-enterprise-30-administrator-guide/chapter-1-installation)
from section 1.2.4.

First disable all repositories, then enable only the ones needed for OSEv3.
```bash
subscription-manager repos --disable="*"
subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-optional-rpms" \
    --enable="rhel-7-server-ose-3.0-rpms"
```

Make sure that deltarpm is there to make updating easier.
```bash
yum install -y deltarpm
```

Next remove NetworkManager to keep it from messing with the network connection at random times.
```bash
yum remove -y NetworkManager*
```

Install some useful tools.
```bash
yum install -y wget git net-tools bind-utils iptables-services bridge-utils
```

Then update the system.
```bash
yum update -y
```

Then you will need to install Docker, make some configuration changes then enable and start it.
```bash
yum install -y docker
sed -i -e "s/^OPTIONS=.*/OPTIONS='--insecure-registry=0.0.0.0/0 --selinux-enabled=true'"
systemctl enable docker; systemctl start docker
```

Once this is complete, you will need to package the Vagrant box and import it into Vagrant. Please refer to the Vagrant
documentation to do this for your hypervisor.

## Running the system

Make sure that you update the submodules with:
```bash
git submodule init
git submodule update
```

After that, you can just run `vagrant up`.

Enjoy.
