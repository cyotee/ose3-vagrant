#!/bin/bash
mkdir /usr/share/openshift
cp -r /vagrant/projects/openshift-ansible/playbooks/common/openshift-master/roles/openshift_examples/files/examples /usr/share/openshift

# Set the proper DNS resolver
sed -i -e "s/^nameserver.*/nameserver 192.168.100.150/" /etc/resolv.conf
