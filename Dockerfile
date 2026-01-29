FROM weejewel/wg-easy:latest

# Metadata
LABEL maintainer="OrionTrader"
LABEL description="Custom WireGuard VPN with wg-easy interface"

# Set default environment variables
ENV WG_HOST=0.0.0.0
ENV WG_DEFAULT_ADDRESS=10.8.0.0/24
ENV WG_DEFAULT_DNS=1.1.1.1
ENV WG_MTU=1420

# Expose ports
EXPOSE 51820/udp
EXPOSE 51821/tcp

# Keep the original entrypoint
CMD ["/usr/bin/wg-easy"]
