#!/bin/bash
set -e
# entrypoint.sh: Ensure SSH Host keys are present at runtime

if [ ! -f /root/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519
fi


# create authorized_keys
touch /root/.ssh/authorized_keys

# Fix permissions (important)
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys || true

# Finally, exec the CMD passed by Dockerfile
exec "$@"
