#!/bin/bash

# Set the proper DNS resolver
sed -i -e "s/^nameserver.*/nameserver 192.168.100.150/" /etc/resolv.conf
