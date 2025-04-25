FROM alpine:3.19

# Install dnsmasq
RUN apk update && \
    apk add --no-cache dnsmasq && \
    rm -rf /var/cache/apk/*

# Copy the dnsmasq configuration template
COPY dnsmasq.conf.template /etc/dnsmasq.conf.template

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose DHCP port
EXPOSE 67/udp

# Use the entrypoint script
ENTRYPOINT ["/entrypoint.sh"]