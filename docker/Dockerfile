# Use Alpine base image
FROM alpine:latest

# Set default values for optional variables
ENV HARDENING_LEVEL=high \
    EXTRA_PACKAGES="vim htop" \
    ADMIN="" \
    ADMIN_PASS="" \
    USER="" \
    USER_PASS="" \
    ROOT_PASS=""

# Copy the hardening script into the container
COPY scripts/extended-pimp.sh /tmp/extended-pimp.sh
RUN chmod +x /tmp/extended-pimp.sh

# Run the script with dynamically passed environment variables
CMD ["/bin/sh", "-c", "/tmp/extended-pimp.sh"]
