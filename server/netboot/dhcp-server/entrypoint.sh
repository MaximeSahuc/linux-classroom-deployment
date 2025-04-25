#!/bin/sh

# Replace SERVER_IP_ADDRESS with the actual IP address from environment variable
if [ -n "$SERVER_IP_ADDRESS" ]; then
    sed "s/SERVER_IP_ADDRESS/$SERVER_IP_ADDRESS/g" /etc/dnsmasq.conf.template > /etc/dnsmasq.conf
    echo "Configured dnsmasq with SERVER_IP_ADDRESS: $SERVER_IP_ADDRESS"
else
    echo "ERROR: SERVER_IP_ADDRESS environment variable not set!"
    exit 1
fi

# Run dnsmasq in foreground
exec dnsmasq -k -d