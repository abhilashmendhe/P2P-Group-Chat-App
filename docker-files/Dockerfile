# Use an official Ubuntu base image
FROM ubuntu:latest

# Install necessary packages
RUN apt-get upgrade && apt-get update && apt-get install -y \
    curl \
    git \
    openssh-server \
    openssh-client \
    vim \
    iputils-ping \
    net-tools \ 
    bc \ 
    expect \
    python3 && \
    mkdir -p /var/run/sshd && \
    mkdir -p /root/.ssh && chmod 700 /root/.ssh

# Copy sshd_config to /etc/ssh/sshd_config
COPY sshd_config /etc/ssh/sshd_config

# --- KEY MANAGEMENT ---
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Use entrypoint at runtime (not build time)
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Run sshd in the foreground to keep the container alive
CMD ["/usr/sbin/sshd", "-D"]

# Expose SSH port
EXPOSE 22
