# Use the hardened image built with Packer, or base from Alpine and add custom steps.
FROM alpine:latest

# Copy your hardening script if you want to run it during image build
COPY ../scripts/harden_alpine.sh /usr/local/bin/harden_alpine.sh
RUN chmod +x /usr/local/bin/harden_alpine.sh && \
    /usr/local/bin/harden_alpine.sh

# Set environment variables (if you want to bake them into the image)
ENV HARDENING_LEVEL=high \
    EXTRA_PACKAGES="vim,htop"

# Default command (can be overridden by docker-compose)
CMD [ "sh", "/scripts/setup.sh" ]
