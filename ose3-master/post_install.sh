#!/bin/bash

# setup service account for docker-registry
echo \
    '{"kind":"ServiceAccount","apiVersion":"v1","metadata":{"name":"registry"}}' \
     | oc create -f -

cd ~
oc get scc privileged -o yaml > scc-privileged.yaml
echo "- system:serviceaccount:default:registry" >> scc-privileged.yaml
oc update -f scc-privileged.yaml

mkdir -p /mnt/docker

# install docker-registry
oadm registry --service-account=registry \
--config=/etc/openshift/master/admin.kubeconfig \
--credentials=/etc/openshift/master/openshift-registry.kubeconfig \
--mount-host=/mnt/docker \
--selector='region=infra' \
--images='registry.access.redhat.com/openshift3/ose-${component}:${version}'

# prepare generic certificate for openshift endpoints which don't provide their own certs
CA=/etc/openshift/master
oadm create-server-cert --signer-cert=$CA/ca.crt \
      --signer-key=$CA/ca.key --signer-serial=$CA/ca.serial.txt \
      --hostnames='*.cloudapps.example.com' \
      --cert=cloudapps.crt --key=cloudapps.key

cat cloudapps.crt cloudapps.key $CA/ca.crt > cloudapps.router.pem

# install router
oadm router router --replicas=1 \
    --credentials='/etc/openshift/master/openshift-router.kubeconfig' \
    --images='registry.access.redhat.com/openshift3/ose-${component}:${version}' \
    --selector='region=infra' \
    --stats-user='admin' \
    --stats-password='redhat' \
    --default-cert=cloudapps.router.pem

# Open the port to allow the HAProxy stats to be viewed
iptables -I OS_FIREWALL_ALLOW -p tcp -m tcp --dport 1936 -j ACCEPT

# add routing config so new projects wil leverage specified subdomain
echo "routingConfig:" >> /etc/openshift/master/master-config.yaml
echo "  subdomain: cloudapps.example.com" >> /etc/openshift/master/master-config.yaml

# setup so that openshift doesn't authenticate passwords (any password is fine) - moved to ansible/hosts
sed -i -e "s/- name: deny_all/- name: anypassword/" /etc/openshift/master/master-config.yaml
sed -i -e "s/kind: DenyAllPasswordIdentityProvider/kind: AllowAllPasswordIdentityProvider/" /etc/openshift/master/master-config.yaml

# restart openshift-master from all the config changes above
systemctl restart openshift-master

# allow external docker images (Dockerfile) with USER requirements to run
oc get scc restricted -o yaml > scc-restricted.yaml
sed -i -e "s/type: MustRunAsRange/type: RunAsAny/" scc-restricted.yaml
oc update -f scc-restricted.yaml

# Create a test project
oc new-project test-project

# Add bashburn to the test project
oadm policy add-role-to-user admin bashburn -n test-project

# Give bashburn admin access to the cluster
oadm policy add-cluster-role-to-user admin bashburn
